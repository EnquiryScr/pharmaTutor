/**
 * Secure Headers Management
 * Comprehensive security headers configuration and enforcement
 */

const helmet = require('helmet');
const crypto = require('crypto');

class SecureHeaders {
  constructor() {
    this.config = {
      // Content Security Policy
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
        },
        reportOnly: false,
        useDefaults: true
      },
      
      // HTTP Strict Transport Security
      hsts: {
        enabled: true,
        maxAge: 31536000, // 1 year
        includeSubDomains: true,
        preload: true
      },
      
      // X-Frame-Options
      frameguard: {
        enabled: true,
        action: 'deny' // 'deny' | 'sameorigin' | 'allow-from'
      },
      
      // X-Content-Type-Options
      noSniff: {
        enabled: true
      },
      
      // X-XSS-Protection
      xssFilter: {
        enabled: true,
        mode: 'block' // 'block' | 'sanitize'
      },
      
      // Referrer Policy
      referrerPolicy: {
        enabled: true,
        policy: 'strict-origin-when-cross-origin' // 'no-referrer' | 'no-referrer-when-downgrade' | 'origin' | 'origin-when-cross-origin' | 'same-origin' | 'strict-origin' | 'strict-origin-when-cross-origin' | 'no-referrer-when-downgrade' | 'unsafe-url'
      },
      
      // Permissions Policy
      permissionsPolicy: {
        enabled: true,
        directives: {
          'accelerometer': '()',
          'camera': '()',
          'clipboard-read': '()',
          'clipboard-write': '()',
          'fullscreen': '()',
          'geolocation': '()',
          'gyroscope': '()',
          'magnetometer': '()',
          'microphone': '()',
          'midi': '()',
          'payment': '()',
          'usb': '()',
          'interest-cohort': '()' // Privacy: disable FLoC
        }
      },
      
      // Additional security headers
      crossOriginEmbedderPolicy: {
        enabled: true,
        policy: 'require-corp'
      },
      
      crossOriginOpenerPolicy: {
        enabled: true,
        policy: 'same-origin'
      },
      
      crossOriginResourcePolicy: {
        enabled: true,
        policy: 'same-origin'
      },
      
      // Custom headers
      customHeaders: {
        'X-Powered-By': null, // Remove
        'Server': 'Secure-Server', // Custom server header
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
        'Content-Security-Policy': '', // Will be set by CSP middleware
        'Referrer-Policy': 'strict-origin-when-cross-origin',
        'Permissions-Policy': 'geolocation=(), microphone=(), camera=()'
      }
    };
    
    this.headerStats = {
      totalRequests: 0,
      securityViolations: 0,
      cspViolations: 0,
      hstsEnabled: 0
    };
  }

  initialize() {
    try {
      this.configureHelmet();
      console.log('✅ Secure Headers initialized');
    } catch (error) {
      throw new Error(`Failed to initialize Secure Headers: ${error.message}`);
    }
  }

  // Configure Helmet with comprehensive security settings
  configureHelmet() {
    this.helmetConfig = {
      // Content Security Policy
      contentSecurityPolicy: this.config.contentSecurityPolicy.enabled ? {
        directives: this.buildCSPDirectives(),
        reportOnly: this.config.contentSecurityPolicy.reportOnly,
        useDefaults: this.config.contentSecurityPolicy.useDefaults
      } : false,
      
      // HTTP Strict Transport Security
      hsts: this.config.hsts.enabled ? {
        maxAge: this.config.hsts.maxAge,
        includeSubDomains: this.config.hsts.includeSubDomains,
        preload: this.config.hsts.preload
      } : false,
      
      // X-Frame-Options
      frameguard: this.config.frameguard.enabled ? {
        action: this.config.frameguard.action
      } : false,
      
      // X-Content-Type-Options
      noSniff: this.config.noSniff.enabled,
      
      // X-XSS-Protection
      xssFilter: this.config.xssFilter.enabled,
      
      // Referrer Policy
      referrerPolicy: this.config.referrerPolicy.enabled ? this.config.referrerPolicy.policy : false,
      
      // Permissions Policy
      permissionsPolicy: this.config.permissionsPolicy.enabled ? this.buildPermissionsPolicy() : false,
      
      // Cross-Origin Resource Policy
      crossOriginResourcePolicy: this.config.crossOriginResourcePolicy.enabled ? {
        policy: this.config.crossOriginResourcePolicy.policy
      } : false,
      
      // Cross-Origin Embedder Policy
      crossOriginEmbedderPolicy: this.config.crossOriginEmbedderPolicy.enabled ? {
        policy: this.config.crossOriginEmbedderPolicy.policy
      } : false,
      
      // Cross-Origin Opener Policy
      crossOriginOpenerPolicy: this.config.crossOriginOpenerPolicy.enabled ? {
        policy: this.config.crossOriginOpenerPolicy.policy
      } : false,
      
      // Remove X-Powered-By header
      hidePoweredBy: true,
      
      // DNS Prefetch Control
      dnsPrefetchControl: { allow: false },
      
      // IE No Open
      ieNoOpen: true,
      
      // Don't infer content type
      noSniff: true,
      
      // Origin Agent Cluster
      originAgentCluster: true
    };
  }

  // Build CSP directives
  buildCSPDirectives() {
    const directives = {};
    
    for (const [key, value] of Object.entries(this.config.contentSecurityPolicy.directives)) {
      // Convert camelCase to kebab-case for CSP
      const cspKey = key.replace(/([A-Z])/g, '-$1').toLowerCase();
      
      if (Array.isArray(value)) {
        directives[cspKey] = value;
      } else if (typeof value === 'boolean') {
        // Handle boolean directives like upgradeInsecureRequests
        if (value) {
          directives[cspKey] = [];
        }
      }
    }
    
    return directives;
  }

  // Build Permissions Policy
  buildPermissionsPolicy() {
    const policy = {};
    
    for (const [feature, allowedOrigins] of Object.entries(this.config.permissionsPolicy.directives)) {
      policy[feature] = Array.isArray(allowedOrigins) ? allowedOrigins : [allowedOrigins];
    }
    
    return policy;
  }

  // Main middleware for secure headers
  middleware(options = {}) {
    const finalOptions = { ...this.config, ...options };
    
    return (req, res, next) => {
      try {
        // Apply Helmet middleware
        const helmetMiddleware = helmet(this.helmetConfig);
        helmetMiddleware(req, res, () => {
          // Apply custom headers after Helmet
          this.applyCustomHeaders(req, res);
          
          // Apply domain-specific headers
          this.applyDomainSpecificHeaders(req, res);
          
          // Log header application
          this.logHeaderApplication(req, res);
          
          next();
        });
      } catch (error) {
        console.error('Secure headers middleware error:', error);
        next(); // Continue on error
      }
    };
  }

  // Apply custom headers
  applyCustomHeaders(req, res) {
    for (const [headerName, headerValue] of Object.entries(this.config.customHeaders)) {
      if (headerValue === null) {
        // Remove header
        res.removeHeader(headerName);
      } else if (headerValue !== '') {
        // Set header
        res.setHeader(headerName, headerValue);
      }
    }
  }

  // Apply domain-specific headers
  applyDomainSpecificHeaders(req, res) {
    const domain = this.extractDomainFromRequest(req);
    
    // Apply stricter headers for admin domains
    if (domain && this.isAdminDomain(domain)) {
      res.setHeader('X-Frame-Options', 'DENY');
      res.setHeader('Content-Security-Policy', this.buildAdminCSP());
      res.setHeader('X-Content-Type-Options', 'nosniff');
    }
    
    // Apply API-specific headers
    if (this.isAPIRequest(req)) {
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('X-Frame-Options', 'DENY');
      
      // Relax CSP for API endpoints
      if (req.path.startsWith('/api/')) {
        res.setHeader('Content-Security-Policy', this.buildAPICSP());
      }
    }
  }

  // Extract domain from request
  extractDomainFromRequest(req) {
    const host = req.headers.host;
    const origin = req.headers.origin;
    
    if (host) {
      return host.split(':')[0];
    }
    
    if (origin) {
      try {
        const url = new URL(origin);
        return url.hostname;
      } catch {
        return null;
      }
    }
    
    return null;
  }

  // Check if domain is admin domain
  isAdminDomain(domain) {
    const adminPatterns = [
      /^admin\./,
      /^admin-/
    ];
    
    return adminPatterns.some(pattern => pattern.test(domain));
  }

  // Check if request is API request
  isAPIRequest(req) {
    return req.path.startsWith('/api/') || 
           req.path.startsWith('/v1/') || 
           req.headers.accept?.includes('application/json');
  }

  // Build admin-specific CSP
  buildAdminCSP() {
    return [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "connect-src 'self' wss: https:",
      "font-src 'self' https:",
      "object-src 'none'",
      "frame-ancestors 'none'",
      "base-uri 'self'",
      "form-action 'self'"
    ].join('; ');
  }

  // Build API-specific CSP
  buildAPICSP() {
    return [
      "default-src 'self'",
      "script-src 'self'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data:",
      "connect-src 'self'",
      "object-src 'none'",
      "frame-ancestors 'none'"
    ].join('; ');
  }

  // Dynamic CSP generation
  generateDynamicCSP(req, options = {}) {
    const {
      allowInlineScripts = false,
      allowInlineStyles = true,
      allowExternalDomains = [],
      allowWebSockets = true,
      allowImages = true,
      strictMode = false
    } = options;
    
    const directives = [];
    
    // Base directives
    directives.push(`default-src 'self'`);
    
    // Script sources
    const scriptSrc = ["'self'"];
    if (allowInlineScripts) {
      scriptSrc.push("'unsafe-inline'");
    }
    if (allowInlineScripts && !strictMode) {
      scriptSrc.push("'unsafe-eval'");
    }
    directives.push(`script-src ${scriptSrc.join(' ')}`);
    
    // Style sources
    const styleSrc = ["'self'"];
    if (allowInlineStyles) {
      styleSrc.push("'unsafe-inline'");
    }
    styleSrc.push("https://fonts.googleapis.com");
    directives.push(`style-src ${styleSrc.join(' ')}`);
    
    // Image sources
    const imgSrc = ["'self'"];
    if (allowImages) {
      imgSrc.push("data:", "https:");
    }
    directives.push(`img-src ${imgSrc.join(' ')}`);
    
    // Connect sources
    const connectSrc = ["'self'"];
    if (allowWebSockets) {
      connectSrc.push("wss:", "https:");
    }
    if (allowExternalDomains.length > 0) {
      connectSrc.push(...allowExternalDomains);
    }
    directives.push(`connect-src ${connectSrc.join(' ')}`);
    
    // Font sources
    directives.push("font-src 'self' https://fonts.gstatic.com");
    
    // Object sources
    directives.push("object-src 'none'");
    
    // Frame sources
    directives.push("frame-src 'none'");
    
    // Frame ancestors
    directives.push("frame-ancestors 'none'");
    
    // Base URI
    directives.push("base-uri 'self'");
    
    // Form action
    directives.push("form-action 'self'");
    
    // Upgrade insecure requests (in production)
    if (process.env.NODE_ENV === 'production') {
      directives.push("upgrade-insecure-requests");
    }
    
    return directives.join('; ');
  }

  // Log header application
  logHeaderApplication(req, res) {
    this.headerStats.totalRequests++;
    
    // Check if HSTS is enabled
    if (res.getHeader('Strict-Transport-Security')) {
      this.headerStats.hstsEnabled++;
    }
    
    // Log CSP violations (if any)
    const csp = res.getHeader('Content-Security-Policy');
    if (csp && csp.includes('report-only')) {
      this.headerStats.cspViolations++;
    }
  }

  // Generate security report
  generateSecurityReport() {
    const totalRequests = this.headerStats.totalRequests;
    
    return {
      totalRequests,
      hstsEnabled: this.headerStats.hstsEnabled,
      hstsPercentage: totalRequests > 0 ? (this.headerStats.hstsEnabled / totalRequests * 100).toFixed(2) : 0,
      cspViolations: this.headerStats.cspViolations,
      configuration: this.getHeaderConfiguration()
    };
  }

  // Get current header configuration
  getHeaderConfiguration() {
    return {
      contentSecurityPolicy: this.config.contentSecurityPolicy.enabled,
      hsts: this.config.hsts.enabled,
      frameguard: this.config.frameguard.enabled,
      noSniff: this.config.noSniff.enabled,
      xssFilter: this.config.xssFilter.enabled,
      referrerPolicy: this.config.referrerPolicy.enabled,
      permissionsPolicy: this.config.permissionsPolicy.enabled,
      crossOriginPolicies: {
        embedder: this.config.crossOriginEmbedderPolicy.enabled,
        opener: this.config.crossOriginOpenerPolicy.enabled,
        resource: this.config.crossOriginResourcePolicy.enabled
      }
    };
  }

  // Validate headers configuration
  validateConfiguration() {
    const issues = [];
    
    // Check CSP configuration
    if (this.config.contentSecurityPolicy.enabled) {
      const directives = this.config.contentSecurityPolicy.directives;
      
      if (!directives.scriptSrc || directives.scriptSrc.includes("'unsafe-eval'")) {
        issues.push('CSP allows unsafe-eval which may pose security risks');
      }
      
      if (!directives.frameAncestors || !directives.frameAncestors.includes("'none'")) {
        issues.push('CSP does not prevent clickjacking attacks');
      }
    }
    
    // Check HSTS configuration
    if (this.config.hsts.enabled && this.config.hsts.maxAge < 31536000) {
      issues.push('HSTS max-age is less than recommended 1 year');
    }
    
    // Check X-Frame-Options
    if (this.config.frameguard.enabled && this.config.frameguard.action !== 'deny') {
      issues.push('X-Frame-Options should be set to deny for maximum security');
    }
    
    return {
      valid: issues.length === 0,
      issues
    };
  }

  // Update header configuration
  updateConfiguration(newConfig) {
    try {
      this.config = { ...this.config, ...newConfig };
      this.configureHelmet(); // Reconfigure with new settings
      console.log('Header configuration updated');
      return true;
    } catch (error) {
      console.error('Error updating header configuration:', error);
      return false;
    }
  }

  // Generate nonce for CSP
  generateNonce(length = 16) {
    return crypto.randomBytes(length).toString('base64');
  }

  // Apply CSP with nonce
  applyCSPWithNonce(res, nonce) {
    const cspHeader = this.buildCSPWithNonce(nonce);
    res.setHeader('Content-Security-Policy', cspHeader);
  }

  // Build CSP with nonce
  buildCSPWithNonce(nonce) {
    const directives = this.buildCSPDirectives();
    
    // Replace nonce placeholder with actual nonce
    if (directives['script-src']) {
      directives['script-src'] = directives['script-src'].map(src => {
        if (src === "'nonce'") {
          return `'nonce-${nonce}'`;
        }
        return src;
      });
    }
    
    return Object.entries(directives)
      .map(([key, values]) => `${key} ${Array.isArray(values) ? values.join(' ') : values}`)
      .join('; ');
  }

  // Middleware for CSP nonce generation
  generateNonceMiddleware() {
    return (req, res, next) => {
      const nonce = this.generateNonce();
      res.locals.cspNonce = nonce;
      
      // Apply CSP with nonce
      this.applyCSPWithNonce(res, nonce);
      
      next();
    };
  }

  // Health check for secure headers
  healthCheck() {
    try {
      const validation = this.validateConfiguration();
      
      return {
        healthy: validation.valid,
        issues: validation.issues,
        totalRequests: this.headerStats.totalRequests,
        hstsCoverage: this.headerStats.hstsEnabled,
        configuration: this.getHeaderConfiguration()
      };
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }

  // Reset statistics
  resetStats() {
    this.headerStats = {
      totalRequests: 0,
      securityViolations: 0,
      cspViolations: 0,
      hstsEnabled: 0
    };
  }
}

module.exports = {
  SecureHeaders
};