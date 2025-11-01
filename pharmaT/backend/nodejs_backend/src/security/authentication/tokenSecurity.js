/**
 * Secure Token Management
 * JWT tokens, refresh tokens, and token lifecycle management
 */

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const Redis = require('redis');
const { v4: uuidv4 } = require('uuid');
const { EncryptionService } = require('../encryption/encryption');

class TokenSecurity {
  constructor() {
    this.redisClient = null;
    this.encryptionService = new EncryptionService();
    this.config = {
      accessTokenExpiry: 15 * 60, // 15 minutes
      refreshTokenExpiry: 7 * 24 * 60 * 60, // 7 days
      maxRefreshTokens: 5, // Maximum refresh tokens per user
      tokenBlacklistTtl: 30 * 24 * 60 * 60, // 30 days
      algorithm: 'RS256',
      issuer: 'tutoring-platform',
      audience: 'tutoring-platform-users',
      jwtid: true, // Include JWT ID
      subject: true // Include subject
    };
    
    this.tokenStore = new Map();
    this.refreshTokenStore = new Map();
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
      console.log('✅ Token Security initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Token Security: ${error.message}`);
    }
  }

  // Generate RSA key pair for JWT signing
  async generateKeyPair() {
    return new Promise((resolve, reject) => {
      crypto.generateKeyPair('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: {
          type: 'spki',
          format: 'pem'
        },
        privateKeyEncoding: {
          type: 'pkcs8',
          format: 'pem'
        }
      }, (err, publicKey, privateKey) => {
        if (err) {
          reject(err);
        } else {
          resolve({ publicKey, privateKey });
        }
      });
    });
  }

  // Generate access token
  async generateAccessToken(payload, options = {}) {
    const {
      userId,
      email,
      role = 'user',
      permissions = [],
      sessionId = uuidv4(),
      deviceInfo = {},
      ipAddress = null,
      expiresIn = this.config.accessTokenExpiry
    } = payload;

    const tokenPayload = {
      sub: userId,
      email,
      role,
      permissions,
      sessionId,
      deviceInfo,
      ipAddress,
      type: 'access',
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + expiresIn,
      iss: this.config.issuer,
      aud: this.config.audience,
      jti: uuidv4()
    };

    // Merge additional payload data
    Object.assign(tokenPayload, options);

    const privateKey = process.env.JWT_PRIVATE_KEY;
    if (!privateKey) {
      throw new Error('JWT private key not configured');
    }

    return jwt.sign(tokenPayload, privateKey, {
      algorithm: this.config.algorithm,
      expiresIn: expiresIn,
      issuer: this.config.issuer,
      audience: this.config.audience,
      jwtid: true,
      subject: userId
    });
  }

  // Generate refresh token
  async generateRefreshToken(userId, options = {}) {
    const {
      sessionId = uuidv4(),
      deviceInfo = {},
      ipAddress = null,
      expiresIn = this.config.refreshTokenExpiry,
      metadata = {}
    } = options;

    const refreshTokenId = uuidv4();
    const tokenData = {
      id: refreshTokenId,
      userId,
      sessionId,
      deviceInfo,
      ipAddress,
      created: Date.now(),
      lastUsed: Date.now(),
      expiresAt: Date.now() + (expiresIn * 1000),
      isActive: true,
      usageCount: 0,
      metadata
    };

    // Store refresh token in Redis
    await this.storeRefreshToken(refreshTokenId, tokenData);

    // Create JWT refresh token
    const refreshPayload = {
      sub: userId,
      type: 'refresh',
      sessionId,
      jti: refreshTokenId,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + expiresIn,
      iss: this.config.issuer,
      aud: this.config.audience
    };

    const privateKey = process.env.JWT_PRIVATE_KEY;
    if (!privateKey) {
      throw new Error('JWT private key not configured');
    }

    const refreshToken = jwt.sign(refreshPayload, privateKey, {
      algorithm: this.config.algorithm,
      expiresIn: expiresIn,
      issuer: this.config.issuer,
      audience: this.config.audience,
      jwtid: true,
      subject: userId
    });

    // Track refresh token in user's token store
    await this.addUserRefreshToken(userId, refreshTokenId, refreshToken);

    return refreshToken;
  }

  // Verify access token
  async verifyAccessToken(token, options = {}) {
    const publicKey = process.env.JWT_PUBLIC_KEY;
    if (!publicKey) {
      throw new Error('JWT public key not configured');
    }

    try {
      const decoded = jwt.verify(token, publicKey, {
        algorithms: [this.config.algorithm],
        issuer: this.config.issuer,
        audience: this.config.audience
      });

      // Check if token is blacklisted
      if (await this.isTokenBlacklisted(decoded.jti)) {
        throw new Error('Token is blacklisted');
      }

      // Check session validity
      if (decoded.sessionId && !(await this.isSessionValid(decoded.sessionId))) {
        throw new Error('Session is invalid');
      }

      return {
        valid: true,
        payload: decoded,
        expired: false
      };
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return {
          valid: false,
          payload: null,
          expired: true,
          error: 'Token expired'
        };
      }
      
      if (error.name === 'JsonWebTokenError') {
        return {
          valid: false,
          payload: null,
          expired: false,
          error: 'Invalid token'
        };
      }

      return {
        valid: false,
        payload: null,
        expired: false,
        error: error.message
      };
    }
  }

  // Verify refresh token
  async verifyRefreshToken(token, options = {}) {
    const publicKey = process.env.JWT_PUBLIC_KEY;
    if (!publicKey) {
      throw new Error('JWT public key not configured');
    }

    try {
      const decoded = jwt.verify(token, publicKey, {
        algorithms: [this.config.algorithm],
        issuer: this.config.issuer,
        audience: this.config.audience
      });

      if (decoded.type !== 'refresh') {
        throw new Error('Invalid token type');
      }

      // Check if refresh token exists and is valid
      const tokenData = await this.getRefreshToken(decoded.jti);
      if (!tokenData || !tokenData.isActive) {
        throw new Error('Refresh token not found or invalid');
      }

      // Update usage statistics
      await this.updateRefreshTokenUsage(decoded.jti);

      return {
        valid: true,
        payload: decoded,
        tokenData
      };
    } catch (error) {
      return {
        valid: false,
        payload: null,
        error: error.message
      };
    }
  }

  // Refresh access token using refresh token
  async refreshAccessToken(refreshToken, options = {}) {
    const verification = await this.verifyRefreshToken(refreshToken);
    
    if (!verification.valid) {
      throw new Error(`Invalid refresh token: ${verification.error}`);
    }

    const { payload } = verification;
    
    // Get user information
    const userData = await this.getUserData(payload.sub);
    if (!userData) {
      throw new Error('User not found');
    }

    // Generate new access token
    const newAccessToken = await this.generateAccessToken({
      userId: payload.sub,
      email: userData.email,
      role: userData.role,
      permissions: userData.permissions || [],
      sessionId: payload.sessionId,
      deviceInfo: verification.tokenData.deviceInfo,
      ipAddress: verification.tokenData.ipAddress
    });

    // Optionally rotate refresh token for security
    let newRefreshToken = null;
    if (options.rotateRefreshToken) {
      await this.revokeRefreshToken(payload.jti);
      newRefreshToken = await this.generateRefreshToken(payload.sub, {
        sessionId: payload.sessionId,
        deviceInfo: verification.tokenData.deviceInfo,
        ipAddress: verification.tokenData.ipAddress
      });
    }

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: this.config.accessTokenExpiry,
      tokenType: 'Bearer'
    };
  }

  // Store refresh token in Redis
  async storeRefreshToken(tokenId, tokenData) {
    try {
      const key = `refresh_token:${tokenId}`;
      await this.redisClient.hSet(key, {
        userId: tokenData.userId,
        sessionId: tokenData.sessionId,
        deviceInfo: JSON.stringify(tokenData.deviceInfo),
        ipAddress: tokenData.ipAddress || '',
        created: tokenData.created.toString(),
        lastUsed: tokenData.lastUsed.toString(),
        expiresAt: tokenData.expiresAt.toString(),
        isActive: tokenData.isActive.toString(),
        usageCount: tokenData.usageCount.toString(),
        metadata: JSON.stringify(tokenData.metadata)
      });
      
      // Set expiration
      const ttl = Math.floor((tokenData.expiresAt - Date.now()) / 1000);
      await this.redisClient.expire(key, ttl);
    } catch (error) {
      console.error('Error storing refresh token:', error);
      throw error;
    }
  }

  // Get refresh token from Redis
  async getRefreshToken(tokenId) {
    try {
      const key = `refresh_token:${tokenId}`;
      const data = await this.redisClient.hGetAll(key);
      
      if (!data || Object.keys(data).length === 0) {
        return null;
      }

      return {
        id: tokenId,
        userId: data.userId,
        sessionId: data.sessionId,
        deviceInfo: JSON.parse(data.deviceInfo || '{}'),
        ipAddress: data.ipAddress || null,
        created: parseInt(data.created),
        lastUsed: parseInt(data.lastUsed),
        expiresAt: parseInt(data.expiresAt),
        isActive: data.isActive === 'true',
        usageCount: parseInt(data.usageCount),
        metadata: JSON.parse(data.metadata || '{}')
      };
    } catch (error) {
      console.error('Error retrieving refresh token:', error);
      return null;
    }
  }

  // Add refresh token to user's token store
  async addUserRefreshToken(userId, tokenId, refreshToken) {
    try {
      const key = `user_refresh_tokens:${userId}`;
      await this.redisClient.sAdd(key, tokenId);
      
      // Limit number of refresh tokens per user
      const tokens = await this.redisClient.sMembers(key);
      if (tokens.length > this.config.maxRefreshTokens) {
        // Remove oldest tokens
        const sortedTokens = await this.getRefreshTokensByAge(userId);
        const toRemove = sortedTokens.slice(0, tokens.length - this.config.maxRefreshTokens);
        
        for (const oldTokenId of toRemove) {
          await this.revokeRefreshToken(oldTokenId);
        }
      }
    } catch (error) {
      console.error('Error adding user refresh token:', error);
    }
  }

  // Update refresh token usage statistics
  async updateRefreshTokenUsage(tokenId) {
    try {
      const key = `refresh_token:${tokenId}`;
      await this.redisClient.hIncrBy(key, 'usageCount', 1);
      await this.redisClient.hSet(key, 'lastUsed', Date.now().toString());
    } catch (error) {
      console.error('Error updating refresh token usage:', error);
    }
  }

  // Revoke refresh token
  async revokeRefreshToken(tokenId) {
    try {
      // Get token data before deletion
      const tokenData = await this.getRefreshToken(tokenId);
      
      if (tokenData) {
        // Add to blacklist
        await this.blacklistToken(tokenId);
        
        // Remove from Redis
        await this.redisClient.del(`refresh_token:${tokenId}`);
        
        // Remove from user's token store
        const userKey = `user_refresh_tokens:${tokenData.userId}`;
        await this.redisClient.sRem(userKey, tokenId);
      }
    } catch (error) {
      console.error('Error revoking refresh token:', error);
    }
  }

  // Blacklist token
  async blacklistToken(tokenId) {
    try {
      const key = `blacklisted_tokens:${tokenId}`;
      await this.redisClient.setEx(key, this.config.tokenBlacklistTtl, 'revoked');
    } catch (error) {
      console.error('Error blacklisting token:', error);
    }
  }

  // Check if token is blacklisted
  async isTokenBlacklisted(tokenId) {
    try {
      const key = `blacklisted_tokens:${tokenId}`;
      const isBlacklisted = await this.redisClient.exists(key);
      return isBlacklisted === 1;
    } catch (error) {
      console.error('Error checking token blacklist:', error);
      return false;
    }
  }

  // Check session validity
  async isSessionValid(sessionId) {
    try {
      const key = `session:${sessionId}`;
      const sessionData = await this.redisClient.hGetAll(key);
      return sessionData && Object.keys(sessionData).length > 0;
    } catch (error) {
      console.error('Error checking session validity:', error);
      return false;
    }
  }

  // Create user session
  async createSession(userId, sessionData) {
    const sessionId = uuidv4();
    const key = `session:${sessionId}`;
    
    const session = {
      userId,
      created: Date.now(),
      lastActive: Date.now(),
      expiresAt: Date.now() + (this.config.refreshTokenExpiry * 1000),
      isActive: true,
      ...sessionData
    };

    await this.redisClient.hSet(key, {
      userId: session.userId,
      created: session.created.toString(),
      lastActive: session.lastActive.toString(),
      expiresAt: session.expiresAt.toString(),
      isActive: session.isActive.toString(),
      ...sessionData
    });

    await this.redisClient.expire(key, Math.floor((session.expiresAt - Date.now()) / 1000));

    return sessionId;
  }

  // Update session activity
  async updateSessionActivity(sessionId) {
    try {
      const key = `session:${sessionId}`;
      await this.redisClient.hSet(key, 'lastActive', Date.now().toString());
    } catch (error) {
      console.error('Error updating session activity:', error);
    }
  }

  // Revoke all user sessions
  async revokeAllUserSessions(userId) {
    try {
      // Find all refresh tokens for user
      const tokenKeys = await this.redisClient.keys(`refresh_token:*`);
      const userTokens = [];

      for (const key of tokenKeys) {
        const tokenId = key.split(':')[2];
        const tokenData = await this.getRefreshToken(tokenId);
        if (tokenData && tokenData.userId === userId) {
          userTokens.push(tokenId);
        }
      }

      // Revoke all tokens
      for (const tokenId of userTokens) {
        await this.revokeRefreshToken(tokenId);
      }

      // Revoke all sessions
      const sessionKeys = await this.redisClient.keys('session:*');
      for (const key of sessionKeys) {
        const sessionData = await this.redisClient.hGetAll(key);
        if (sessionData.userId === userId) {
          await this.redisClient.del(key);
        }
      }

      console.log(`Revoked ${userTokens.length} tokens and sessions for user ${userId}`);
    } catch (error) {
      console.error('Error revoking user sessions:', error);
    }
  }

  // Get user data (placeholder - implement based on your user system)
  async getUserData(userId) {
    // This should integrate with your actual user system
    // For now, return placeholder data
    return {
      id: userId,
      email: 'user@example.com',
      role: 'user',
      permissions: []
    };
  }

  // Get refresh tokens sorted by age for user
  async getRefreshTokensByAge(userId) {
    try {
      const key = `user_refresh_tokens:${userId}`;
      const tokenIds = await this.redisClient.sMembers(key);
      
      const tokenData = [];
      for (const tokenId of tokenIds) {
        const data = await this.getRefreshToken(tokenId);
        if (data) {
          tokenData.push({ id: tokenId, created: data.created });
        }
      }

      // Sort by creation date (oldest first)
      return tokenData.sort((a, b) => a.created - b.created).map(t => t.id);
    } catch (error) {
      console.error('Error getting user refresh tokens:', error);
      return [];
    }
  }

  // Clean up expired tokens
  async cleanupExpiredTokens() {
    try {
      const tokenKeys = await this.redisClient.keys('refresh_token:*');
      const currentTime = Date.now();
      
      for (const key of tokenKeys) {
        const tokenId = key.split(':')[2];
        const tokenData = await this.getRefreshToken(tokenId);
        
        if (tokenData && tokenData.expiresAt < currentTime) {
          await this.revokeRefreshToken(tokenId);
        }
      }
      
      console.log('Expired tokens cleanup completed');
    } catch (error) {
      console.error('Error cleaning up expired tokens:', error);
    }
  }

  // Token introspection endpoint data
  async introspectToken(token) {
    const verification = await this.verifyAccessToken(token);
    
    if (!verification.valid) {
      return {
        active: false,
        token_type: 'access_token'
      };
    }

    return {
      active: true,
      token_type: 'access_token',
      client_id: this.config.audience,
      username: verification.payload.email,
      scope: verification.payload.permissions?.join(' ') || '',
      sub: verification.payload.sub,
      exp: verification.payload.exp,
      iat: verification.payload.iat,
      aud: verification.payload.aud,
      iss: verification.payload.iss,
      jti: verification.payload.jti
    };
  }

  // Health check for token system
  async healthCheck() {
    try {
      const redisConnected = this.redisClient.isOpen;
      const hasKeys = process.env.JWT_PRIVATE_KEY && process.env.JWT_PUBLIC_KEY;
      
      return {
        healthy: redisConnected && hasKeys,
        redisConnected,
        hasKeys,
        tokenStoreSize: this.tokenStore.size,
        refreshTokenStoreSize: this.refreshTokenStore.size
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
  TokenSecurity
};