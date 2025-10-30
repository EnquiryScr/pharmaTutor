const winston = require('winston');
const { createLogger, format, transports } = winston;

// Custom format for request logging
const requestFormat = format.printf(({ level, message, timestamp, ...metadata }) => {
  let log = `${timestamp} [${level}]: ${message}`;
  
  // Add metadata if present
  if (Object.keys(metadata).length > 0) {
    log += ` | Metadata: ${JSON.stringify(metadata)}`;
  }
  
  return log;
});

// Create logger instance
const logger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(
    format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss'
    }),
    format.errors({ stack: true }),
    format.json()
  ),
  defaultMeta: { service: 'tutoring-backend' },
  transports: [
    // Write to console in development
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.simple(),
        requestFormat
      )
    }),
    
    // Write all logs with level 'info' and below to combined.log
    new transports.File({ 
      filename: 'logs/combined.log',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    
    // Write all logs with level 'error' and below to error.log
    new transports.File({ 
      filename: 'logs/error.log', 
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    })
  ]
});

// Request logger middleware
const requestLogger = (req, res, next) => {
  const start = Date.now();
  
  // Log request
  logger.info('Request received', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    userId: req.user?.userId,
    timestamp: new Date().toISOString()
  });
  
  // Log response when finished
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    logger.info('Request completed', {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userId: req.user?.userId,
      contentLength: res.get('Content-Length'),
      timestamp: new Date().toISOString()
    });
  });
  
  next();
};

// Security logger middleware
const securityLogger = (req, res, next) => {
  // Log suspicious activities
  const suspiciousPatterns = [
    /\b(?:union|select|insert|delete|update|drop|exec|execute)\b/i,
    /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
    /javascript:/i,
    /on\w+\s*=/i,
    /\b(?:eval|alert|confirm|prompt)\b/i
  ];
  
  const userAgent = req.get('User-Agent') || '';
  const body = JSON.stringify(req.body || {});
  const query = JSON.stringify(req.query || {});
  
  const suspicious = suspiciousPatterns.some(pattern => 
    pattern.test(userAgent) || 
    pattern.test(body) || 
    pattern.test(query)
  );
  
  if (suspicious) {
    logger.warn('Suspicious activity detected', {
      type: 'security',
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      userAgent: userAgent,
      body: body,
      query: query,
      userId: req.user?.userId,
      timestamp: new Date().toISOString()
    });
  }
  
  next();
};

// Performance logger middleware
const performanceLogger = (req, res, next) => {
  const startTime = process.hrtime.bigint();
  
  res.on('finish', () => {
    const endTime = process.hrtime.bigint();
    const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds
    
    // Log slow requests
    if (duration > 5000) { // 5 seconds
      logger.warn('Slow request detected', {
        type: 'performance',
        method: req.method,
        url: req.originalUrl,
        duration: `${duration}ms`,
        statusCode: res.statusCode,
        userId: req.user?.userId,
        timestamp: new Date().toISOString()
      });
    }
  });
  
  next();
};

// Database operation logger
const logDatabaseOperation = (operation, collection, query, result, duration) => {
  logger.info('Database operation', {
    type: 'database',
    operation,
    collection,
    duration: `${duration}ms`,
    recordsAffected: result?.nModified || result?.n || result?.length || 0,
    timestamp: new Date().toISOString()
  });
};

// Authentication logger
const logAuthEvent = (event, userId, ip, userAgent, success = true, details = {}) => {
  const logLevel = success ? 'info' : 'warn';
  
  logger.log(logLevel, `Authentication ${event}`, {
    type: 'authentication',
    event,
    success,
    userId,
    ip,
    userAgent,
    details,
    timestamp: new Date().toISOString()
  });
};

// Payment logger
const logPaymentEvent = (event, userId, amount, currency, status, metadata = {}) => {
  logger.info(`Payment ${event}`, {
    type: 'payment',
    event,
    userId,
    amount,
    currency,
    status,
    metadata,
    timestamp: new Date().toISOString()
  });
};

// File operation logger
const logFileOperation = (operation, fileName, fileSize, userId, success = true) => {
  const logLevel = success ? 'info' : 'error';
  
  logger.log(logLevel, `File ${operation}`, {
    type: 'file_operation',
    operation,
    fileName,
    fileSize,
    userId,
    success,
    timestamp: new Date().toISOString()
  });
};

module.exports = {
  requestLogger,
  securityLogger,
  performanceLogger,
  logDatabaseOperation,
  logAuthEvent,
  logPaymentEvent,
  logFileOperation,
  logger
};