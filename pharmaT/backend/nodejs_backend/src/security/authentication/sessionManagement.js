/**
 * Session Management
 * Secure session handling with Redis storage and advanced security features
 */

const crypto = require('crypto');
const Redis = require('redis');
const { v4: uuidv4 } = require('uuid');
const { EncryptionService } = require('../encryption/encryption');

class SessionManager {
  constructor() {
    this.redisClient = null;
    this.encryptionService = new EncryptionService();
    this.config = {
      sessionTimeout: 30 * 60 * 1000, // 30 minutes
      maxSessions: 5, // Maximum active sessions per user
      sessionPrefix: 'session:',
      lockoutThreshold: 5, // Failed attempts before lockout
      lockoutDuration: 15 * 60 * 1000, // 15 minutes
      concurrentLoginLimit: 3, // Max concurrent logins
      deviceFingerprint: true,
      secureCookies: true,
      httpOnlyCookies: true,
      sameSite: 'strict'
    };
    
    this.activeSessions = new Map();
    this.sessionLocks = new Map();
    this.userSessions = new Map();
  }

  async initialize() {
    try {
      await this.encryptionService.initialize();
      
      // Initialize Redis
      this.redisClient = Redis.createClient({
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        password: process.env.REDIS_PASSWORD
      });
      
      await this.redisClient.connect();
      console.log('✅ Session Manager initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Session Manager: ${error.message}`);
    }
  }

  // Create new session
  async createSession(userId, sessionData = {}) {
    const sessionId = uuidv4();
    const timestamp = Date.now();
    
    const session = {
      id: sessionId,
      userId,
      created: timestamp,
      lastActivity: timestamp,
      expires: timestamp + this.config.sessionTimeout,
      isActive: true,
      deviceInfo: sessionData.deviceInfo || {},
      ipAddress: sessionData.ipAddress || null,
      userAgent: sessionData.userAgent || null,
      location: sessionData.location || null,
      riskScore: 0,
      concurrentLogin: sessionData.concurrentLogin || false,
      biometricVerified: sessionData.biometricVerified || false,
      twoFactorVerified: sessionData.twoFactorVerified || false,
      data: sessionData.data || {}
    };

    try {
      // Check if user has reached concurrent login limit
      const userActiveSessions = await this.getUserActiveSessions(userId);
      if (userActiveSessions.length >= this.config.maxSessions) {
        throw new Error('Maximum number of concurrent sessions reached');
      }

      // Store session in Redis
      await this.storeSession(session);

      // Track in memory
      this.activeSessions.set(sessionId, session);
      this.trackUserSession(userId, sessionId);

      // Generate session fingerprint
      session.fingerprint = await this.generateSessionFingerprint(session);

      // Update session with fingerprint
      await this.storeSession(session);
      this.activeSessions.set(sessionId, session);

      console.log(`Session created: ${sessionId} for user: ${userId}`);
      return session;
    } catch (error) {
      throw new Error(`Failed to create session: ${error.message}`);
    }
  }

  // Store session in Redis
  async storeSession(session) {
    try {
      const key = `${this.config.sessionPrefix}${session.id}`;
      
      const sessionData = {
        id: session.id,
        userId: session.userId,
        created: session.created.toString(),
        lastActivity: session.lastActivity.toString(),
        expires: session.expires.toString(),
        isActive: session.isActive.toString(),
        deviceInfo: JSON.stringify(session.deviceInfo),
        ipAddress: session.ipAddress || '',
        userAgent: session.userAgent || '',
        location: session.location || '',
        riskScore: session.riskScore.toString(),
        concurrentLogin: session.concurrentLogin.toString(),
        biometricVerified: session.biometricVerified.toString(),
        twoFactorVerified: session.twoFactorVerified.toString(),
        data: JSON.stringify(session.data)
      };

      if (session.fingerprint) {
        sessionData.fingerprint = session.fingerprint;
      }

      await this.redisClient.hSet(key, sessionData);
      
      // Set expiration
      const ttl = Math.floor((session.expires - Date.now()) / 1000);
      await this.redisClient.expire(key, ttl);
    } catch (error) {
      console.error('Error storing session:', error);
      throw error;
    }
  }

  // Retrieve session from Redis
  async getSession(sessionId) {
    try {
      const key = `${this.config.sessionPrefix}${sessionId}`;
      const data = await this.redisClient.hGetAll(key);
      
      if (!data || Object.keys(data).length === 0) {
        return null;
      }

      return {
        id: data.id,
        userId: data.userId,
        created: parseInt(data.created),
        lastActivity: parseInt(data.lastActivity),
        expires: parseInt(data.expires),
        isActive: data.isActive === 'true',
        deviceInfo: JSON.parse(data.deviceInfo || '{}'),
        ipAddress: data.ipAddress || null,
        userAgent: data.userAgent || null,
        location: data.location || null,
        riskScore: parseInt(data.riskScore),
        concurrentLogin: data.concurrentLogin === 'true',
        biometricVerified: data.biometricVerified === 'true',
        twoFactorVerified: data.twoFactorVerified === 'true',
        data: JSON.parse(data.data || '{}'),
        fingerprint: data.fingerprint || null
      };
    } catch (error) {
      console.error('Error retrieving session:', error);
      return null;
    }
  }

  // Update session activity
  async updateSessionActivity(sessionId, activityData = {}) {
    try {
      const session = await this.getSession(sessionId);
      if (!session) {
        throw new Error('Session not found');
      }

      // Check if session is expired
      if (Date.now() > session.expires) {
        await this.invalidateSession(sessionId);
        throw new Error('Session expired');
      }

      // Update activity
      session.lastActivity = Date.now();
      session.data = { ...session.data, ...activityData };

      // Update risk score based on activity
      session.riskScore = this.calculateRiskScore(session, activityData);

      // Store updated session
      await this.storeSession(session);
      this.activeSessions.set(sessionId, session);

      return session;
    } catch (error) {
      if (error.message !== 'Session not found') {
        console.error('Error updating session activity:', error);
      }
      throw error;
    }
  }

  // Invalidate session
  async invalidateSession(sessionId) {
    try {
      const session = await this.getSession(sessionId);
      if (session) {
        // Remove from Redis
        const key = `${this.config.sessionPrefix}${sessionId}`;
        await this.redisClient.del(key);

        // Remove from memory
        this.activeSessions.delete(sessionId);
        this.untrackUserSession(session.userId, sessionId);

        // Add to session blacklist for security
        await this.blacklistSession(sessionId, session.userId);

        console.log(`Session invalidated: ${sessionId}`);
      }
    } catch (error) {
      console.error('Error invalidating session:', error);
    }
  }

  // Invalidate all user sessions
  async invalidateUserSessions(userId, excludeSessionId = null) {
    try {
      const userActiveSessions = await this.getUserActiveSessions(userId);
      
      for (const sessionId of userActiveSessions) {
        if (excludeSessionId && sessionId === excludeSessionId) {
          continue; // Don't invalidate the current session
        }
        await this.invalidateSession(sessionId);
      }

      console.log(`Invalidated ${userActiveSessions.length} sessions for user: ${userId}`);
    } catch (error) {
      console.error('Error invalidating user sessions:', error);
    }
  }

  // Get user active sessions
  async getUserActiveSessions(userId) {
    try {
      const key = `user_sessions:${userId}`;
      const sessionIds = await this.redisClient.sMembers(key);
      
      // Filter out expired/invalid sessions
      const activeSessions = [];
      for (const sessionId of sessionIds) {
        const session = await this.getSession(sessionId);
        if (session && session.isActive && session.expires > Date.now()) {
          activeSessions.push(sessionId);
        } else if (session) {
          // Clean up expired sessions
          await this.invalidateSession(sessionId);
        }
      }

      return activeSessions;
    } catch (error) {
      console.error('Error getting user active sessions:', error);
      return [];
    }
  }

  // Track user session
  trackUserSession(userId, sessionId) {
    const key = `user_sessions:${userId}`;
    this.redisClient.sAdd(key, sessionId);
    
    // Track in memory
    if (!this.userSessions.has(userId)) {
      this.userSessions.set(userId, new Set());
    }
    this.userSessions.get(userId).add(sessionId);
  }

  // Untrack user session
  untrackUserSession(userId, sessionId) {
    const key = `user_sessions:${userId}`;
    this.redisClient.sRem(key, sessionId);
    
    // Remove from memory
    if (this.userSessions.has(userId)) {
      this.userSessions.get(userId).delete(sessionId);
      if (this.userSessions.get(userId).size === 0) {
        this.userSessions.delete(userId);
      }
    }
  }

  // Generate session fingerprint for security
  async generateSessionFingerprint(session) {
    try {
      const fingerprintData = {
        userAgent: session.userAgent,
        ipAddress: session.ipAddress,
        deviceInfo: session.deviceInfo,
        userId: session.userId,
        timestamp: session.created
      };

      const fingerprintString = JSON.stringify(fingerprintData);
      const hash = crypto.createHash('sha256').update(fingerprintString).digest('hex');
      
      return hash.substring(0, 16); // First 16 characters for readability
    } catch (error) {
      console.error('Error generating session fingerprint:', error);
      return null;
    }
  }

  // Validate session fingerprint
  async validateSessionFingerprint(sessionId, currentFingerprint) {
    try {
      const session = await this.getSession(sessionId);
      if (!session || !session.fingerprint) {
        return false;
      }

      // Fingerprints match if first 8 characters are the same (partial matching for flexibility)
      const sessionFP = session.fingerprint.substring(0, 8);
      const currentFP = currentFingerprint.substring(0, 8);
      
      return sessionFP === currentFP;
    } catch (error) {
      console.error('Error validating session fingerprint:', error);
      return false;
    }
  }

  // Calculate risk score for session
  calculateRiskScore(session, activityData) {
    let riskScore = session.riskScore || 0;
    const now = Date.now();
    
    // Increase risk if session is old
    const sessionAge = now - session.created;
    if (sessionAge > 24 * 60 * 60 * 1000) { // 24 hours
      riskScore += 1;
    }

    // Check for suspicious activity patterns
    if (activityData.ipAddress && activityData.ipAddress !== session.ipAddress) {
      riskScore += 2; // IP address changed
    }

    if (activityData.userAgent && activityData.userAgent !== session.userAgent) {
      riskScore += 2; // User agent changed
    }

    // Cap risk score
    return Math.min(riskScore, 10);
  }

  // Lock session due to security concerns
  async lockSession(sessionId, reason = 'Security lockout', duration = null) {
    try {
      const lockData = {
        sessionId,
        lockedAt: Date.now(),
        reason,
        expiresAt: duration ? Date.now() + duration : null
      };

      const key = `session_lock:${sessionId}`;
      await this.redisClient.hSet(key, {
        lockedAt: lockData.lockedAt.toString(),
        reason,
        expiresAt: lockData.expiresAt ? lockData.expiresAt.toString() : '0'
      });

      if (duration) {
        await this.redisClient.expire(key, Math.floor(duration / 1000));
      }

      this.sessionLocks.set(sessionId, lockData);
      console.log(`Session locked: ${sessionId} - ${reason}`);
    } catch (error) {
      console.error('Error locking session:', error);
    }
  }

  // Unlock session
  async unlockSession(sessionId) {
    try {
      const key = `session_lock:${sessionId}`;
      await this.redisClient.del(key);
      this.sessionLocks.delete(sessionId);
      
      console.log(`Session unlocked: ${sessionId}`);
    } catch (error) {
      console.error('Error unlocking session:', error);
    }
  }

  // Check if session is locked
  async isSessionLocked(sessionId) {
    try {
      const key = `session_lock:${sessionId}`;
      const lockData = await this.redisClient.hGetAll(key);
      
      if (!lockData || Object.keys(lockData).length === 0) {
        return false;
      }

      const lockedAt = parseInt(lockData.lockedAt);
      const expiresAt = parseInt(lockData.expiresAt);
      
      // Check if lock has expired
      if (expiresAt && Date.now() > expiresAt) {
        await this.unlockSession(sessionId);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Error checking session lock:', error);
      return false;
    }
  }

  // Blacklist session
  async blacklistSession(sessionId, userId) {
    try {
      const key = `blacklisted_session:${sessionId}`;
      await this.redisClient.setEx(key, 86400, userId); // 24 hours
    } catch (error) {
      console.error('Error blacklisting session:', error);
    }
  }

  // Check if session is blacklisted
  async isSessionBlacklisted(sessionId) {
    try {
      const key = `blacklisted_session:${sessionId}`;
      const blacklisted = await this.redisClient.exists(key);
      return blacklisted === 1;
    } catch (error) {
      console.error('Error checking session blacklist:', error);
      return false;
    }
  }

  // Session validation middleware
  middleware(options = {}) {
    const {
      required = true,
      maxIdleTime = this.config.sessionTimeout,
      validateFingerprint = this.config.deviceFingerprint,
      checkLockout = true
    } = options;

    return async (req, res, next) => {
      try {
        const sessionId = req.headers['x-session-id'] || req.cookies?.sessionId;
        
        if (!sessionId) {
          if (required) {
            return res.status(401).json({
              error: 'Session required',
              code: 'SESSION_REQUIRED'
            });
          }
          return next();
        }

        // Check if session is blacklisted
        if (await this.isSessionBlacklisted(sessionId)) {
          return res.status(401).json({
            error: 'Session is invalid',
            code: 'SESSION_INVALID'
          });
        }

        // Check if session is locked
        if (checkLockout && await this.isSessionLocked(sessionId)) {
          return res.status(423).json({
            error: 'Session is locked',
            code: 'SESSION_LOCKED'
          });
        }

        // Get and validate session
        const session = await this.getSession(sessionId);
        if (!session) {
          if (required) {
            return res.status(401).json({
              error: 'Invalid session',
              code: 'INVALID_SESSION'
            });
          }
          return next();
        }

        // Check session expiration
        if (Date.now() > session.expires) {
          await this.invalidateSession(sessionId);
          if (required) {
            return res.status(401).json({
              error: 'Session expired',
              code: 'SESSION_EXPIRED'
            });
          }
          return next();
        }

        // Validate fingerprint if required
        if (validateFingerprint && session.fingerprint) {
          const currentFingerprint = await this.generateSessionFingerprint({
            ...session,
            userAgent: req.headers['user-agent'],
            ipAddress: req.ip
          });
          
          if (!await this.validateSessionFingerprint(sessionId, currentFingerprint)) {
            await this.lockSession(sessionId, 'Fingerprint mismatch');
            return res.status(401).json({
              error: 'Session fingerprint mismatch',
              code: 'FINGERPRINT_MISMATCH'
            });
          }
        }

        // Update session activity
        const activityData = {
          ipAddress: req.ip,
          userAgent: req.headers['user-agent'],
          lastRequest: Date.now(),
          path: req.path,
          method: req.method
        };

        await this.updateSessionActivity(sessionId, activityData);

        // Attach session to request
        req.session = session;
        req.sessionId = sessionId;

        next();
      } catch (error) {
        console.error('Session middleware error:', error);
        if (required) {
          return res.status(500).json({
            error: 'Session validation error',
            code: 'SESSION_ERROR'
          });
        }
        next();
      }
    };
  }

  // Get session statistics
  async getSessionStats() {
    try {
      const totalSessions = await this.redisClient.keys(`${this.config.sessionPrefix}*`);
      const activeSessions = [];
      
      for (const key of totalSessions) {
        const session = await this.getSession(key.replace(this.config.sessionPrefix, ''));
        if (session && session.isActive && session.expires > Date.now()) {
          activeSessions.push(session);
        }
      }

      return {
        total: totalSessions.length,
        active: activeSessions.length,
        byRiskLevel: {
          low: activeSessions.filter(s => s.riskScore <= 2).length,
          medium: activeSessions.filter(s => s.riskScore > 2 && s.riskScore <= 5).length,
          high: activeSessions.filter(s => s.riskScore > 5).length
        },
        averageAge: activeSessions.length > 0 
          ? activeSessions.reduce((sum, s) => sum + (Date.now() - s.created), 0) / activeSessions.length / 1000 / 60
          : 0
      };
    } catch (error) {
      console.error('Error getting session stats:', error);
      return null;
    }
  }

  // Clean up expired sessions
  async cleanupExpiredSessions() {
    try {
      const sessionKeys = await this.redisClient.keys(`${this.config.sessionPrefix}*`);
      const currentTime = Date.now();
      let cleaned = 0;

      for (const key of sessionKeys) {
        const sessionId = key.replace(this.config.sessionPrefix, '');
        const session = await this.getSession(sessionId);
        
        if (session && session.expires <= currentTime) {
          await this.invalidateSession(sessionId);
          cleaned++;
        }
      }

      console.log(`Cleaned up ${cleaned} expired sessions`);
      return cleaned;
    } catch (error) {
      console.error('Error cleaning up expired sessions:', error);
      return 0;
    }
  }

  // Health check for session system
  async healthCheck() {
    try {
      const redisConnected = this.redisClient.isOpen;
      const stats = await this.getSessionStats();
      
      return {
        healthy: redisConnected,
        redisConnected,
        activeSessions: stats?.active || 0,
        totalSessions: stats?.total || 0,
        lockCount: this.sessionLocks.size
      };
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }
}

module.exports = {
  SessionManager
};