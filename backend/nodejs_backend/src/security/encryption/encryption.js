/**
 * Data Encryption Service
 * Comprehensive encryption for data at rest and in transit
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const { createCipheriv, createDecipheriv, randomBytes, createHash } = crypto;

class EncryptionService {
  constructor() {
    this.algorithms = {
      aes256gcm: 'aes-256-gcm',
      aes256cbc: 'aes-256-cbc',
      aes128gcm: 'aes-128-gcm',
      aes128cbc: 'aes-128-cbc'
    };
    
    this.keyDerivation = {
      pbkdf2: 'pbkdf2',
      scrypt: 'scrypt'
    };
    
    this.config = {
      algorithm: this.algorithms.aes256gcm,
      keyDerivation: this.keyDerivation.pbkdf2,
      iterations: 100000,
      saltLength: 32,
      ivLength: 16,
      tagLength: 16,
      keyLength: 32
    };
  }

  async initialize() {
    console.log('✅ Encryption Service initialized');
  }

  // Generate secure random key
  generateKey(length = 32) {
    return randomBytes(length);
  }

  // Generate salt for key derivation
  generateSalt(length = 32) {
    return randomBytes(length);
  }

  // Derive key from password
  async deriveKey(password, salt, iterations = 100000) {
    const keyDerivationMethod = this.config.keyDerivation;
    
    return new Promise((resolve, reject) => {
      crypto.pbkdf2(password, salt, iterations, this.config.keyLength, 'sha512', (err, derivedKey) => {
        if (err) {
          reject(err);
        } else {
          resolve(derivedKey);
        }
      });
    });
  }

  // Encrypt data using AES-256-GCM
  async encrypt(plaintext, key, options = {}) {
    const {
      algorithm = this.config.algorithm,
      iv = randomBytes(this.config.ivLength),
      authTagLength = this.config.tagLength
    } = options;

    try {
      const cipher = createCipheriv(algorithm, key, iv);
      cipher.setAAD(Buffer.from('tutoring-platform', 'utf8')); // Additional authenticated data
      
      let encrypted = cipher.update(plaintext, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      const authTag = cipher.getAuthTag();
      
      return {
        encrypted,
        iv: iv.toString('hex'),
        authTag: authTag.toString('hex'),
        algorithm,
        timestamp: Date.now()
      };
    } catch (error) {
      throw new Error(`Encryption failed: ${error.message}`);
    }
  }

  // Decrypt data using AES-256-GCM
  async decrypt(encryptedData, key, options = {}) {
    const {
      algorithm = encryptedData.algorithm || this.config.algorithm,
      iv = Buffer.from(encryptedData.iv, 'hex'),
      authTag = Buffer.from(encryptedData.authTag, 'hex')
    } = options;

    try {
      const decipher = createDecipheriv(algorithm, key, iv);
      decipher.setAuthTag(authTag);
      decipher.setAAD(Buffer.from('tutoring-platform', 'utf8'));
      
      let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return decrypted;
    } catch (error) {
      throw new Error(`Decryption failed: ${error.message}`);
    }
  }

  // Encrypt with password-based key derivation
  async encryptWithPassword(plaintext, password, options = {}) {
    const {
      iterations = this.config.iterations,
      salt = this.generateSalt()
    } = options;

    try {
      const key = await this.deriveKey(password, salt, iterations);
      return await this.encrypt(plaintext, key, { iv: randomBytes(this.config.ivLength) });
    } catch (error) {
      throw new Error(`Password-based encryption failed: ${error.message}`);
    }
  }

  // Decrypt with password-based key derivation
  async decryptWithPassword(encryptedData, password, options = {}) {
    const { iterations = this.config.iterations } = options;

    try {
      const salt = Buffer.from(encryptedData.salt, 'hex') || this.generateSalt();
      const key = await this.deriveKey(password, salt, iterations);
      return await this.decrypt(encryptedData, key);
    } catch (error) {
      throw new Error(`Password-based decryption failed: ${error.message}`);
    }
  }

  // Hash data using SHA-256
  hash(data, algorithm = 'sha256') {
    return createHash(algorithm).update(data).digest('hex');
  }

  // Generate HMAC for data integrity
  generateHMAC(data, key, algorithm = 'sha256') {
    return crypto.createHmac(algorithm, key).update(data).digest('hex');
  }

  // Verify HMAC
  verifyHMAC(data, hmac, key, algorithm = 'sha256') {
    const expectedHmac = this.generateHMAC(data, key, algorithm);
    return crypto.timingSafeEqual(Buffer.from(hmac, 'hex'), Buffer.from(expectedHmac, 'hex'));
  }

  // Encrypt file content
  async encryptFile(filePath, key, options = {}) {
    try {
      const fileContent = await fs.readFile(filePath);
      const { encrypted, iv, authTag } = await this.encrypt(fileContent.toString('base64'), key, options);
      
      return {
        encrypted,
        iv,
        authTag,
        originalSize: fileContent.length,
        algorithm: this.config.algorithm
      };
    } catch (error) {
      throw new Error(`File encryption failed: ${error.message}`);
    }
  }

  // Decrypt file content
  async decryptFile(encryptedData, key, outputPath, options = {}) {
    try {
      const decrypted = await this.decrypt(encryptedData, key, options);
      const fileContent = Buffer.from(decrypted, 'base64');
      
      await fs.writeFile(outputPath, fileContent);
      
      return {
        decrypted: true,
        size: fileContent.length
      };
    } catch (error) {
      throw new Error(`File decryption failed: ${error.message}`);
    }
  }

  // Encrypt sensitive user data
  async encryptUserData(userData, key) {
    const sensitiveFields = ['password', 'email', 'phone', 'dateOfBirth', 'address', 'ssn'];
    const encryptedData = { ...userData };
    
    for (const field of sensitiveFields) {
      if (userData[field]) {
        const encrypted = await this.encrypt(userData[field], key);
        encryptedData[field] = encrypted;
        encryptedData[`${field}_encrypted`] = true;
      }
    }
    
    return encryptedData;
  }

  // Decrypt sensitive user data
  async decryptUserData(userData, key) {
    const encryptedFields = Object.keys(userData).filter(key => key.endsWith('_encrypted'));
    
    for (const encryptedField of encryptedFields) {
      const originalField = encryptedField.replace('_encrypted', '');
      const encryptedData = userData[originalField];
      
      if (encryptedData && typeof encryptedData === 'object' && encryptedData.encrypted) {
        const decrypted = await this.decrypt(encryptedData, key);
        userData[originalField] = decrypted;
      }
    }
    
    // Remove encryption flags
    encryptedFields.forEach(field => {
      delete userData[field];
    });
    
    return userData;
  }

  // Encrypt database connection string
  async encryptConnectionString(connectionString, key) {
    const encrypted = await this.encrypt(connectionString, key);
    return encrypted;
  }

  // Decrypt database connection string
  async decryptConnectionString(encryptedConnectionString, key) {
    const decrypted = await this.decrypt(encryptedConnectionString, key);
    return decrypted;
  }

  // Generate encryption key from environment variables
  static generateKeyFromEnv() {
    const envKey = process.env.ENCRYPTION_KEY;
    if (!envKey) {
      throw new Error('ENCRYPTION_KEY environment variable is not set');
    }
    
    // Derive key from environment variable
    const salt = process.env.ENCRYPTION_SALT || 'tutoring-platform-salt';
    const iterations = parseInt(process.env.KEY_ITERATIONS) || 100000;
    
    return new Promise((resolve, reject) => {
      crypto.pbkdf2(envKey, salt, iterations, 32, 'sha512', (err, derivedKey) => {
        if (err) {
          reject(err);
        } else {
          resolve(derivedKey);
        }
      });
    });
  }

  // Secure data wipe
  async secureWipe(data, iterations = 3) {
    if (typeof data === 'string') {
      let wiped = '';
      for (let i = 0; i < iterations; i++) {
        wiped += crypto.randomBytes(data.length).toString('hex').substring(0, data.length);
      }
      return wiped.substring(0, data.length);
    }
    
    if (Buffer.isBuffer(data)) {
      for (let i = 0; i < iterations; i++) {
        data.fill(crypto.randomInt(0, 256));
      }
      return data;
    }
    
    return data;
  }

  // Generate cryptographically secure random tokens
  generateSecureToken(length = 32) {
    return randomBytes(length).toString('hex');
  }

  // Generate secure password hash
  async hashPassword(password, options = {}) {
    const {
      iterations = this.config.iterations,
      salt = this.generateSalt(),
      keyLength = 32
    } = options;

    try {
      const hash = await this.deriveKey(password, salt, iterations);
      return {
        hash: hash.toString('hex'),
        salt: salt.toString('hex'),
        iterations,
        keyLength
      };
    } catch (error) {
      throw new Error(`Password hashing failed: ${error.message}`);
    }
  }

  // Verify password against hash
  async verifyPassword(password, passwordHash) {
    try {
      const { hash, salt, iterations, keyLength } = passwordHash;
      const key = await this.deriveKey(password, Buffer.from(salt, 'hex'), iterations);
      return crypto.timingSafeEqual(
        key,
        Buffer.from(hash, 'hex').subarray(0, keyLength)
      );
    } catch (error) {
      return false;
    }
  }

  // Encrypt API response data
  encryptResponseData(data, key, requestId) {
    const timestamp = Date.now();
    const payload = JSON.stringify({
      data,
      timestamp,
      requestId
    });
    
    return this.encrypt(payload, key);
  }

  // Decrypt API request data
  decryptRequestData(encryptedData, key) {
    const decrypted = this.decrypt(encryptedData, key);
    return JSON.parse(decrypted);
  }

  // Rotate encryption keys
  async rotateKeys(oldKey, newKey, data) {
    const decrypted = await this.decrypt(data, oldKey);
    return await this.encrypt(decrypted, newKey);
  }

  // Validate encryption integrity
  async validateIntegrity(encryptedData, key) {
    try {
      await this.decrypt(encryptedData, key);
      return true;
    } catch {
      return false;
    }
  }

  // Generate encryption metadata
  generateMetadata() {
    return {
      algorithm: this.config.algorithm,
      keyDerivation: this.config.keyDerivation,
      iterations: this.config.iterations,
      version: '1.0.0',
      created: Date.now()
    };
  }
}

module.exports = {
  EncryptionService
};