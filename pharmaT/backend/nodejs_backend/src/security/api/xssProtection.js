/**
 * XSS (Cross-Site Scripting) Protection
 * Advanced XSS prevention with content sanitization and CSP enforcement
 */

const DOMPurify = require('dompurify');
const { JSDOM } = require('jsdom');
const validator = require('validator');

class XSSProtection {
  constructor() {
    this.window = null;
    this.DOMPurify = null;
    this.xssPatterns = [
      /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
      /<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi,
      /<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi,
      /<embed\b[^<]*(?:(?!<\/embed>)<[^<]*)*<\/embed>/gi,
      /<link\b[^<]*(?:(?!<\/link>)<[^<]*)*<\/link>/gi,
      /<meta\b[^<]*(?:(?!>)<[^<]*)*>/gi,
      /javascript:/gi,
      /vbscript:/gi,
      /data:text\/html/gi,
      /data:.*\/javascript/gi,
      /on\w+\s*=/gi, // Event handlers
      /<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi
    ];
    
    this.eventHandlers = [
      'onclick', 'ondblclick', 'onmousedown', 'onmouseup', 'onmouseover',
      'onmousemove', 'onmouseout', 'onkeypress', 'onkeydown', 'onkeyup',
      'onload', 'onunload', 'onfocus', 'onblur', 'onchange', 'onsubmit',
      'onreset', 'onselect', 'onabort', 'onerror', 'onmousewheel',
      'onmouseenter', 'onmouseleave', 'onpointerdown', 'onpointerup',
      'onpointermove', 'onpointercancel', 'onpointerover', 'onpointerout',
      'onpointerenter', 'onpointerleave'
    ];
    
    this.dangerousTags = [
      'script', 'iframe', 'object', 'embed', 'link', 'style', 'meta',
      'base', 'form', 'input', 'button', 'textarea', 'select', 'option'
    ];
  }

  initialize() {
    // Initialize DOMPurify with secure configuration
    this.window = new JSDOM('').window;
    this.DOMPurify = DOMPurify(this.window);
    
    // Configure DOMPurify for maximum security
    this.configureDOMPurify();
    
    console.log('✅ XSS Protection initialized');
  }

  configureDOMPurify() {
    // Default secure configuration
    this.secureConfig = {
      ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'u', 'i', 'b', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'span', 'div', 'blockquote', 'code', 'pre'],
      ALLOWED_ATTR: ['class', 'id', 'title', 'href', 'rel', 'target'],
      ALLOW_DATA_ATTR: false,
      FORBID_TAGS: this.dangerousTags,
      FORBID_ATTR: this.eventHandlers,
      RETURN_TRUSTED_TYPE: false,
      SANITIZE_DOM: true,
      KEEP_CONTENT: false
    };

    // Relaxed configuration for trusted content
    this.relaxedConfig = {
      ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'u', 'i', 'b', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'span', 'div', 'blockquote', 'code', 'pre', 'img', 'a', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 'sup', 'sub'],
      ALLOWED_ATTR: ['class', 'id', 'title', 'href', 'rel', 'target', 'src', 'alt', 'width', 'height', 'colspan', 'rowspan'],
      ALLOW_DATA_ATTR: false,
      FORBID_TAGS: ['script', 'iframe', 'object', 'embed', 'style', 'meta', 'base'],
      FORBID_ATTR: ['onclick', 'onload', 'onerror', 'onmouseover', 'onfocus', 'onblur', 'onmouseenter', 'onmouseleave'],
      RETURN_TRUSTED_TYPE: false,
      SANITIZE_DOM: true,
      KEEP_CONTENT: false
    };

    // Image-only configuration
    this.imageConfig = {
      ALLOWED_TAGS: ['img'],
      ALLOWED_ATTR: ['src', 'alt', 'width', 'height', 'class', 'id'],
      FORBID_TAGS: ['script', 'iframe', 'object', 'embed', 'style', 'meta', 'base', 'form'],
      FORBID_ATTR: ['onclick', 'onload', 'onerror', 'onmouseover', 'onfocus', 'onblur'],
      RETURN_TRUSTED_TYPE: false,
      SANITIZE_DOM: true,
      KEEP_CONTENT: false
    };
  }

  // Detect XSS attempts
  detectXSS(input) {
    if (typeof input !== 'string') return false;
    
    return this.xssPatterns.some(pattern => pattern.test(input));
  }

  // Remove script tags and dangerous content
  stripScripts(input) {
    if (typeof input !== 'string') return input;
    
    // Remove script tags
    let sanitized = input.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    
    // Remove javascript: protocol
    sanitized = sanitized.replace(/javascript:/gi, '');
    
    // Remove vbscript: protocol
    sanitized = sanitized.replace(/vbscript:/gi, '');
    
    // Remove data: protocol with javascript
    sanitized = sanitized.replace(/data:[^,]*javascript[^,]*,/gi, '');
    
    return sanitized;
  }

  // Sanitize HTML content
  sanitizeHTML(html, options = {}) {
    const {
      config = 'secure', // 'secure', 'relaxed', 'image'
      allowProtocols = [],
      stripEmptyTags = true
    } = options;

    let domConfig;
    switch (config) {
      case 'relaxed':
        domConfig = this.relaxedConfig;
        break;
      case 'image':
        domConfig = this.imageConfig;
        break;
      default:
        domConfig = this.secureConfig;
    }

    // Add custom protocol whitelist if specified
    if (allowProtocols.length > 0) {
      domConfig = {
        ...domConfig,
        ALLOWED_URI_REGEXP: new RegExp(
          `^(?:(?:(?:f|ht)tps?|mailto|tel|callto):|[^a-z]|[a-z+.\\-]+(?:[^a-z+.\\-:]|$))`,
          'i'
        )
      };
    }

    try {
      let sanitized = this.DOMPurify.sanitize(html, domConfig);
      
      // Additional sanitization
      sanitized = this.sanitizeLinks(sanitized, allowProtocols);
      sanitized = this.sanitizeImages(sanitized);
      
      if (stripEmptyTags) {
        sanitized = this.stripEmptyTags(sanitized);
      }
      
      return sanitized;
    } catch (error) {
      console.error('HTML sanitization error:', error);
      return '';
    }
  }

  // Sanitize links to prevent protocol abuse
  sanitizeLinks(html, allowedProtocols = []) {
    return html.replace(/<a\s+([^>]*?)>/gi, (match, attrs) => {
      // Extract href attribute
      const hrefMatch = attrs.match(/href=["']([^"']*)["']/i);
      if (!hrefMatch) return match;
      
      const href = hrefMatch[1];
      
      // Check protocol
      if (!this.isAllowedProtocol(href, allowedProtocols)) {
        // Remove href or replace with safe protocol
        const safeAttrs = attrs.replace(/href=["'][^"']*["']/i, '');
        return `<a ${safeAttrs}>`;
      }
      
      return match;
    });
  }

  // Sanitize image sources
  sanitizeImages(html) {
    return html.replace(/<img\s+([^>]*?)>/gi, (match, attrs) => {
      // Extract src attribute
      const srcMatch = attrs.match(/src=["']([^"']*)["']/i);
      if (!srcMatch) return match;
      
      const src = srcMatch[1];
      
      // Only allow safe image protocols
      if (!this.isSafeImageSource(src)) {
        const safeAttrs = attrs.replace(/src=["'][^"']*["']/i, 'src=""');
        return `<img ${safeAttrs} alt="Sanitized image">`;
      }
      
      return match;
    });
  }

  // Check if protocol is allowed
  isAllowedProtocol(url, allowedProtocols) {
    if (!url) return false;
    
    const protocol = url.split(':')[0].toLowerCase();
    
    // Default allowed protocols
    const defaultAllowed = ['http', 'https', 'mailto', 'tel', 'callto'];
    const allAllowed = [...defaultAllowed, ...allowedProtocols];
    
    return allAllowed.includes(protocol);
  }

  // Check if image source is safe
  isSafeImageSource(src) {
    if (!src) return false;
    
    const protocol = src.split(':')[0].toLowerCase();
    const allowedImageProtocols = ['http', 'https', 'data'];
    
    if (!allowedImageProtocols.includes(protocol)) return false;
    
    // Check data URLs
    if (protocol === 'data') {
      const mimeType = src.substring(5, src.indexOf(';'));
      return mimeType.startsWith('image/');
    }
    
    return true;
  }

  // Strip empty HTML tags
  stripEmptyTags(html) {
    return html.replace(/<([a-zA-Z0-9]+)[^>]*><\/\1>/gi, '');
  }

  // Sanitize text content for plain text display
  sanitizeText(text) {
    if (typeof text !== 'string') return text;
    
    let sanitized = text;
    
    // Remove script tags and dangerous content
    sanitized = this.stripScripts(sanitized);
    
    // Remove event handlers
    this.eventHandlers.forEach(handler => {
      const pattern = new RegExp(`${handler}\\s*=\\s*["'][^"']*["']`, 'gi');
      sanitized = sanitized.replace(pattern, '');
    });
    
    // Remove javascript: and data: protocols
    sanitized = sanitized
      .replace(/javascript:/gi, '')
      .replace(/data:/gi, '');
    
    return sanitized;
  }

  // Middleware for request sanitization
  middleware(options = {}) {
    const {
      stripHTML = true,
      sanitizeHTML = false,
      config = 'secure',
      detectOnly = false,
      logSuspicious = true,
      blockRequests = true
    } = options;

    return (req, res, next) => {
      const userIP = req.ip || req.connection.remoteAddress;
      
      try {
        // Check for XSS attempts
        const suspiciousInputs = [];
        
        // Check body
        if (req.body) {
          this.checkObjectForXSS(req.body, suspiciousInputs, 'body');
        }
        
        // Check query parameters
        if (req.query) {
          this.checkObjectForXSS(req.query, suspiciousInputs, 'query');
        }
        
        // Check route parameters
        if (req.params) {
          this.checkObjectForXSS(req.params, suspiciousInputs, 'params');
        }
        
        if (suspiciousInputs.length > 0) {
          if (logSuspicious) {
            console.warn(`XSS attempt detected from ${userIP}:`, suspiciousInputs);
          }
          
          if (blockRequests) {
            return res.status(400).json({
              error: 'Potentially unsafe content detected',
              code: 'UNSAFE_CONTENT'
            });
          }
        }
        
        // Sanitize request data
        if (stripHTML || sanitizeHTML) {
          if (req.body) {
            req.body = this.sanitizeObject(req.body, {
              stripHTML,
              sanitizeHTML,
              config
            });
          }
          
          if (req.query) {
            req.query = this.sanitizeObject(req.query, {
              stripHTML,
              sanitizeHTML,
              config
            });
          }
          
          if (req.params) {
            req.params = this.sanitizeObject(req.params, {
              stripHTML,
              sanitizeHTML,
              config
            });
          }
        }
        
        next();
      } catch (error) {
        console.error('XSS protection error:', error);
        next();
      }
    };
  }

  // Check object recursively for XSS patterns
  checkObjectForXSS(obj, suspiciousInputs, path = '') {
    if (typeof obj === 'string') {
      if (this.detectXSS(obj)) {
        suspiciousInputs.push({
          path,
          value: obj,
          type: 'string'
        });
      }
    } else if (Array.isArray(obj)) {
      obj.forEach((item, index) => {
        this.checkObjectForXSS(item, suspiciousInputs, `${path}[${index}]`);
      });
    } else if (obj && typeof obj === 'object') {
      Object.keys(obj).forEach(key => {
        this.checkObjectForXSS(obj[key], suspiciousInputs, path ? `${path}.${key}` : key);
      });
    }
  }

  // Sanitize object recursively
  sanitizeObject(obj, options) {
    const {
      stripHTML = true,
      sanitizeHTML = false,
      config = 'secure'
    } = options;

    if (typeof obj === 'string') {
      if (stripHTML) {
        return this.sanitizeText(obj);
      }
      if (sanitizeHTML) {
        return this.sanitizeHTML(obj, { config });
      }
      return obj;
    }

    if (Array.isArray(obj)) {
      return obj.map(item => this.sanitizeObject(item, options));
    }

    if (obj && typeof obj === 'object') {
      const sanitized = {};
      Object.keys(obj).forEach(key => {
        sanitized[key] = this.sanitizeObject(obj[key], options);
      });
      return sanitized;
    }

    return obj;
  }

  // Escape HTML entities for output
  escapeHTML(text) {
    if (typeof text !== 'string') return text;
    
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/\//g, '&#x2F;');
  }

  // Content Security Policy generator
  generateCSP(options = {}) {
    const {
      allowInlineScripts = false,
      allowInlineStyles = false,
      allowImages = true,
      allowConnections = true,
      allowFonts = true,
      allowMedia = true,
      allowForms = false,
      frameAncestors = "'none'",
      objectSrc = "'none'"
    } = options;

    const directives = [];

    // Base directives
    directives.push(`default-src 'self'`);
    
    if (allowInlineScripts) {
      directives.push(`script-src 'self' 'unsafe-inline'`);
    } else {
      directives.push(`script-src 'self'`);
    }
    
    if (allowInlineStyles) {
      directives.push(`style-src 'self' 'unsafe-inline'`);
    } else {
      directives.push(`style-src 'self'`);
    }
    
    if (allowImages) {
      directives.push(`img-src 'self' data: https:`);
    } else {
      directives.push(`img-src 'self'`);
    }
    
    if (allowConnections) {
      directives.push(`connect-src 'self' ws: wss:`);
    } else {
      directives.push(`connect-src 'self'`);
    }
    
    if (allowFonts) {
      directives.push(`font-src 'self' https: data:`);
    } else {
      directives.push(`font-src 'self'`);
    }
    
    if (allowMedia) {
      directives.push(`media-src 'self' https: data:`);
    } else {
      directives.push(`media-src 'self'`);
    }
    
    if (allowForms) {
      directives.push(`form-action 'self'`);
    } else {
      directives.push(`form-action 'none'`);
    }
    
    directives.push(`object-src ${objectSrc}`);
    directives.push(`frame-ancestors ${frameAncestors}`);
    directives.push(`base-uri 'self'`);
    directives.push(`manifest-src 'self'`);

    return directives.join('; ');
  }

  // Validate URL for safety
  validateURL(url) {
    try {
      const parsed = new URL(url);
      
      // Check protocol
      const allowedProtocols = ['http:', 'https:', 'mailto:', 'tel:'];
      if (!allowedProtocols.includes(parsed.protocol)) {
        return false;
      }
      
      // Check for javascript: and data: protocols
      if (url.toLowerCase().includes('javascript:') || url.toLowerCase().includes('data:')) {
        return false;
      }
      
      return true;
    } catch {
      return false;
    }
  }
}

module.exports = {
  XSSProtection
};