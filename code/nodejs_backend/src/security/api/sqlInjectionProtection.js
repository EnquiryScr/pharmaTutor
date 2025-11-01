/**
 * SQL Injection Protection
 * Advanced SQL injection prevention with parameterized queries and input sanitization
 */

const { Pool } = require('pg');
const Redis = require('redis');

class SQLInjectionProtection {
  constructor() {
    this.dbPool = null;
    this.redisClient = null;
    this.suspiciousPatterns = [
      /(\bUNION\b|\bSELECT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\bDROP\b|\bCREATE\b|\bALTER\b)/i,
      /(--|\/\*|\*\/)/,
      /(\bor\b|\band\b)\s+['"]?\d+['"]?\s*=\s*['"]?\d+['"]?/i,
      /(\bor\b|\band\b)\s+['"]?\w+['"]?\s*=\s*['"]?\w+['"]?/i,
      /'.*?'.*?'/,
      /".*?".*?"/,
      /;.*$/,
      /\|\|.*$/,
      /&&.*$/,
      /\bxp_cmdshell\b/i,
      /\bsp_executesql\b/i,
      /\binformation_schema\b/i,
      /\bsys\./i,
      /\bmysql\./i,
      /\bload_file\b/i,
      /\binto\s+outfile\b/i
    ];
  }

  async initialize() {
    // Initialize database pool with security settings
    this.dbPool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'tutoring_platform',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Initialize Redis for caching sanitized queries
    this.redisClient = Redis.createClient({
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379,
      password: process.env.REDIS_PASSWORD
    });
    
    await this.redisClient.connect();
    console.log('✅ SQL Injection Protection initialized');
  }

  // Detect potential SQL injection attempts
  detectSQLInjection(input) {
    if (typeof input !== 'string') return false;
    
    return this.suspiciousPatterns.some(pattern => pattern.test(input));
  }

  // Sanitize input for database operations
  sanitizeInput(input) {
    if (typeof input !== 'string') return input;
    
    let sanitized = input;
    
    // Remove null bytes and control characters
    sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
    
    // Escape single quotes (prevent string-based injection)
    sanitized = sanitized.replace(/'/g, "''");
    
    // Escape double quotes
    sanitized = sanitized.replace(/"/g, '""');
    
    // Remove SQL keywords
    const sqlKeywords = [
      'UNION', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER',
      'EXEC', 'EXECUTE', 'DECLARE', 'CAST', 'CONVERT', 'CHAR', 'ASCII',
      'LOAD_FILE', 'INTO OUTFILE', 'INTO DUMPFILE', 'BENCHMARK', 'SLEEP',
      'INFORMATION_SCHEMA', 'SYS', 'MYSQL'
    ];
    
    sqlKeywords.forEach(keyword => {
      const regex = new RegExp(`\\b${keyword}\\b`, 'gi');
      sanitized = sanitized.replace(regex, '');
    });
    
    // Remove SQL comments
    sanitized = sanitized.replace(/--.*$/gm, '');
    sanitized = sanitized.replace(/\/\*.*?\*\//gs, '');
    
    return sanitized;
  }

  // Create parameterized query with validation
  createParameterizedQuery(query, params = []) {
    // Validate query structure
    if (this.isUnsafeQuery(query)) {
      throw new Error('Unsafe SQL query detected');
    }
    
    // Validate parameters
    const validatedParams = params.map(param => {
      if (typeof param === 'string') {
        if (this.detectSQLInjection(param)) {
          throw new Error('SQL injection attempt detected in parameter');
        }
        return this.sanitizeInput(param);
      }
      return param;
    });
    
    return {
      text: query,
      values: validatedParams
    };
  }

  // Check if query contains unsafe patterns
  isUnsafeQuery(query) {
    if (typeof query !== 'string') return true;
    
    // Check for dangerous patterns
    const dangerousPatterns = [
      /\b(DROP|DELETE|UPDATE)\s+.*\s+(FROM|WHERE|IN|SET)/i,
      /\bEXEC(UTE)?\b/i,
      /\bxp_cmdshell\b/i,
      /\bsp_executesql\b/i,
      /\bINTO\s+(OUTFILE|DUMPFILE)\b/i,
      /\bLOAD_FILE\b/i,
      /\bBENCHMARK\b/i,
      /\bSLEEP\b/i
    ];
    
    return dangerousPatterns.some(pattern => pattern.test(query));
  }

  // Middleware for request validation
  middleware(options = {}) {
    const {
      detectOnly = false,
      logSuspicious = true,
      blockRequests = true
    } = options;

    return (req, res, next) => {
      const userIP = req.ip || req.connection.remoteAddress;
      
      try {
        // Check all request parameters for SQL injection
        const suspiciousInputs = [];
        
        // Check body
        if (req.body) {
          this.checkObjectForSQLInjection(req.body, suspiciousInputs, 'body');
        }
        
        // Check query parameters
        if (req.query) {
          this.checkObjectForSQLInjection(req.query, suspiciousInputs, 'query');
        }
        
        // Check route parameters
        if (req.params) {
          this.checkObjectForSQLInjection(req.params, suspiciousInputs, 'params');
        }
        
        if (suspiciousInputs.length > 0) {
          if (logSuspicious) {
            console.warn(`SQL injection attempt detected from ${userIP}:`, suspiciousInputs);
            
            // Log to Redis for rate limiting
            this.logSuspiciousActivity(userIP, 'sql_injection', suspiciousInputs);
          }
          
          if (blockRequests) {
            return res.status(400).json({
              error: 'Invalid input detected',
              code: 'INVALID_INPUT'
            });
          }
        }
        
        next();
      } catch (error) {
        console.error('SQL injection protection error:', error);
        next();
      }
    };
  }

  // Check object recursively for SQL injection patterns
  checkObjectForSQLInjection(obj, suspiciousInputs, path = '') {
    if (typeof obj === 'string') {
      if (this.detectSQLInjection(obj)) {
        suspiciousInputs.push({
          path,
          value: obj,
          type: 'string'
        });
      }
    } else if (Array.isArray(obj)) {
      obj.forEach((item, index) => {
        this.checkObjectForSQLInjection(item, suspiciousInputs, `${path}[${index}]`);
      });
    } else if (obj && typeof obj === 'object') {
      Object.keys(obj).forEach(key => {
        this.checkObjectForSQLInjection(obj[key], suspiciousInputs, path ? `${path}.${key}` : key);
      });
    }
  }

  // Log suspicious activity to Redis
  async logSuspiciousActivity(ip, type, details) {
    try {
      const key = `security:violations:${ip}`;
      const violations = await this.redisClient.incr(key);
      await this.redisClient.expire(key, 3600); // 1 hour expiry
      
      // If too many violations, add to blacklist
      if (violations > 10) {
        await this.redisClient.sAdd('security:blacklist:ips', ip);
        await this.redisClient.expire('security:blacklist:ips', 86400); // 24 hours
        console.warn(`IP ${ip} added to security blacklist for ${type} attempts`);
      }
    } catch (error) {
      console.error('Error logging suspicious activity:', error);
    }
  }

  // Safe database query execution
  async executeSafeQuery(query, params = [], options = {}) {
    try {
      const {
        timeout = 30000,
        maxRetries = 3
      } = options;
      
      let lastError;
      
      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          // Create parameterized query
          const safeQuery = this.createParameterizedQuery(query, params);
          
          // Add timeout
          const client = await this.dbPool.connect();
          try {
            const result = await client.query(safeQuery);
            return result;
          } finally {
            client.release();
          }
        } catch (error) {
          lastError = error;
          if (attempt === maxRetries) break;
          
          // Exponential backoff
          await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
        }
      }
      
      throw lastError;
    } catch (error) {
      console.error('Safe query execution failed:', error);
      throw error;
    }
  }

  // Query result sanitization
  sanitizeQueryResult(result) {
    if (!result || !result.rows) return result;
    
    const sanitizedRows = result.rows.map(row => {
      const sanitizedRow = {};
      Object.keys(row).forEach(key => {
        const value = row[key];
        if (typeof value === 'string') {
          // Remove potential script tags and dangerous content
          sanitizedRow[key] = value
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
            .replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, '')
            .replace(/javascript:/gi, '');
        } else {
          sanitizedRow[key] = value;
        }
      });
      return sanitizedRow;
    });
    
    return {
      ...result,
      rows: sanitizedRows
    };
  }

  // Check if IP is blacklisted
  async isBlacklisted(ip) {
    try {
      const isBlacklisted = await this.redisClient.sIsMember('security:blacklist:ips', ip);
      return isBlacklisted;
    } catch (error) {
      console.error('Error checking IP blacklist:', error);
      return false;
    }
  }

  // Whitelist management
  async whitelistIP(ip) {
    try {
      await this.redisClient.sAdd('security:whitelist:ips', ip);
      await this.redisClient.expire('security:whitelist:ips', 2592000); // 30 days
    } catch (error) {
      console.error('Error whitelisting IP:', error);
    }
  }

  // Blacklist management
  async blacklistIP(ip, duration = 86400) {
    try {
      await this.redisClient.sAdd('security:blacklist:ips', ip);
      await this.redisClient.expire('security:blacklist:ips', duration);
    } catch (error) {
      console.error('Error blacklisting IP:', error);
    }
  }

  // Connection pool health check
  async checkDatabaseHealth() {
    try {
      const client = await this.dbPool.connect();
      try {
        const result = await client.query('SELECT 1');
        return {
          healthy: true,
          connections: this.dbPool.totalCount,
          idle: this.dbPool.idleCount,
          waiting: this.dbPool.waitingCount
        };
      } finally {
        client.release();
      }
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }
}

module.exports = {
  SQLInjectionProtection
};