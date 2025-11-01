/**
 * Biometric Authentication Integration
 * Support for various biometric authentication methods
 */

const crypto = require('crypto');
const cryptojs = require('crypto-js');
const jwt = require('jsonwebtoken');
const Redis = require('redis');
const { v4: uuidv4 } = require('uuid');
const { EncryptionService } = require('../encryption/encryption');

class BiometricIntegration {
  constructor() {
    this.redisClient = null;
    this.encryptionService = new EncryptionService();
    this.config = {
      biometricTypes: {
        FINGERPRINT: 'fingerprint',
        FACIAL: 'facial',
        VOICE: 'voice',
        IRIS: 'iris',
        RETINA: 'retina',
        HEARTBEAT: 'heartbeat',
        BEHAVIORAL: 'behavioral'
      },
      templateVersion: '1.0',
      maxTemplates: 5,
      encryptionAlgorithm: 'AES-256-GCM',
      hashAlgorithm: 'SHA-256',
      fallbackRequired: true,
      confidenceThreshold: 0.85,
      timeout: 30000, // 30 seconds
      retryAttempts: 3
    };
    
    this.biometricStore = new Map();
    this.activeChallenges = new Map();
    this.userBiometrics = new Map();
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
      console.log('✅ Biometric Integration initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Biometric Integration: ${error.message}`);
    }
  }

  // Register biometric template for user
  async registerBiometric(userId, biometricData, options = {}) {
    const {
      type = this.config.biometricTypes.FINGERPRINT,
      deviceId,
      deviceInfo = {},
      metadata = {}
    } = options;

    if (!Object.values(this.config.biometricTypes).includes(type)) {
      throw new Error(`Invalid biometric type: ${type}`);
    }

    try {
      // Generate unique template ID
      const templateId = uuidv4();
      
      // Encrypt biometric template
      const encryptedTemplate = await this.encryptionService.encrypt(
        JSON.stringify(biometricData),
        await this.getBiometricKey(userId)
      );

      // Create template metadata
      const template = {
        id: templateId,
        userId,
        type,
        deviceId: deviceId || uuidv4(),
        deviceInfo,
        metadata,
        encryptedTemplate,
        created: Date.now(),
        lastUsed: null,
        usageCount: 0,
        isActive: true,
        version: this.config.templateVersion,
        hash: await this.generateBiometricHash(biometricData),
        quality: biometricData.quality || 0.8,
        confidence: 1.0 // Full confidence for enrollment
      };

      // Store template
      await this.storeBiometricTemplate(template);
      this.biometricStore.set(templateId, template);
      this.trackUserBiometric(userId, templateId);

      // Check if this is the first template for this biometric type
      const existingTemplates = await this.getUserBiometricTemplates(userId, type);
      if (existingTemplates.length === 1) {
        // First template for this type - set as primary
        await this.setPrimaryTemplate(userId, type, templateId);
      }

      console.log(`Biometric template registered: ${templateId} for user: ${userId}`);
      return {
        templateId,
        type,
        isPrimary: existingTemplates.length === 1,
        success: true
      };
    } catch (error) {
      throw new Error(`Failed to register biometric: ${error.message}`);
    }
  }

  // Generate biometric authentication challenge
  async generateChallenge(userId, options = {}) {
    const {
      types = [this.config.biometricTypes.FINGERPRINT],
      fallbackRequired = this.config.fallbackRequired,
      timeout = this.config.timeout,
      nonce = crypto.randomBytes(16).toString('hex'),
      challengeType = 'authentication'
    } = options;

    try {
      const challengeId = uuidv4();
      const challenge = {
        id: challengeId,
        userId,
        types,
        nonce,
        challengeType,
        created: Date.now(),
        expires: Date.now() + timeout,
        attempts: 0,
        maxAttempts: this.config.retryAttempts,
        fallbackRequired,
        status: 'pending',
        responses: [],
        metadata: options.metadata || {}
      };

      // Store challenge
      await this.storeChallenge(challenge);
      this.activeChallenges.set(challengeId, challenge);

      console.log(`Biometric challenge generated: ${challengeId} for user: ${userId}`);
      return {
        challengeId,
        nonce,
        types,
        expiresAt: challenge.expires,
        timeout,
        fallbackRequired
      };
    } catch (error) {
      throw new Error(`Failed to generate challenge: ${error.message}`);
    }
  }

  // Verify biometric response
  async verifyBiometricResponse(challengeId, biometricResponse, options = {}) {
    try {
      const challenge = await this.getChallenge(challengeId);
      if (!challenge) {
        throw new Error('Challenge not found');
      }

      if (challenge.status !== 'pending') {
        throw new Error('Challenge is not active');
      }

      if (Date.now() > challenge.expires) {
        await this.expireChallenge(challengeId);
        throw new Error('Challenge has expired');
      }

      if (challenge.attempts >= challenge.maxAttempts) {
        await this.failChallenge(challengeId, 'Max attempts exceeded');
        throw new Error('Maximum attempts exceeded');
      }

      const { type, templateId, biometricData, deviceId } = biometricResponse;
      
      // Validate response
      if (!type || !templateId || !biometricData) {
        throw new Error('Invalid biometric response');
      }

      if (!challenge.types.includes(type)) {
        throw new Error(`Biometric type ${type} not requested`);
      }

      // Get template
      const template = await this.getBiometricTemplate(templateId);
      if (!template || !template.isActive) {
        throw new Error('Template not found or inactive');
      }

      if (template.userId !== challenge.userId) {
        throw new Error('Template does not belong to user');
      }

      // Decrypt template
      const decryptedTemplate = await this.encryptionService.decrypt(
        template.encryptedTemplate,
        await this.getBiometricKey(challenge.userId)
      );
      const storedTemplate = JSON.parse(decryptedTemplate);

      // Perform biometric matching
      const matchResult = await this.performBiometricMatch(
        type,
        biometricData,
        storedTemplate,
        options
      );

      // Record attempt
      challenge.attempts++;
      
      const responseRecord = {
        type,
        templateId,
        deviceId,
        matchScore: matchResult.score,
        confidence: matchResult.confidence,
        timestamp: Date.now(),
        success: matchResult.success
      };
      
      challenge.responses.push(responseRecord);

      if (matchResult.success) {
        // Successful match
        challenge.status = 'success';
        challenge.matched = true;
        challenge.verified = true;
        challenge.successAt = Date.now();

        // Update template usage
        await this.updateTemplateUsage(templateId);

        // Complete challenge
        await this.completeChallenge(challenge);
        
        console.log(`Biometric authentication successful: ${challengeId}`);
        
        return {
          success: true,
          confidence: matchResult.confidence,
          type,
          templateId,
          verified: true
        };
      } else {
        // Failed match
        challenge.matched = false;
        
        if (challenge.attempts >= challenge.maxAttempts) {
          await this.failChallenge(challengeId, 'Authentication failed');
        } else {
          await this.storeChallenge(challenge);
        }

        console.log(`Biometric authentication failed: ${challengeId}`);
        
        return {
          success: false,
          confidence: matchResult.confidence,
          type,
          templateId,
          attemptsRemaining: challenge.maxAttempts - challenge.attempts,
          verified: false
        };
      }
    } catch (error) {
      console.error('Biometric verification error:', error);
      
      // Mark challenge as failed
      await this.failChallenge(challengeId, error.message);
      
      throw error;
    }
  }

  // Perform biometric matching
  async performBiometricMatch(type, inputData, template, options = {}) {
    const startTime = Date.now();
    
    try {
      let score = 0;
      let confidence = 0;
      
      switch (type) {
        case this.config.biometricTypes.FINGERPRINT:
          ({ score, confidence } = await this.matchFingerprint(inputData, template, options));
          break;
          
        case this.config.biometricTypes.FACIAL:
          ({ score, confidence } = await this.matchFacial(inputData, template, options));
          break;
          
        case this.config.biometricTypes.VOICE:
          ({ score, confidence } = await this.matchVoice(inputData, template, options));
          break;
          
        case this.config.biometricTypes.IRIS:
          ({ score, confidence } = await this.matchIris(inputData, template, options));
          break;
          
        case this.config.biometricTypes.BEHAVIORAL:
          ({ score, confidence } = await this.matchBehavioral(inputData, template, options));
          break;
          
        default:
          throw new Error(`Unsupported biometric type: ${type}`);
      }

      // Apply quality and freshness checks
      const qualityCheck = this.checkQuality(inputData, template);
      const freshnessCheck = this.checkFreshness(inputData, template);
      
      // Calculate final confidence
      const finalConfidence = (confidence * 0.4) + (qualityCheck * 0.3) + (freshnessCheck * 0.3);
      
      // Determine success based on threshold
      const success = finalConfidence >= this.config.confidenceThreshold && score >= 0.75;
      
      const processingTime = Date.now() - startTime;
      
      console.log(`Biometric matching completed: type=${type}, score=${score.toFixed(3)}, confidence=${finalConfidence.toFixed(3)}, success=${success}, time=${processingTime}ms`);
      
      return {
        score,
        confidence: finalConfidence,
        success,
        processingTime
      };
    } catch (error) {
      console.error('Biometric matching error:', error);
      return {
        score: 0,
        confidence: 0,
        success: false,
        error: error.message
      };
    }
  }

  // Fingerprint matching algorithm
  async matchFingerprint(inputData, template, options) {
    try {
      // Simplified fingerprint matching
      // In real implementation, use specialized libraries like FingerJS, BioAPI, etc.
      
      const inputHash = await this.generateBiometricHash(inputData);
      const templateHash = template.hash;
      
      // Calculate similarity (simplified)
      let matches = 0;
      const minLength = Math.min(inputHash.length, templateHash.length);
      
      for (let i = 0; i < minLength; i++) {
        if (inputHash[i] === templateHash[i]) {
          matches++;
        }
      }
      
      const score = matches / minLength;
      const confidence = Math.min(score * 1.2, 1.0); // Boost confidence slightly
      
      return { score, confidence };
    } catch (error) {
      console.error('Fingerprint matching error:', error);
      return { score: 0, confidence: 0 };
    }
  }

  // Facial recognition matching algorithm
  async matchFacial(inputData, template, options) {
    try {
      // Simplified facial recognition
      // In real implementation, use libraries like face-api.js, OpenCV, etc.
      
      const inputHash = await this.generateBiometricHash(inputData);
      const templateHash = template.hash;
      
      let matches = 0;
      const minLength = Math.min(inputHash.length, templateHash.length);
      
      for (let i = 0; i < minLength; i++) {
        if (inputHash[i] === templateHash[i]) {
          matches++;
        }
      }
      
      const score = matches / minLength;
      const confidence = Math.min(score * 1.1, 1.0);
      
      return { score, confidence };
    } catch (error) {
      console.error('Facial recognition error:', error);
      return { score: 0, confidence: 0 };
    }
  }

  // Voice recognition matching algorithm
  async matchVoice(inputData, template, options) {
    try {
      // Simplified voice recognition
      // In real implementation, use libraries like Web Speech API, Azure Speech, etc.
      
      const inputHash = await this.generateBiometricHash(inputData);
      const templateHash = template.hash;
      
      let matches = 0;
      const minLength = Math.min(inputHash.length, templateHash.length);
      
      for (let i = 0; i < minLength; i++) {
        if (inputHash[i] === templateHash[i]) {
          matches++;
        }
      }
      
      const score = matches / minLength;
      const confidence = Math.min(score * 1.0, 1.0);
      
      return { score, confidence };
    } catch (error) {
      console.error('Voice recognition error:', error);
      return { score: 0, confidence: 0 };
    }
  }

  // Iris recognition matching algorithm
  async matchIris(inputData, template, options) {
    try {
      // Simplified iris recognition
      // In real implementation, use specialized biometric libraries
      
      const inputHash = await this.generateBiometricHash(inputData);
      const templateHash = template.hash;
      
      let matches = 0;
      const minLength = Math.min(inputHash.length, templateHash.length);
      
      for (let i = 0; i < minLength; i++) {
        if (inputHash[i] === templateHash[i]) {
          matches++;
        }
      }
      
      const score = matches / minLength;
      const confidence = Math.min(score * 1.3, 1.0); // Iris recognition is typically very accurate
      
      return { score, confidence };
    } catch (error) {
      console.error('Iris recognition error:', error);
      return { score: 0, confidence: 0 };
    }
  }

  // Behavioral biometric matching
  async matchBehavioral(inputData, template, options) {
    try {
      // Behavioral biometrics (typing patterns, mouse movements, etc.)
      const inputHash = await this.generateBiometricHash(inputData);
      const templateHash = template.hash;
      
      let matches = 0;
      const minLength = Math.min(inputHash.length, templateHash.length);
      
      for (let i = 0; i < minLength; i++) {
        if (inputHash[i] === templateHash[i]) {
          matches++;
        }
      }
      
      const score = matches / minLength;
      const confidence = Math.min(score * 0.9, 1.0); // Behavioral biometrics are less precise
      
      return { score, confidence };
    } catch (error) {
      console.error('Behavioral biometric error:', error);
      return { score: 0, confidence: 0 };
    }
  }

  // Generate biometric hash
  async generateBiometricHash(data) {
    try {
      const dataString = JSON.stringify(data);
      const hash = crypto.createHash(this.config.hashAlgorithm)
        .update(dataString)
        .digest('hex');
      return hash;
    } catch (error) {
      console.error('Error generating biometric hash:', error);
      throw error;
    }
  }

  // Check biometric data quality
  checkQuality(inputData, template) {
    try {
      // Check input data quality
      const inputQuality = inputData.quality || 0.8;
      const templateQuality = template.quality || 0.8;
      
      // Average quality
      const avgQuality = (inputQuality + templateQuality) / 2;
      
      // Apply penalties for very low quality
      if (avgQuality < 0.5) return 0.1;
      if (avgQuality < 0.7) return 0.6;
      
      return Math.min(avgQuality, 1.0);
    } catch (error) {
      return 0.5; // Default quality score
    }
  }

  // Check biometric data freshness
  checkFreshness(inputData, template) {
    try {
      // Check if biometric data is recent
      const inputTimestamp = inputData.timestamp || Date.now();
      const maxAge = 300000; // 5 minutes
      
      const age = Date.now() - inputTimestamp;
      
      if (age > maxAge) return 0.1; // Very old data
      if (age > maxAge / 2) return 0.6; // Moderately old
      
      return 1.0; // Fresh data
    } catch (error) {
      return 0.5; // Default freshness score
    }
  }

  // Get biometric key for user
  async getBiometricKey(userId) {
    // This should integrate with your key management system
    const keyMaterial = `biometric_${userId}_${process.env.BIOMETRIC_SALT || 'default_salt'}`;
    const key = crypto.createHash('sha256').update(keyMaterial).digest();
    return key;
  }

  // Store biometric template
  async storeBiometricTemplate(template) {
    try {
      const key = `biometric_template:${template.id}`;
      
      const templateData = {
        ...template,
        encryptedTemplate: JSON.stringify(template.encryptedTemplate)
      };
      
      await this.redisClient.hSet(key, templateData);
      await this.redisClient.expire(key, 86400 * 365); // 1 year
      
      console.log(`Biometric template stored: ${template.id}`);
    } catch (error) {
      console.error('Error storing biometric template:', error);
      throw error;
    }
  }

  // Get biometric template
  async getBiometricTemplate(templateId) {
    try {
      const key = `biometric_template:${templateId}`;
      const data = await this.redisClient.hGetAll(key);
      
      if (!data || Object.keys(data).length === 0) {
        return null;
      }
      
      return {
        ...data,
        id: data.id,
        userId: data.userId,
        type: data.type,
        deviceId: data.deviceId,
        deviceInfo: JSON.parse(data.deviceInfo || '{}'),
        metadata: JSON.parse(data.metadata || '{}'),
        encryptedTemplate: JSON.parse(data.encryptedTemplate),
        created: parseInt(data.created),
        lastUsed: data.lastUsed ? parseInt(data.lastUsed) : null,
        usageCount: parseInt(data.usageCount),
        isActive: data.isActive === 'true',
        version: data.version,
        hash: data.hash,
        quality: parseFloat(data.quality),
        confidence: parseFloat(data.confidence)
      };
    } catch (error) {
      console.error('Error retrieving biometric template:', error);
      return null;
    }
  }

  // Get user biometric templates
  async getUserBiometricTemplates(userId, type = null) {
    try {
      const userKey = `user_biometrics:${userId}`;
      const templateIds = await this.redisClient.sMembers(userKey);
      
      const templates = [];
      for (const templateId of templateIds) {
        const template = await this.getBiometricTemplate(templateId);
        if (template && template.isActive && (!type || template.type === type)) {
          templates.push(template);
        }
      }
      
      return templates;
    } catch (error) {
      console.error('Error getting user biometric templates:', error);
      return [];
    }
  }

  // Track user biometric
  trackUserBiometric(userId, templateId) {
    const key = `user_biometrics:${userId}`;
    this.redisClient.sAdd(key, templateId);
    
    if (!this.userBiometrics.has(userId)) {
      this.userBiometrics.set(userId, new Set());
    }
    this.userBiometrics.get(userId).add(templateId);
  }

  // Update template usage
  async updateTemplateUsage(templateId) {
    try {
      const template = await this.getBiometricTemplate(templateId);
      if (template) {
        template.lastUsed = Date.now();
        template.usageCount++;
        
        await this.storeBiometricTemplate(template);
        this.biometricStore.set(templateId, template);
      }
    } catch (error) {
      console.error('Error updating template usage:', error);
    }
  }

  // Set primary template
  async setPrimaryTemplate(userId, type, templateId) {
    try {
      const key = `primary_biometric:${userId}:${type}`;
      await this.redisClient.set(key, templateId);
      
      console.log(`Primary biometric template set: ${type} -> ${templateId} for user: ${userId}`);
    } catch (error) {
      console.error('Error setting primary template:', error);
    }
  }

  // Store challenge
  async storeChallenge(challenge) {
    try {
      const key = `biometric_challenge:${challenge.id}`;
      const challengeData = {
        ...challenge,
        responses: JSON.stringify(challenge.responses)
      };
      
      await this.redisClient.hSet(key, challengeData);
      await this.redisClient.expire(key, Math.floor((challenge.expires - Date.now()) / 1000));
      
      this.activeChallenges.set(challenge.id, challenge);
    } catch (error) {
      console.error('Error storing challenge:', error);
      throw error;
    }
  }

  // Get challenge
  async getChallenge(challengeId) {
    try {
      const key = `biometric_challenge:${challengeId}`;
      const data = await this.redisClient.hGetAll(key);
      
      if (!data || Object.keys(data).length === 0) {
        return null;
      }
      
      return {
        ...data,
        id: data.id,
        userId: data.userId,
        types: JSON.parse(data.types),
        nonce: data.nonce,
        challengeType: data.challengeType,
        created: parseInt(data.created),
        expires: parseInt(data.expires),
        attempts: parseInt(data.attempts),
        maxAttempts: parseInt(data.maxAttempts),
        fallbackRequired: data.fallbackRequired === 'true',
        status: data.status,
        responses: JSON.parse(data.responses || '[]'),
        metadata: JSON.parse(data.metadata || '{}'),
        matched: data.matched === 'true',
        verified: data.verified === 'true',
        successAt: data.successAt ? parseInt(data.successAt) : null
      };
    } catch (error) {
      console.error('Error retrieving challenge:', error);
      return null;
    }
  }

  // Complete challenge
  async completeChallenge(challenge) {
    try {
      challenge.status = 'completed';
      await this.storeChallenge(challenge);
      
      // Clean up active challenge
      this.activeChallenges.delete(challenge.id);
    } catch (error) {
      console.error('Error completing challenge:', error);
    }
  }

  // Fail challenge
  async failChallenge(challengeId, reason) {
    try {
      const challenge = await this.getChallenge(challengeId);
      if (challenge) {
        challenge.status = 'failed';
        challenge.failureReason = reason;
        challenge.failedAt = Date.now();
        
        await this.storeChallenge(challenge);
        this.activeChallenges.delete(challengeId);
      }
    } catch (error) {
      console.error('Error failing challenge:', error);
    }
  }

  // Expire challenge
  async expireChallenge(challengeId) {
    try {
      const challenge = await this.getChallenge(challengeId);
      if (challenge) {
        challenge.status = 'expired';
        challenge.expiredAt = Date.now();
        
        await this.storeChallenge(challenge);
        this.activeChallenges.delete(challengeId);
      }
    } catch (error) {
      console.error('Error expiring challenge:', error);
    }
  }

  // Remove biometric template
  async removeBiometricTemplate(userId, templateId) {
    try {
      const template = await this.getBiometricTemplate(templateId);
      if (!template || template.userId !== userId) {
        throw new Error('Template not found or access denied');
      }
      
      // Mark as inactive
      template.isActive = false;
      template.deactivated = Date.now();
      
      await this.storeBiometricTemplate(template);
      this.biometricStore.delete(templateId);
      
      // Remove from user tracking
      const userKey = `user_biometrics:${userId}`;
      await this.redisClient.sRem(userKey, templateId);
      
      if (this.userBiometrics.has(userId)) {
        this.userBiometrics.get(userId).delete(templateId);
      }
      
      console.log(`Biometric template removed: ${templateId}`);
    } catch (error) {
      throw new Error(`Failed to remove biometric template: ${error.message}`);
    }
  }

  // Get biometric statistics
  async getBiometricStats() {
    try {
      const templateKeys = await this.redisClient.keys('biometric_template:*');
      const activeTemplates = [];
      
      for (const key of templateKeys) {
        const templateId = key.split(':')[2];
        const template = await this.getBiometricTemplate(templateId);
        if (template && template.isActive) {
          activeTemplates.push(template);
        }
      }
      
      const challengeKeys = await this.redisClient.keys('biometric_challenge:*');
      const activeChallenges = [];
      
      for (const key of challengeKeys) {
        const challengeId = key.split(':')[2];
        const challenge = await this.getChallenge(challengeId);
        if (challenge && challenge.status === 'pending') {
          activeChallenges.push(challenge);
        }
      }
      
      return {
        totalTemplates: activeTemplates.length,
        activeChallenges: activeChallenges.length,
        byType: {
          fingerprint: activeTemplates.filter(t => t.type === this.config.biometricTypes.FINGERPRINT).length,
          facial: activeTemplates.filter(t => t.type === this.config.biometricTypes.FACIAL).length,
          voice: activeTemplates.filter(t => t.type === this.config.biometricTypes.VOICE).length,
          iris: activeTemplates.filter(t => t.type === this.config.biometricTypes.IRIS).length,
          behavioral: activeTemplates.filter(t => t.type === this.config.biometricTypes.BEHAVIORAL).length
        },
        successRate: this.calculateSuccessRate(activeChallenges)
      };
    } catch (error) {
      console.error('Error getting biometric stats:', error);
      return null;
    }
  }

  // Calculate success rate
  calculateSuccessRate(challenges) {
    if (challenges.length === 0) return 0;
    
    const completed = challenges.filter(c => c.status === 'success' || c.status === 'failed' || c.status === 'expired');
    const successful = challenges.filter(c => c.status === 'success');
    
    return completed.length > 0 ? successful.length / completed.length : 0;
  }

  // Health check for biometric system
  async healthCheck() {
    try {
      const redisConnected = this.redisClient.isOpen;
      const stats = await this.getBiometricStats();
      
      return {
        healthy: redisConnected,
        redisConnected,
        activeTemplates: stats?.totalTemplates || 0,
        activeChallenges: stats?.activeChallenges || 0,
        activeChallengesCount: this.activeChallenges.size,
        templateStoreSize: this.biometricStore.size
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
  BiometricIntegration
};