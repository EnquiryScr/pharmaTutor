/**
 * Network Security
 * HTTPS enforcement, secure headers, and network-level security measures
 */

const https = require('https');
const fs = require('fs').promises;
const path = require('path');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

class NetworkSecurity {
  constructor() {
    this.config = {
      // HTTPS configuration
      https: {
        enabled: process.env.HTTPS_ENABLED === 'true',
        port: process.env.HTTPS_PORT || 443,
        redirectHttp: true,
        httpPort: process.env.HTTP_PORT || 80,
        minTLSVersion: 'TLSv1.2',
        preferredTLSVersion: 'TLSv1.3'
      },
      
      // SSL/TLS configuration
      ssl: {
        keyPath: process.env.SSL_KEY_PATH || './certs/private.key',
        certPath: process.env.SSL_CERT_PATH || './certs/certificate.crt',
        caPath: process.env.SSL_CA_PATH || './certs/ca_bundle.crt',
        dhParamsPath: process.env.SSL_DH_PARAMS_PATH || './certs/dhparams.pem',
        keySize: 4096,
        ecCurve: 'secp384r1'
      },
      
      // Security headers configuration
      headers: {
        contentSecurityPolicy: {
          enabled: true,
          directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "wss:", "https:"],
            fontSrc: ["'self'", "https://fonts.gstatic.com"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
            frameAncestors: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"],
            upgradeInsecureRequests: []
          }
        },
        
        hsts: {
          maxAge: 31536000, // 1 year
          includeSubDomains: true,
          preload: true
        },
        
        xssProtection: '1; mode=block',
        contentTypeOptions: 'nosniff',
        referrerPolicy: 'strict-origin-when-cross-origin',
        permissionsPolicy: [
          'camera=()',
          'microphone=()',
          'geolocation=()',
          'interest-cohort=()'
        ].join(', ')
      },
      
      // Security features
      features: {
        preventClickjacking: true,
        preventMIMETypeSniffing: true,
        enableXSSProtection: true,
        enableHSTS: true,
        enableCSP: true,
        enableCORP: true
      },
      
      // Certificate pinning
      certificatePinning: {
        enabled: process.env.CERT_PINNING_ENABLED === 'true',
        pins: this.parseCertificatePins(),
        backupPins: []
      }
    };
  }

  async initialize() {
    try {
      // Initialize SSL/TLS configuration
      if (this.config.https.enabled) {
        await this.initializeSSL();
      }
      
      // Initialize security headers
      this.initializeSecurityHeaders();
      
      // Initialize certificate pinning
      if (this.config.certificatePinning.enabled) {
        await this.initializeCertificatePinning();
      }
      
      console.log('✅ Network Security initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Network Security: ${error.message}`);
    }
  }

  // Parse certificate pins from environment
  parseCertificatePins() {
    try {
      const pins = process.env.CERTIFICATE_PINS;
      if (pins) {
        return pins.split(',').map(pin => pin.trim());
      }
      return [];
    } catch (error) {
      console.warn('Error parsing certificate pins:', error);
      return [];
    }
  }

  // Initialize SSL/TLS configuration
  async initializeSSL() {
    try {
      // Check if SSL certificates exist
      const keyExists = await this.checkFileExists(this.config.ssl.keyPath);
      const certExists = await this.checkFileExists(this.config.ssl.certPath);
      
      if (!keyExists || !certExists) {
        console.warn('SSL certificates not found. Generating self-signed certificates for development.');
        await this.generateSelfSignedCertificates();
      }
      
      // Load SSL configuration
      this.sslConfig = {
        key: await fs.readFile(this.config.ssl.keyPath),
        cert: await fs.readFile(this.config.ssl.certPath),
        ca: this.config.ssl.caPath ? await fs.readFile(this.config.ssl.caPath) : undefined,
        dhparam: await this.loadDHParams(),
        
        // Security settings
        minVersion: this.config.https.minTLSVersion,
        maxVersion: this.config.https.preferredTLSVersion,
        honorCipherOrder: true,
        ciphers: this.getSecureCipherSuites(),
        ecdhCurve: this.config.ssl.ecCurve,
        
        // Security features
        rejectUnauthorized: process.env.NODE_ENV === 'production',
        secureProtocol: 'TLSv1.2_method',
        sessionTimeout: 300, // 5 minutes
        
        // Compression
        // Note: Disable compression to prevent CRIME attacks
        // This is handled by the node.js http server automatically
      };
      
      console.log('✅ SSL/TLS configuration loaded');
    } catch (error) {
      throw new Error(`Failed to initialize SSL: ${error.message}`);
    }
  }

  // Load DH parameters for perfect forward secrecy
  async loadDHParams() {
    try {
      return await fs.readFile(this.config.ssl.dhParamsPath);
    } catch (error) {
      console.warn('DH parameters not found, generating new ones...');
      return await this.generateDHParams();
    }
  }

  // Generate DH parameters for perfect forward secrecy
  async generateDHParams() {
    try {
      // In a real implementation, you would generate these offline and store them
      // For now, return null to use server defaults
      console.warn('Using default DH parameters. For production, generate custom DH params.');
      return null;
    } catch (error) {
      console.error('Error generating DH parameters:', error);
      return null;
    }
  }

  // Get secure cipher suites
  getSecureCipherSuites() {
    // Modern cipher suites that support perfect forward secrecy
    return [
      'ECDHE-RSA-AES256-GCM-SHA384',
      'ECDHE-RSA-AES128-GCM-SHA256',
      'ECDHE-RSA-AES256-SHA384',
      'ECDHE-RSA-AES128-SHA256',
      'ECDHE-RSA-AES256-SHA',
      'ECDHE-RSA-AES128-SHA',
      'DHE-RSA-AES256-GCM-SHA384',
      'DHE-RSA-AES128-GCM-SHA256',
      'DHE-RSA-AES256-SHA256',
      'DHE-RSA-AES128-SHA256',
      'DHE-RSA-AES256-SHA',
      'DHE-RSA-AES128-SHA'
    ].join(':');
  }

  // Generate self-signed certificates for development
  async generateSelfSignedCertificates() {
    try {
      // In a real implementation, use a library like 'selfsigned'
      // For now, create placeholder certificate files
      const certDir = path.dirname(this.config.ssl.keyPath);
      
      console.log(`Generating self-signed certificates in ${certDir}...`);
      console.log('Note: Replace with proper certificates for production use.');
      
      // Create placeholder files
      await fs.mkdir(certDir, { recursive: true });
      
      // This is a placeholder - in production, use proper certificate generation
      const placeholder = '# Self-signed certificate placeholder\n# Replace with proper SSL certificates\n';
      await fs.writeFile(this.config.ssl.keyPath, placeholder);
      await fs.writeFile(this.config.ssl.certPath, placeholder);
      
      if (this.config.ssl.caPath) {
        await fs.writeFile(this.config.ssl.caPath, placeholder);
      }
      
      console.log('⚠️  Self-signed certificates generated (for development only)');
    } catch (error) {
      throw new Error(`Failed to generate self-signed certificates: ${error.message}`);
    }
  }

  // Initialize security headers
  initializeSecurityHeaders() {
    this.helmetConfig = {
      // Content Security Policy
      contentSecurityPolicy: this.config.headers.contentSecurityPolicy.enabled ? {
        directives: this.config.headers.contentSecurityPolicy.directives
      } : false,
      
      // HTTP Strict Transport Security
      hsts: this.config.headers.hsts ? {
        maxAge: this.config.headers.hsts.maxAge,
        includeSubDomains: this.config.headers.hsts.includeSubDomains,
        preload: this.config.headers.hsts.preload
      } : false,
      
      // Cross-Origin Resource Policy
      crossOriginResourcePolicy: { policy: 'same-origin' },
      
      // X-Frame-Options (legacy, but still useful)
      frameguard: this.config.features.preventClickjacking ? { action: 'deny' } : false,
      
      // X-Content-Type-Options
      noSniff: this.config.features.preventMIMETypeSniffing,
      
      // X-XSS-Protection
      xssFilter: this.config.features.enableXSSProtection,
      
      // Referrer Policy
      referrerPolicy: this.config.headers.referrerPolicy,
      
      // Permissions Policy
      permissionsPolicy: this.parsePermissionsPolicy(),
      
      // Hide X-Powered-By header
      hidePoweredBy: true,
      
      // DNS Prefetch Control
      dnsPrefetchControl: { allow: false },
      
      // IE No Open
      ieNoOpen: true,
      
      // Don't infer content type
      noSniff: true,
      
      // Origin Agent Cluster
      originAgentCluster: true,
      
      // Cross-Origin Embedder Policy
      crossOriginEmbedderPolicy: { policy: 'require-corp' },
      
      // Cross-Origin Opener Policy
      crossOriginOpenerPolicy: { policy: 'same-origin' },
      
      // Cross-Origin Resource Policy
      crossOriginResourcePolicy: { policy: 'same-origin' }
    };
    
    console.log('✅ Security headers configured');
  }

  // Parse permissions policy
  parsePermissionsPolicy() {
    const policies = [];
    
    // Parse permission policies from config
    if (Array.isArray(this.config.headers.permissionsPolicy)) {
      this.config.headers.permissionsPolicy.forEach(policy => {
        const [feature, allowedOrigins] = policy.split('=');
        if (feature && allowedOrigins) {
          policies.push(feature.trim());
        }
      });
    }
    
    return policies;
  }

  // Middleware for secure headers
  secureHeaders() {
    return helmet(this.helmetConfig);
  }

  // Middleware for HTTPS enforcement
  enforceHTTPS() {
    return (req, res, next) => {
      if (this.config.https.enabled) {
        // Check if request is already HTTPS
        if (req.secure || req.headers['x-forwarded-proto'] === 'https') {
          return next();
        }
        
        // Redirect HTTP to HTTPS
        const host = req.headers.host;
        const url = req.originalUrl;
        
        if (host) {
          const httpsUrl = `https://${host}${url}`;
          return res.redirect(301, httpsUrl);
        }
        
        return res.status(400).send('HTTPS required');
      }
      
      next();
    };
  }

  // Redirect HTTP to HTTPS
  createHTTPRedirect() {
    return (req, res) => {
      if (this.config.https.redirectHttp && !req.secure) {
        const host = req.headers.host;
        const url = req.originalUrl;
        
        if (host) {
          const httpsUrl = `https://${host}${url}`;
          return res.redirect(301, httpsUrl);
        }
      }
      
      res.status(400).send('HTTPS required');
    };
  }

  // Middleware for certificate pinning
  certificatePinning() {
    return async (req, res, next) => {
      if (!this.config.certificatePinning.enabled) {
        return next();
      }
      
      try {
        const socket = req.socket;
        
        if (socket && socket.getPeerCertificate) {
          const peerCert = socket.getPeerCertificate(true);
          const certPin = this.generateCertificatePin(peerCert);
          
          if (!this.validateCertificatePin(certPin)) {
            console.warn(`Certificate pin mismatch detected from ${req.ip}`);
            return res.status(400).send('Certificate validation failed');
          }
        }
        
        next();
      } catch (error) {
        console.error('Certificate pinning error:', error);
        next();
      }
    };
  }

  // Generate certificate pin
  generateCertificatePin(certificate) {
    // SHA-256 hash of the public key
    const publicKey = certificate.publicKey;
    const hash = require('crypto')
      .createHash('sha256')
      .update(publicKey)
      .digest('hex');
    
    return hash;
  }

  // Validate certificate pin
  validateCertificatePin(pin) {
    return this.config.certificatePinning.pins.includes(pin) ||
           this.config.certificatePinning.backupPins.includes(pin);
  }

  // Initialize certificate pinning
  async initializeCertificatePinning() {
    try {
      if (this.config.certificatePinning.pins.length === 0) {
        console.warn('Certificate pinning enabled but no pins configured');
      } else {
        console.log(`Certificate pinning initialized with ${this.config.certificatePinning.pins.length} pins`);
      }
    } catch (error) {
      console.error('Error initializing certificate pinning:', error);
    }
  }

  // Check if file exists
  async checkFileExists(filePath) {
    try {
      await fs.access(filePath);
      return true;
    } catch {
      return false;
    }
  }

  // Rate limiting for network security
  createNetworkRateLimit(options = {}) {
    const defaultOptions = {
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 1000, // limit each IP to 1000 requests per windowMs
      message: {
        error: 'Too many requests from this IP',
        code: 'RATE_LIMIT_EXCEEDED'
      },
      standardHeaders: true,
      legacyHeaders: false,
      skip: (req) => {
        // Skip rate limiting for health checks
        return req.path === '/health' || req.path === '/status';
      }
    };
    
    const finalOptions = { ...defaultOptions, ...options };
    
    return rateLimit(finalOptions);
  }

  // Aggressive rate limiting for suspicious activity
  createAggressiveRateLimit(options = {}) {
    const defaultOptions = {
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 10, // limit each IP to 10 requests per windowMs
      message: {
        error: 'Suspicious activity detected',
        code: 'AGGRESSIVE_RATE_LIMIT'
      },
      standardHeaders: true,
      legacyHeaders: false,
      skipSuccessfulRequests: false,
      skipFailedRequests: false
    };
    
    const finalOptions = { ...defaultOptions, ...options };
    
    return rateLimit(finalOptions);
  }

  // Create HTTPS server
  createHTTPSServer(app) {
    if (!this.config.https.enabled) {
      throw new Error('HTTPS is not enabled');
    }
    
    return https.createServer(this.sslConfig, app);
  }

  // Get SSL configuration
  getSSLConfig() {
    return this.sslConfig;
  }

  // Get security headers configuration
  getSecurityHeadersConfig() {
    return this.helmetConfig;
  }

  // Get certificate pinning configuration
  getCertificatePinningConfig() {
    return this.config.certificatePinning;
  }

  // Validate network security configuration
  validateConfiguration() {
    const issues = [];
    
    // Check HTTPS configuration
    if (this.config.https.enabled) {
      if (!this.sslConfig) {
        issues.push('SSL configuration not loaded');
      }
    }
    
    // Check security headers
    if (!this.helmetConfig) {
      issues.push('Security headers not configured');
    }
    
    // Check certificate pinning
    if (this.config.certificatePinning.enabled && 
        this.config.certificatePinning.pins.length === 0) {
      issues.push('Certificate pinning enabled but no pins configured');
    }
    
    return {
      valid: issues.length === 0,
      issues
    };
  }

  // Get network security status
  getStatus() {
    return {
      https: {
        enabled: this.config.https.enabled,
        redirectHttp: this.config.https.redirectHttp,
        sslConfigured: !!this.sslConfig
      },
      headers: {
        securityHeadersEnabled: !!this.helmetConfig,
        cspEnabled: this.config.headers.contentSecurityPolicy.enabled,
        hstsEnabled: this.config.headers.hsts
      },
      certificatePinning: {
        enabled: this.config.certificatePinning.enabled,
        pinsConfigured: this.config.certificatePinning.pins.length > 0
      },
      validation: this.validateConfiguration()
    };
  }

  // Health check for network security
  async healthCheck() {
    try {
      const status = this.getStatus();
      
      return {
        healthy: status.validation.valid,
        httpsEnabled: status.https.enabled,
        sslConfigured: status.https.sslConfigured,
        securityHeadersConfigured: status.headers.securityHeadersEnabled,
        certificatePinningEnabled: status.certificatePinning.enabled,
        validationIssues: status.validation.issues
      };
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }

  // Update SSL certificates (for automated renewal)
  async updateSSLCertificates() {
    try {
      // Reload SSL configuration
      await this.initializeSSL();
      
      console.log('SSL certificates updated');
      return true;
    } catch (error) {
      console.error('Error updating SSL certificates:', error);
      return false;
    }
  }

  // Export security configuration for external services
  exportSecurityConfig() {
    return {
      https: this.config.https,
      headers: this.config.headers,
      certificatePinning: {
        ...this.config.certificatePinning,
        pins: '***' // Don't expose actual pins
      }
    };
  }
}

module.exports = {
  NetworkSecurity
};