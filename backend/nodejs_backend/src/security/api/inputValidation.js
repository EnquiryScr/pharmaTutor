/**
 * Input Validation and Sanitization
 * Comprehensive input validation with SQL injection and XSS prevention
 */

const Joi = require('joi');
const DOMPurify = require('dompurify');
const { JSDOM } = require('jsdom');
const validator = require('validator');

class InputValidationService {
  constructor() {
    this.schemas = new Map();
    this.customValidators = new Map();
  }

  initialize() {
    // Initialize DOMPurify with safe configuration
    this.window = new JSDOM('').window;
    this.DOMPurify = DOMPurify(this.window);
    
    // Add custom sanitizers
    this.addCustomSanitizers();
    
    console.log('✅ Input Validation Service initialized');
  }

  addCustomSanitizers() {
    // Add custom validation methods
    this.customValidators.set('email', (value) => {
      return validator.isEmail(value) ? value : null;
    });

    this.customValidators.set('phone', (value) => {
      return validator.isMobilePhone(value, 'any') ? value : null;
    });

    this.customValidators.set('slug', (value) => {
      return validator.matches(value, /^[a-z0-9-]+$/) ? value : null;
    });

    this.customValidators.set('uuid', (value) => {
      return validator.isUUID(value) ? value : null;
    });
  }

  // Comprehensive input sanitization
  sanitize(input, options = {}) {
    const {
      allowHTML = false,
      allowScripts = false,
      allowImages = true,
      maxLength = 1000,
      stripNull = true,
      trim = true
    } = options;

    if (typeof input !== 'string') {
      return stripNull ? null : input;
    }

    let sanitized = input;

    // Trim whitespace
    if (trim) {
      sanitized = sanitized.trim();
    }

    // Check length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    // Remove null bytes
    if (stripNull) {
      sanitized = sanitized.replace(/\0/g, '');
    }

    // HTML sanitization
    if (allowHTML) {
      const config = {
        ALLOWED_TAGS: allowScripts ? ['script', 'style'] : ['p', 'br', 'strong', 'em', 'u', 'i', 'b', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
        ALLOWED_ATTR: ['href', 'title', 'class', 'id', 'style'],
        ALLOW_DATA_ATTR: false,
        FORBID_TAGS: ['style', 'script', 'iframe', 'object', 'embed', 'link'],
        FORBID_ATTR: ['onclick', 'onload', 'onerror', 'onmouseover', 'onfocus', 'onblur']
      };

      if (allowImages) {
        config.ALLOWED_TAGS.push('img');
        config.ALLOWED_ATTR.push('src', 'alt', 'width', 'height');
      }

      sanitized = this.DOMPurify.sanitize(sanitized, config);
    } else {
      // Remove all HTML
      sanitized = this.DOMPurify.sanitize(sanitized, {
        ALLOWED_TAGS: [],
        ALLOWED_ATTR: []
      });
    }

    // SQL injection prevention - encode dangerous characters
    sanitized = sanitized
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '') // Remove control characters
      .replace(/(\'|")/g, '\\$1') // Escape quotes
      .replace(/(\bUNION\b|\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b|\bCREATE\b|\bALTER\b)/gi, '') // Remove SQL keywords
      .replace(/(--|\/\*|\*\/)/g, '') // Remove SQL comments
      .replace(/(\bOR\b|\bAND\b|\bNOT\b)/gi, match => `\\${match}`); // Escape boolean operators

    return sanitized;
  }

  // Schema-based validation
  createSchema(name, schema) {
    this.schemas.set(name, schema);
    return schema;
  }

  validateRequest(schemaName, data) {
    const schema = this.schemas.get(schemaName);
    if (!schema) {
      throw new Error(`Schema ${schemaName} not found`);
    }

    const { error, value } = schema.validate(data);
    if (error) {
      return {
        isValid: false,
        errors: error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message,
          value: detail.context?.value
        }))
      };
    }

    return {
      isValid: true,
      data: value
    };
  }

  // Sanitize object recursively
  sanitizeObject(obj, options = {}) {
    if (typeof obj === 'string') {
      return this.sanitize(obj, options);
    }

    if (Array.isArray(obj)) {
      return obj.map(item => this.sanitizeObject(item, options));
    }

    if (obj && typeof obj === 'object') {
      const sanitized = {};
      for (const [key, value] of Object.entries(obj)) {
        sanitized[key] = this.sanitizeObject(value, options);
      }
      return sanitized;
    }

    return obj;
  }

  // Common validation schemas
  createCommonSchemas() {
    // User registration schema
    const userRegistrationSchema = Joi.object({
      email: Joi.string().email().required().max(255),
      password: Joi.string().min(8).max(128).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/).required()
        .messages({
          'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
        }),
      firstName: Joi.string().min(1).max(50).required(),
      lastName: Joi.string().min(1).max(50).required(),
      dateOfBirth: Joi.date().max('now').optional(),
      userType: Joi.string().valid('student', 'tutor', 'parent', 'admin').required()
    });

    // Login schema
    const loginSchema = Joi.object({
      email: Joi.string().email().required(),
      password: Joi.string().required(),
      rememberMe: Joi.boolean().optional()
    });

    // Assignment schema
    const assignmentSchema = Joi.object({
      title: Joi.string().min(1).max(200).required(),
      description: Joi.string().max(2000).required(),
      dueDate: Joi.date().min('now').required(),
      priority: Joi.string().valid('low', 'medium', 'high', 'urgent').default('medium'),
      category: Joi.string().max(50).optional(),
      attachments: Joi.array().items(Joi.string().uuid()).max(10)
    });

    // File upload schema
    const fileUploadSchema = Joi.object({
      originalName: Joi.string().max(255).required(),
      mimeType: Joi.string().valid(
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain', 'text/csv'
      ).required(),
      size: Joi.number().max(10485760).required(), // 10MB max
      hash: Joi.string().hex().length(64).required()
    });

    // Query/message schema
    const messageSchema = Joi.object({
      content: Joi.string().min(1).max(1000).required(),
      type: Joi.string().valid('text', 'image', 'file', 'system').default('text'),
      recipientId: Joi.string().uuid().optional(),
      subject: Joi.string().max(200).optional()
    });

    // Payment schema
    const paymentSchema = Joi.object({
      amount: Joi.number().min(0.01).max(999999.99).required(),
      currency: Joi.string().valid('USD', 'EUR', 'GBP', 'CAD', 'AUD').required(),
      description: Joi.string().max(500).optional(),
      metadata: Joi.object().optional()
    });

    // Store all schemas
    this.schemas.set('userRegistration', userRegistrationSchema);
    this.schemas.set('login', loginSchema);
    this.schemas.set('assignment', assignmentSchema);
    this.sanitizeObject(this.schemas);
    this.schemas.set('fileUpload', fileUploadSchema);
    this.schemas.set('message', messageSchema);
    this.schemas.set('payment', paymentSchema);

    console.log('✅ Common validation schemas created');
  }

  // Middleware for request validation
  middleware(schemaName, options = {}) {
    return (req, res, next) => {
      try {
        // Sanitize request data
        const sanitizedBody = this.sanitizeObject(req.body, options);
        const sanitizedQuery = this.sanitizeObject(req.query, options);
        const sanitizedParams = this.sanitizeObject(req.params, options);

        // Validate against schema
        const validation = this.validateRequest(schemaName, sanitizedBody);
        
        if (!validation.isValid) {
          return res.status(400).json({
            error: 'Validation failed',
            details: validation.errors
          });
        }

        // Replace request data with sanitized and validated data
        req.body = validation.data;
        req.query = sanitizedQuery;
        req.params = sanitizedParams;

        next();
      } catch (error) {
        console.error('Validation middleware error:', error);
        res.status(500).json({
          error: 'Validation service error'
        });
      }
    };
  }

  // File-specific validation
  validateFileUpload(file, options = {}) {
    const {
      allowedTypes = [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain', 'text/csv'
      ],
      maxSize = 10485760, // 10MB
      requireHash = true
    } = options;

    const errors = [];

    // Check file presence
    if (!file) {
      errors.push('No file provided');
      return { isValid: false, errors };
    }

    // Check file size
    if (file.size > maxSize) {
      errors.push(`File size exceeds maximum allowed size of ${maxSize} bytes`);
    }

    // Check MIME type
    if (!allowedTypes.includes(file.mimetype)) {
      errors.push(`File type ${file.mimetype} is not allowed`);
    }

    // Validate filename
    if (file.originalname && file.originalname.length > 255) {
      errors.push('Filename is too long');
    }

    // Check for dangerous file extensions
    const dangerousExtensions = ['.exe', '.bat', '.cmd', '.com', '.pif', '.scr', '.vbs', '.js', '.jar', '.sh'];
    if (file.originalname) {
      const extension = file.originalname.toLowerCase().substring(file.originalname.lastIndexOf('.'));
      if (dangerousExtensions.includes(extension)) {
        errors.push(`File type ${extension} is not allowed`);
      }
    }

    // Validate file hash if required
    if (requireHash && !file.hash) {
      errors.push('File hash is required');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Advanced SQL injection detection
  detectSQLInjection(input) {
    const sqlPatterns = [
      /(\bUNION\b|\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b|\bCREATE\b|\bALTER\b)/i,
      /(--|\/\*|\*\/)/,
      /('|")/,
      /(;|\|\||&&)/,
      /\b(EXEC|EXECUTE)\b/i,
      /\b(OR|AND|NOT)\s+['"]?[\d]+['"]?\s*=\s*['"]?[\d]+['"]?/i
    ];

    return sqlPatterns.some(pattern => pattern.test(input));
  }

  // Advanced XSS detection
  detectXSS(input) {
    const xssPatterns = [
      /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
      /<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi,
      /javascript:/i,
      /on\w+\s*=/i, // Event handlers
      /data:text\/html/i,
      /<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi,
      /<embed\b[^<]*(?:(?!<\/embed>)<[^<]*)*<\/embed>/gi
    ];

    return xssPatterns.some(pattern => pattern.test(input));
  }
}

// Express middleware for request sanitization
function requestSanitizer(options = {}) {
  return (req, res, next) => {
    const validator = new InputValidationService();
    validator.initialize();

    try {
      // Sanitize request data
      req.body = validator.sanitizeObject(req.body, options);
      req.query = validator.sanitizeObject(req.query, options);
      req.params = validator.sanitizeObject(req.params, options);
      
      // Store validator for route handlers
      req.validator = validator;
      
      next();
    } catch (error) {
      console.error('Request sanitization error:', error);
      res.status(400).json({
        error: 'Invalid request data'
      });
    }
  };
}

module.exports = {
  InputValidationService,
  requestSanitizer
};