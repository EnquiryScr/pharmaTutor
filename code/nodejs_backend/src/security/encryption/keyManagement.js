/**
 * Key Management System
 * Secure key generation, storage, rotation, and lifecycle management
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const Redis = require('redis');
const { v4: uuidv4 } = require('uuid');
const { EncryptionService } = require('./encryption');

class KeyManagementSystem {
  constructor() {
    this.redisClient = null;
    this.encryptionService = new EncryptionService();
    this.masterKey = null;
    this.keyStore = new Map();
    this.rotationSchedule = new Map();
    this.config = {
      masterKeyPath: './keys/master.key',
      keyStorePath: './keys/keystore.json',
      keyRotationInterval: 90 * 24 * 60 * 60 * 1000, // 90 days in milliseconds
      keyBackupPath: './keys/backup/',
      keyVersion: '1.0.0'
    };
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
      
      // Load or create master key
      await this.initializeMasterKey();
      
      // Load existing keys
      await this.loadKeyStore();
      
      // Start key rotation scheduler
      this.startKeyRotationScheduler();
      
      console.log('✅ Key Management System initialized');
    } catch (error) {
      console.error('❌ Failed to initialize Key Management System:', error);
      throw error;
    }
  }

  // Initialize or load master key
  async initializeMasterKey() {
    try {
      const masterKeyPath = this.config.masterKeyPath;
      
      try {
        // Try to load existing master key
        const masterKeyData = await fs.readFile(masterKeyPath);
        this.masterKey = masterKeyData;
        console.log('Master key loaded from file');
      } catch (error) {
        // Generate new master key
        this.masterKey = this.encryptionService.generateKey(32);
        await this.saveMasterKey();
        console.log('New master key generated');
      }
    } catch (error) {
      throw new Error(`Failed to initialize master key: ${error.message}`);
    }
  }

  // Save master key to file
  async saveMasterKey() {
    try {
      const masterKeyDir = path.dirname(this.config.masterKeyPath);
      await fs.mkdir(masterKeyDir, { recursive: true });
      await fs.writeFile(this.config.masterKeyPath, this.masterKey);
      
      // Set restrictive file permissions
      await fs.chmod(this.config.masterKeyPath, 0o600);
    } catch (error) {
      throw new Error(`Failed to save master key: ${error.message}`);
    }
  }

  // Generate new encryption key
  async generateKey(keyId = null, options = {}) {
    const {
      keyType = 'encryption',
      algorithm = 'aes-256-gcm',
      metadata = {}
    } = options;

    const id = keyId || uuidv4();
    const key = this.encryptionService.generateKey(32);
    const salt = this.encryptionService.generateSalt();
    
    const keyInfo = {
      id,
      key,
      salt,
      type: keyType,
      algorithm,
      metadata,
      created: Date.now(),
      lastUsed: null,
      usageCount: 0,
      isActive: true,
      version: 1
    };

    // Encrypt and store the key
    const encryptedKey = await this.encryptionService.encrypt(key.toString('hex'), this.masterKey);
    const encryptedSalt = await this.encryptionService.encrypt(salt.toString('hex'), this.masterKey);

    keyInfo.encryptedKey = encryptedKey;
    keyInfo.encryptedSalt = encryptedSalt;

    // Store in memory and Redis
    this.keyStore.set(id, keyInfo);
    await this.storeKeyInRedis(id, keyInfo);

    // Store in persistent storage
    await this.saveKeyStore();

    console.log(`Generated new ${keyType} key: ${id}`);
    return id;
  }

  // Retrieve encryption key
  async getKey(keyId, decrypt = true) {
    try {
      const keyInfo = this.keyStore.get(keyId) || await this.getKeyFromRedis(keyId);
      
      if (!keyInfo) {
        throw new Error(`Key not found: ${keyId}`);
      }

      if (!keyInfo.isActive) {
        throw new Error(`Key is inactive: ${keyId}`);
      }

      // Update usage statistics
      keyInfo.lastUsed = Date.now();
      keyInfo.usageCount++;
      
      if (decrypt) {
        const decryptedKey = await this.encryptionService.decrypt(keyInfo.encryptedKey, this.masterKey);
        const decryptedSalt = await this.encryptionService.decrypt(keyInfo.encryptedSalt, this.masterKey);
        
        return {
          ...keyInfo,
          key: Buffer.from(decryptedKey, 'hex'),
          salt: Buffer.from(decryptedSalt, 'hex')
        };
      }

      return keyInfo;
    } catch (error) {
      throw new Error(`Failed to retrieve key ${keyId}: ${error.message}`);
    }
  }

  // Rotate encryption key
  async rotateKey(keyId, options = {}) {
    const {
      createNew = true,
      keepOld = false
    } = options;

    try {
      const oldKeyInfo = await this.getKey(keyId);
      
      // Create new key if requested
      let newKeyId = keyId;
      if (createNew) {
        newKeyId = await this.generateKey(null, {
          keyType: oldKeyInfo.type,
          algorithm: oldKeyInfo.algorithm,
          metadata: {
            ...oldKeyInfo.metadata,
            rotatedFrom: keyId,
            rotationReason: 'scheduled_rotation'
          }
        });
      }

      // Deactivate old key
      oldKeyInfo.isActive = false;
      oldKeyInfo.deactivated = Date.now();
      oldKeyInfo.version++;

      if (!keepOld) {
        // Securely wipe old key
        await this.secureWipeKey(oldKeyInfo.id);
      } else {
        // Keep old key for decryption but mark as inactive
        this.keyStore.set(keyId, oldKeyInfo);
        await this.updateKeyInRedis(keyId, oldKeyInfo);
      }

      console.log(`Key rotated: ${keyId} -> ${newKeyId}`);
      return newKeyId;
    } catch (error) {
      throw new Error(`Key rotation failed: ${error.message}`);
    }
  }

  // Securely wipe a key
  async secureWipeKey(keyId) {
    try {
      const keyInfo = this.keyStore.get(keyId);
      if (!keyInfo) return;

      // Securely wipe the key data
      keyInfo.key = await this.encryptionService.secureWipe(keyInfo.key);
      keyInfo.encryptedKey = await this.encryptionService.secureWipe(JSON.stringify(keyInfo.encryptedKey));
      keyInfo.encryptedSalt = await this.encryptionService.secureWipe(JSON.stringify(keyInfo.encryptedSalt));

      // Remove from storage
      this.keyStore.delete(keyId);
      await this.removeKeyFromRedis(keyId);
      await this.saveKeyStore();

      console.log(`Key securely wiped: ${keyId}`);
    } catch (error) {
      console.error(`Failed to wipe key ${keyId}:`, error);
    }
  }

  // Store key in Redis
  async storeKeyInRedis(keyId, keyInfo) {
    try {
      const keyData = {
        ...keyInfo,
        key: undefined, // Remove plaintext key
        encryptedKey: undefined,
        encryptedSalt: undefined
      };
      
      await this.redisClient.hSet(`keys:${keyId}`, keyData);
      await this.redisClient.expire(`keys:${keyId}`, 86400); // 24 hours
      
      // Store encrypted key data separately
      const encryptedData = await this.encryptionService.encrypt(JSON.stringify({
        key: keyInfo.key.toString('hex'),
        salt: keyInfo.salt.toString('hex'),
        encryptedKey: keyInfo.encryptedKey,
        encryptedSalt: keyInfo.encryptedSalt
      }), this.masterKey);
      
      await this.redisClient.hSet(`keys:encrypted:${keyId}`, encryptedData);
    } catch (error) {
      console.error('Error storing key in Redis:', error);
    }
  }

  // Get key from Redis
  async getKeyFromRedis(keyId) {
    try {
      const keyData = await this.redisClient.hGetAll(`keys:${keyId}`);
      if (!keyData || Object.keys(keyData).length === 0) return null;

      const encryptedData = await this.redisClient.hGetAll(`keys:encrypted:${keyId}`);
      if (!encryptedData || Object.keys(encryptedData).length === 0) return null;

      // Decrypt the key data
      const decryptedKeyData = await this.encryptionService.decrypt(encryptedData, this.masterKey);
      const parsedKeyData = JSON.parse(decryptedKeyData);

      return {
        ...keyData,
        key: Buffer.from(parsedKeyData.key, 'hex'),
        salt: Buffer.from(parsedKeyData.salt, 'hex'),
        encryptedKey: parsedKeyData.encryptedKey,
        encryptedSalt: parsedKeyData.encryptedSalt
      };
    } catch (error) {
      console.error('Error retrieving key from Redis:', error);
      return null;
    }
  }

  // Update key in Redis
  async updateKeyInRedis(keyId, keyInfo) {
    try {
      await this.storeKeyInRedis(keyId, keyInfo);
    } catch (error) {
      console.error('Error updating key in Redis:', error);
    }
  }

  // Remove key from Redis
  async removeKeyFromRedis(keyId) {
    try {
      await this.redisClient.del(`keys:${keyId}`);
      await this.redisClient.del(`keys:encrypted:${keyId}`);
    } catch (error) {
      console.error('Error removing key from Redis:', error);
    }
  }

  // Load keystore from persistent storage
  async loadKeyStore() {
    try {
      const keystorePath = this.config.keyStorePath;
      
      try {
        const keystoreData = await fs.readFile(keystorePath, 'utf8');
        const keystore = JSON.parse(keystoreData);
        
        for (const [keyId, keyInfo] of Object.entries(keystore)) {
          // Skip plaintext keys in stored data
          this.keyStore.set(keyId, {
            ...keyInfo,
            key: undefined // Will be loaded from Redis when needed
          });
        }
        
        console.log(`Loaded ${this.keyStore.size} keys from keystore`);
      } catch (error) {
        console.log('No existing keystore found, starting with empty store');
      }
    } catch (error) {
      console.error('Error loading keystore:', error);
    }
  }

  // Save keystore to persistent storage
  async saveKeyStore() {
    try {
      const keystoreDir = path.dirname(this.config.keyStorePath);
      await fs.mkdir(keystoreDir, { recursive: true });
      
      const keystoreData = {};
      for (const [keyId, keyInfo] of this.keyStore.entries()) {
        keystoreData[keyId] = {
          ...keyInfo,
          key: undefined, // Don't store plaintext keys
          encryptedKey: keyInfo.encryptedKey,
          encryptedSalt: keyInfo.encryptedSalt
        };
      }
      
      await fs.writeFile(this.config.keyStorePath, JSON.stringify(keystoreData, null, 2));
      
      // Set restrictive file permissions
      await fs.chmod(this.config.keyStorePath, 0o600);
    } catch (error) {
      console.error('Error saving keystore:', error);
    }
  }

  // Start key rotation scheduler
  startKeyRotationScheduler() {
    setInterval(() => {
      this.checkKeyRotationSchedule();
    }, 24 * 60 * 60 * 1000); // Check daily
    
    // Also check on startup
    setTimeout(() => {
      this.checkKeyRotationSchedule();
    }, 60000); // Check after 1 minute
  }

  // Check and rotate keys that are due for rotation
  async checkKeyRotationSchedule() {
    const now = Date.now();
    const rotationDue = [];

    for (const [keyId, keyInfo] of this.keyStore.entries()) {
      if (keyInfo.isActive && keyInfo.lastUsed) {
        const age = now - keyInfo.created;
        if (age >= this.config.keyRotationInterval) {
          rotationDue.push(keyId);
        }
      }
    }

    for (const keyId of rotationDue) {
      try {
        console.log(`Automatically rotating key due to age: ${keyId}`);
        await this.rotateKey(keyId);
      } catch (error) {
        console.error(`Failed to automatically rotate key ${keyId}:`, error);
      }
    }
  }

  // List all keys
  listKeys(options = {}) {
    const {
      activeOnly = true,
      type = null,
      limit = null
    } = options;

    let keys = Array.from(this.keyStore.entries());

    // Filter by active status
    if (activeOnly) {
      keys = keys.filter(([_, keyInfo]) => keyInfo.isActive);
    }

    // Filter by type
    if (type) {
      keys = keys.filter(([_, keyInfo]) => keyInfo.type === type);
    }

    // Apply limit
    if (limit) {
      keys = keys.slice(0, limit);
    }

    // Return key information without sensitive data
    return keys.map(([keyId, keyInfo]) => ({
      id: keyId,
      type: keyInfo.type,
      algorithm: keyInfo.algorithm,
      created: keyInfo.created,
      lastUsed: keyInfo.lastUsed,
      usageCount: keyInfo.usageCount,
      version: keyInfo.version,
      metadata: keyInfo.metadata
    }));
  }

  // Backup keys
  async backupKeys(backupPath = null) {
    const path = backupPath || this.config.keyBackupPath;
    const timestamp = new Date().toISOString().replace(/:/g, '-');
    const backupFile = path + `/keys_backup_${timestamp}.enc`;

    try {
      await fs.mkdir(path, { recursive: true });
      
      // Create backup metadata
      const backupData = {
        version: this.config.keyVersion,
        timestamp: Date.now(),
        keys: this.listKeys({ activeOnly: false })
      };

      // Encrypt backup data
      const encryptedBackup = await this.encryptionService.encrypt(JSON.stringify(backupData), this.masterKey);
      await fs.writeFile(backupFile, JSON.stringify(encryptedBackup, null, 2));
      
      console.log(`Keys backed up to: ${backupFile}`);
      return backupFile;
    } catch (error) {
      throw new Error(`Key backup failed: ${error.message}`);
    }
  }

  // Restore keys from backup
  async restoreKeys(backupFile) {
    try {
      const backupData = JSON.parse(await fs.readFile(backupFile, 'utf8'));
      const decryptedBackup = await this.encryptionService.decrypt(backupData, this.masterKey);
      const backup = JSON.parse(decryptedBackup);

      console.log(`Restoring ${backup.keys.length} keys from backup...`);
      
      // Note: In a real implementation, you would need to restore the actual key data
      // This is a simplified version that restores metadata
      
      return backup.keys;
    } catch (error) {
      throw new Error(`Key restoration failed: ${error.message}`);
    }
  }

  // Validate key integrity
  async validateKey(keyId) {
    try {
      const keyInfo = await this.getKey(keyId);
      return {
        valid: true,
        keyId,
        type: keyInfo.type,
        algorithm: keyInfo.algorithm,
        created: keyInfo.created,
        lastUsed: keyInfo.lastUsed,
        usageCount: keyInfo.usageCount
      };
    } catch (error) {
      return {
        valid: false,
        keyId,
        error: error.message
      };
    }
  }

  // Health check for key management system
  async healthCheck() {
    try {
      const masterKeyValid = this.masterKey && this.masterKey.length > 0;
      const redisConnected = this.redisClient.isOpen;
      const keyCount = this.keyStore.size;
      
      return {
        healthy: masterKeyValid && redisConnected,
        masterKeyValid,
        redisConnected,
        keyCount,
        lastRotationCheck: new Date().toISOString()
      };
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }

  // Generate master key rotation
  async rotateMasterKey() {
    try {
      const oldMasterKey = this.masterKey;
      const newMasterKey = this.encryptionService.generateKey(32);
      
      // Re-encrypt all keys with new master key
      const keyIds = Array.from(this.keyStore.keys());
      
      for (const keyId of keyIds) {
        try {
          const keyInfo = this.keyStore.get(keyId);
          
          // Decrypt with old master key
          const keyData = await this.encryptionService.decrypt(keyInfo.encryptedKey, oldMasterKey);
          const saltData = await this.encryptionService.decrypt(keyInfo.encryptedSalt, oldMasterKey);
          
          // Re-encrypt with new master key
          keyInfo.encryptedKey = await this.encryptionService.encrypt(keyData, newMasterKey);
          keyInfo.encryptedSalt = await this.encryptionService.encrypt(saltData, newMasterKey);
          
          this.keyStore.set(keyId, keyInfo);
        } catch (error) {
          console.error(`Failed to re-encrypt key ${keyId} during master key rotation:`, error);
        }
      }
      
      // Update master key
      this.masterKey = newMasterKey;
      await this.saveMasterKey();
      await this.saveKeyStore();
      
      console.log('Master key rotated successfully');
    } catch (error) {
      throw new Error(`Master key rotation failed: ${error.message}`);
    }
  }
}

module.exports = {
  KeyManagementSystem
};