/**
 * Certificate Pinning Implementation
 * Advanced certificate pinning with backup pins and validation
 */

const crypto = require('crypto');
const https = require('https');
const tls = require('tls');
const { URL } = require('url');
const fs = require('fs').promises;
const Redis = require('redis');

class CertificatePinning {
  constructor() {
    this.redisClient = null;
    this.config = {
      // Certificate pinning configuration
      pins: new Map(),
      backupPins: new Map(),
      
      // Validation settings
      validateCertificate: true,
      validateHostname: true,
      allowSelfSigned: false,
      
      // Security settings
      strictPinning: true,
      includeSubdomains: false,
      
      // Monitoring settings
      logValidationResults: true,
      alertOnMismatch: true,
      
      // Performance settings
      cachePins: true,
      pinCacheTTL: 3600, // 1 hour
      
      // Backup pin configuration
      enableBackupPins: true,
      maxBackupPins: 3,
      
      // Compliance settings
      enforceForAPI: true,
      enforceForWebSocket: true,
      enforceForWebRTC: true
    };
    
    this.validationHistory = new Map();
    this.pinCache = new Map();
  }

  async initialize() {
    try {
      // Initialize Redis for caching
      this.redisClient = Redis.createClient({
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        password: process.env.REDIS_PASSWORD
      });
      
      await this.redisClient.connect();
      
      // Load certificate pins from configuration
      await this.loadCertificatePins();
      
      console.log('✅ Certificate Pinning initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Certificate Pinning: ${error.message}`);
    }
  }

  // Load certificate pins from various sources
  async loadCertificatePins() {
    try {
      // Load from environment variables
      await this.loadPinsFromEnvironment();
      
      // Load from configuration file
      await this.loadPinsFromFile();
      
      // Load from secure storage
      await this.loadPinsFromSecureStorage();
      
      console.log(`Loaded ${this.config.pins.size} primary pins and ${this.config.backupPins.size} backup pins`);
    } catch (error) {
      console.error('Error loading certificate pins:', error);
    }
  }

  // Load pins from environment variables
  async loadPinsFromEnvironment() {
    try {
      const primaryPins = process.env.CERTIFICATE_PINS;
      const backupPins = process.env.CERTIFICATE_BACKUP_PINS;
      const domainPins = process.env.DOMAIN_CERTIFICATE_PINS;
      
      if (primaryPins) {
        const pins = primaryPins.split(',').map(pin => pin.trim());
        pins.forEach((pin, index) => {
          this.addPin(`env_primary_${index}`, pin, 'primary');
        });
      }
      
      if (backupPins) {
        const pins = backupPins.split(',').map(pin => pin.trim());
        pins.forEach((pin, index) => {
          this.addPin(`env_backup_${index}`, pin, 'backup');
        });
      }
      
      if (domainPins) {
        const domainConfigs = JSON.parse(domainPins);
        for (const [domain, pins] of Object.entries(domainConfigs)) {
          this.addDomainPin(domain, pins);
        }
      }
    } catch (error) {
      console.error('Error loading pins from environment:', error);
    }
  }

  // Load pins from configuration file
  async loadPinsFromFile() {
    try {
      const configPath = process.env.CERT_PIN_CONFIG_PATH || './security/cert-pins.json';
      
      try {
        const configData = await fs.readFile(configPath, 'utf8');
        const config = JSON.parse(configData);
        
        // Load primary pins
        if (config.primaryPins) {
          config.primaryPins.forEach(pin => {
            this.addPin(pin.id, pin.hash, 'primary', pin.algorithm || 'sha256');
          });
        }
        
        // Load backup pins
        if (config.backupPins) {
          config.backupPins.forEach(pin => {
            this.addPin(pin.id, pin.hash, 'backup', pin.algorithm || 'sha256');
          });
        }
        
        // Load domain-specific pins
        if (config.domainPins) {
          for (const [domain, pins] of Object.entries(config.domainPins)) {
            this.addDomainPin(domain, pins);
          }
        }
      } catch (error) {
        if (error.code !== 'ENOENT') {
          throw error;
        }
        console.log('Certificate pin configuration file not found, using defaults');
      }
    } catch (error) {
      console.error('Error loading pins from file:', error);
    }
  }

  // Load pins from secure storage
  async loadPinsFromSecureStorage() {
    try {
      // In a real implementation, load from secure storage like AWS Secrets Manager,
      // Azure Key Vault, HashiCorp Vault, etc.
      const securePins = process.env.SECURE_CERTIFICATE_PINS;
      
      if (securePins) {
        const decryptedPins = await this.decryptSecurePins(securePins);
        const pinConfigs = JSON.parse(decryptedPins);
        
        pinConfigs.forEach(pin => {
          this.addPin(pin.id, pin.hash, pin.type || 'primary', pin.algorithm || 'sha256');
        });
      }
    } catch (error) {
      console.error('Error loading pins from secure storage:', error);
    }
  }

  // Decrypt secure pins (placeholder implementation)
  async decryptSecurePins(encryptedData) {
    // In a real implementation, decrypt using proper encryption
    // For now, return the data as-is
    return encryptedData;
  }

  // Add certificate pin
  addPin(id, hash, type = 'primary', algorithm = 'sha256') {
    if (!this.validatePinHash(hash, algorithm)) {
      throw new Error(`Invalid certificate pin hash: ${hash}`);
    }
    
    const pin = {
      id,
      hash,
      type,
      algorithm,
      created: Date.now(),
      active: true
    };
    
    if (type === 'primary') {
      this.config.pins.set(id, pin);
    } else {
      this.config.backupPins.set(id, pin);
    }
    
    console.log(`Added ${type} certificate pin: ${id}`);
  }

  // Add domain-specific certificate pin
  addDomainPin(domain, pins) {
    const domainConfig = {
      domain,
      primaryPins: [],
      backupPins: [],
      includeSubdomains: false,
      created: Date.now()
    };
    
    if (Array.isArray(pins.primary)) {
      pins.primary.forEach(pin => {
        domainConfig.primaryPins.push(pin);
        this.addPin(`${domain}_primary_${pin}`, pin, 'primary');
      });
    }
    
    if (Array.isArray(pins.backup)) {
      pins.backup.forEach(pin => {
        domainConfig.backupPins.push(pin);
        this.addPin(`${domain}_backup_${pin}`, pin, 'backup');
      });
    }
    
    domainConfig.includeSubdomains = pins.includeSubdomains || false;
    
    // Store domain configuration
    this.domainPins.set(domain, domainConfig);
  }

  // Validate certificate pin hash
  validatePinHash(hash, algorithm = 'sha256') {
    // Check hash format
    if (typeof hash !== 'string' || hash.length === 0) {
      return false;
    }
    
    // SHA-256 hashes are 64 characters (32 bytes in hex)
    // SHA-1 hashes are 40 characters (20 bytes in hex)
    const validAlgorithms = ['sha256', 'sha1'];
    if (!validAlgorithms.includes(algorithm)) {
      return false;
    }
    
    const expectedLength = algorithm === 'sha256' ? 64 : 40;
    if (hash.length !== expectedLength) {
      return false;
    }
    
    // Check if hash contains only hex characters
    return /^[a-fA-F0-9]+$/.test(hash);
  }

  // Generate certificate pin from certificate
  generateCertificatePin(certificate, algorithm = 'sha256') {
    try {
      if (!certificate || !certificate.publicKey) {
        throw new Error('Invalid certificate object');
      }
      
      // Use public key for pinning (more secure than certificate)
      const publicKey = certificate.publicKey;
      
      let hash;
      if (algorithm === 'sha1') {
        hash = crypto.createHash('sha1').update(publicKey).digest('hex');
      } else {
        hash = crypto.createHash('sha256').update(publicKey).digest('hex');
      }
      
      return hash.toLowerCase();
    } catch (error) {
      console.error('Error generating certificate pin:', error);
      throw error;
    }
  }

  // Validate certificate against pins
  async validateCertificate(certificate, options = {}) {
    const {
      domain = null,
      algorithm = 'sha256',
      includeBackupPins = this.config.enableBackupPins
    } = options;
    
    const validation = {
      valid: false,
      matchedPin: null,
      matchedType: null,
      algorithm,
      domain,
      certificateFingerprint: null,
      errors: [],
      warnings: []
    };
    
    try {
      if (!certificate) {
        validation.errors.push('No certificate provided');
        return validation;
      }
      
      // Generate pin from certificate
      const certificatePin = this.generateCertificatePin(certificate, algorithm);
      validation.certificateFingerprint = certificatePin;
      
      // Get applicable pins
      const applicablePins = this.getApplicablePins(domain);
      const allPins = [...applicablePins.primary, ...applicablePins.backup];
      
      // Check against primary pins
      for (const pin of applicablePins.primary) {
        if (this.comparePins(certificatePin, pin.hash, algorithm)) {
          validation.valid = true;
          validation.matchedPin = pin.id;
          validation.matchedType = 'primary';
          break;
        }
      }
      
      // Check against backup pins if not found in primary
      if (!validation.valid && includeBackupPins) {
        for (const pin of applicablePins.backup) {
          if (this.comparePins(certificatePin, pin.hash, algorithm)) {
            validation.valid = true;
            validation.matchedPin = pin.id;
            validation.matchedType = 'backup';
            validation.warnings.push('Matched backup pin instead of primary');
            break;
          }
        }
      }
      
      // Add warnings if no pins matched but certificate is valid
      if (!validation.valid && this.config.allowSelfSigned) {
        validation.warnings.push('Certificate not pinned but self-signed certificates allowed');
      }
      
      // Log validation result
      if (this.config.logValidationResults) {
        await this.logValidationResult(validation);
      }
      
      return validation;
    } catch (error) {
      validation.errors.push(`Validation error: ${error.message}`);
      console.error('Certificate validation error:', error);
      return validation;
    }
  }

  // Compare certificate pins
  comparePins(certPin, storedPin, algorithm) {
    // Normalize pins to lowercase for comparison
    const normalizedCertPin = certPin.toLowerCase();
    const normalizedStoredPin = storedPin.toLowerCase();
    
    return normalizedCertPin === normalizedStoredPin;
  }

  // Get applicable pins for domain
  getApplicablePins(domain = null) {
    const result = {
      primary: Array.from(this.config.pins.values()).filter(pin => pin.active),
      backup: Array.from(this.config.backupPins.values()).filter(pin => pin.active)
    };
    
    if (domain && this.domainPins.has(domain)) {
      const domainConfig = this.domainPins.get(domain);
      
      // Filter pins specific to this domain
      result.primary = result.primary.filter(pin => 
        pin.id.startsWith(`${domain}_primary_`)
      );
      
      result.backup = result.backup.filter(pin => 
        pin.id.startsWith(`${domain}_backup_`)
      );
    }
    
    return result;
  }

  // Pinning middleware for HTTPS requests
  middleware(options = {}) {
    return async (req, res, next) => {
      try {
        if (!req.secure && !req.headers['x-forwarded-proto']?.includes('https')) {
          return next(); // Skip non-HTTPS requests
        }
        
        const socket = req.socket;
        if (!socket || !socket.getPeerCertificate) {
          return next(); // Skip if no socket or certificate available
        }
        
        const certificate = socket.getPeerCertificate(true);
        if (!certificate || Object.keys(certificate).length === 0) {
          return next(); // Skip if no certificate
        }
        
        // Extract domain from request
        const domain = this.extractDomainFromRequest(req);
        
        // Validate certificate
        const validation = await this.validateCertificate(certificate, {
          ...options,
          domain
        });
        
        // Store validation result in request
        req.certificateValidation = validation;
        
        // Handle validation failure
        if (!validation.valid && this.config.strictPinning) {
          console.warn(`Certificate pinning violation from ${req.ip} for ${domain || 'unknown domain'}`);
          
          if (this.config.alertOnMismatch) {
            await this.alertPinningMismatch(req, validation);
          }
          
          return res.status(400).json({
            error: 'Certificate validation failed',
            code: 'CERT_PINNING_FAILURE'
          });
        }
        
        next();
      } catch (error) {
        console.error('Certificate pinning middleware error:', error);
        next(); // Continue on error to avoid blocking legitimate requests
      }
    };
  }

  // Extract domain from request
  extractDomainFromRequest(req) {
    // Try multiple sources for domain
    const host = req.headers.host;
    const origin = req.headers.origin;
    const referer = req.headers.referer;
    
    if (host) {
      return host.split(':')[0]; // Remove port if present
    }
    
    if (origin) {
      try {
        const url = new URL(origin);
        return url.hostname;
      } catch {
        // Invalid URL
      }
    }
    
    if (referer) {
      try {
        const url = new URL(referer);
        return url.hostname;
      } catch {
        // Invalid URL
      }
    }
    
    return null;
  }

  // Validate TLS connection
  async validateTLSConnection(hostname, port = 443, options = {}) {
    return new Promise((resolve) => {
      const socket = tls.connect({
        host: hostname,
        port: port,
        servername: hostname,
        rejectUnauthorized: false // Don't reject self-signed certificates for pinning
      });
      
      const timeout = setTimeout(() => {
        socket.destroy();
        resolve({
          valid: false,
          error: 'Connection timeout',
          hostname,
          port
        });
      }, 10000); // 10 second timeout
      
      socket.on('secureConnect', async () => {
        clearTimeout(timeout);
        
        try {
          const certificate = socket.getPeerCertificate(true);
          const validation = await this.validateCertificate(certificate, {
            domain: hostname,
            ...options
          });
          
          socket.end();
          
          resolve({
            valid: validation.valid,
            hostname,
            port,
            certificate: {
              subject: certificate.subject,
              issuer: certificate.issuer,
              valid_from: certificate.valid_from,
              valid_to: certificate.valid_to,
              fingerprint: validation.certificateFingerprint
            },
            validation
          });
        } catch (error) {
          socket.end();
          resolve({
            valid: false,
            hostname,
            port,
            error: error.message
          });
        }
      });
      
      socket.on('error', (error) => {
        clearTimeout(timeout);
        resolve({
          valid: false,
          hostname,
          port,
          error: error.message
        });
      });
    });
  }

  // Batch validate multiple domains
  async batchValidateCertificates(hostnames, options = {}) {
    const results = [];
    
    for (const hostname of hostnames) {
      try {
        const result = await this.validateTLSConnection(hostname, options.port || 443, options);
        results.push({
          hostname,
          ...result
        });
        
        // Small delay between requests to avoid overwhelming servers
        await new Promise(resolve => setTimeout(resolve, 100));
      } catch (error) {
        results.push({
          hostname,
          valid: false,
          error: error.message
        });
      }
    }
    
    return results;
  }

  // Log validation result
  async logValidationResult(validation) {
    try {
      const logEntry = {
        timestamp: Date.now(),
        valid: validation.valid,
        matchedPin: validation.matchedPin,
        matchedType: validation.matchedType,
        domain: validation.domain,
        certificateFingerprint: validation.certificateFingerprint,
        errors: validation.errors,
        warnings: validation.warnings
      };
      
      // Store in Redis for recent history
      const key = `cert_pin_validation:${Date.now()}`;
      await this.redisClient.setEx(key, 86400, JSON.stringify(logEntry)); // 24 hours
      
      // Store in memory for quick access
      this.validationHistory.set(logEntry.timestamp, logEntry);
      
      // Clean up old history
      if (this.validationHistory.size > 1000) {
        const timestamps = Array.from(this.validationHistory.keys()).sort();
        const toDelete = timestamps.slice(0, timestamps.length - 1000);
        toDelete.forEach(ts => this.validationHistory.delete(ts));
      }
    } catch (error) {
      console.error('Error logging validation result:', error);
    }
  }

  // Alert on pinning mismatch
  async alertPinningMismatch(req, validation) {
    try {
      const alert = {
        timestamp: Date.now(),
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        domain: validation.domain,
        certificateFingerprint: validation.certificateFingerprint,
        severity: 'high',
        type: 'certificate_pinning_violation'
      };
      
      // In a real implementation, send alert to monitoring system
      console.warn('🚨 Certificate pinning violation:', alert);
      
      // Store alert in Redis
      const key = `cert_pin_alert:${Date.now()}`;
      await this.redisClient.setEx(key, 604800, JSON.stringify(alert)); // 7 days
    } catch (error) {
      console.error('Error creating pinning mismatch alert:', error);
    }
  }

  // Get validation history
  getValidationHistory(limit = 100) {
    const timestamps = Array.from(this.validationHistory.keys()).sort().reverse();
    const recent = timestamps.slice(0, limit);
    
    return recent.map(ts => this.validationHistory.get(ts));
  }

  // Update certificate pins
  async updateCertificatePins(newPins) {
    try {
      // Deactivate old pins
      for (const pin of this.config.pins.values()) {
        pin.active = false;
      }
      
      // Add new pins
      newPins.forEach(pin => {
        this.addPin(pin.id, pin.hash, pin.type || 'primary', pin.algorithm || 'sha256');
      });
      
      console.log(`Updated certificate pins: ${newPins.length} pins added`);
      return true;
    } catch (error) {
      console.error('Error updating certificate pins:', error);
      return false;
    }
  }

  // Rotate certificate pins
  async rotateCertificatePins() {
    try {
      const newPins = {
        primary: [],
        backup: []
      };
      
      // Generate new pins (in a real implementation, obtain from CA)
      for (let i = 0; i < 2; i++) {
        newPins.primary.push({
          id: `rotated_primary_${Date.now()}_${i}`,
          hash: crypto.randomBytes(32).toString('hex'),
          algorithm: 'sha256'
        });
      }
      
      for (let i = 0; i < 2; i++) {
        newPins.backup.push({
          id: `rotated_backup_${Date.now()}_${i}`,
          hash: crypto.randomBytes(32).toString('hex'),
          algorithm: 'sha256'
        });
      }
      
      await this.updateCertificatePins(newPins.primary.concat(newPins.backup));
      console.log('Certificate pins rotated successfully');
      return true;
    } catch (error) {
      console.error('Error rotating certificate pins:', error);
      return false;
    }
  }

  // Health check for certificate pinning
  async healthCheck() {
    try {
      const status = {
        healthy: true,
        primaryPins: this.config.pins.size,
        backupPins: this.config.backupPins.size,
        domainPins: this.domainPins.size,
        validationHistory: this.validationHistory.size,
        redisConnected: this.redisClient.isOpen
      };
      
      // Check if we have at least one primary pin
      if (this.config.pins.size === 0) {
        status.healthy = false;
        status.error = 'No primary certificate pins configured';
      }
      
      return status;
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }

  // Export pins configuration (sanitized)
  exportPinsConfiguration() {
    return {
      primaryPinsCount: this.config.pins.size,
      backupPinsCount: this.config.backupPins.size,
      domainPinsCount: this.domainPins.size,
      configuration: {
        strictPinning: this.config.strictPinning,
        includeSubdomains: this.config.includeSubdomains,
        allowSelfSigned: this.config.allowSelfSigned
      }
    };
  }
}

module.exports = {
  CertificatePinning
};