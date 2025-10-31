const winston = require('winston');
const path = require('path');
const fs = require('fs');

class LoggingService {
  constructor() {
    // Create logs directory if it doesn't exist
    const logsDir = path.join(__dirname, '../../logs');
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir, { recursive: true });
    }

    // Custom format for console output
    const consoleFormat = winston.format.combine(
      winston.format.colorize(),
      winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss'
      }),
      winston.format.printf(({ level, message, timestamp, ...meta }) => {
        let log = `${timestamp} [${level}]: ${message}`;
        
        // Add metadata if present
        if (Object.keys(meta).length > 0) {
          log += ` | ${JSON.stringify(meta, null, 2)}`;
        }
        
        return log;
      })
    );

    // Custom format for file output
    const fileFormat = winston.format.combine(
      winston.format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss'
      }),
      winston.format.errors({ stack: true }),
      winston.format.json()
    );

    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: fileFormat,
      defaultMeta: { service: 'tutoring-platform' },
      transports: [
        // Console transport for development
        new winston.transports.Console({
          format: consoleFormat,
          level: process.env.NODE_ENV === 'development' ? 'debug' : 'info'
        }),

        // Combined log file
        new winston.transports.File({
          filename: path.join(logsDir, 'combined.log'),
          maxsize: 5242880, // 5MB
          maxFiles: 10,
          tailable: true
        }),

        // Error log file
        new winston.transports.File({
          filename: path.join(logsDir, 'error.log'),
          level: 'error',
          maxsize: 5242880, // 5MB
          maxFiles: 5,
          tailable: true
        }),

        // Security log file
        new winston.transports.File({
          filename: path.join(logsDir, 'security.log'),
          level: 'warn',
          maxsize: 5242880, // 5MB
          maxFiles: 10,
          tailable: true
        }),

        // Performance log file
        new winston.transports.File({
          filename: path.join(logsDir, 'performance.log'),
          level: 'info',
          maxsize: 5242880, // 5MB
          maxFiles: 5,
          tailable: true
        }),

        // API log file
        new winston.transports.File({
          filename: path.join(logsDir, 'api.log'),
          maxsize: 10485760, // 10MB
          maxFiles: 10,
          tailable: true,
          format: winston.format.combine(
            winston.format.timestamp(),
            winston.format.json()
          )
        })
      ],

      // Handle exceptions and rejections
      exceptionHandlers: [
        new winston.transports.File({
          filename: path.join(logsDir, 'exceptions.log'),
          maxsize: 5242880,
          maxFiles: 5
        })
      ],

      rejectionHandlers: [
        new winston.transports.File({
          filename: path.join(logsDir, 'rejections.log'),
          maxsize: 5242880,
          maxFiles: 5
        })
      ]
    });

    // Add memory transport for high-priority logs
    this.memoryTransport = new winston.transports.Memory({
      level: 'critical',
      maxsize: 1000
    });
    this.logger.add(this.memoryTransport);
  }

  // Basic logging methods
  debug(message, meta = {}) {
    this.logger.debug(message, meta);
  }

  info(message, meta = {}) {
    this.logger.info(message, meta);
  }

  warn(message, meta = {}) {
    this.logger.warn(message, meta);
  }

  error(message, meta = {}) {
    this.logger.error(message, meta);
  }

  critical(message, meta = {}) {
    this.logger.critical(message, meta);
  }

  // Specialized logging methods
  logRequest(req, res, duration) {
    this.info('HTTP Request', {
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip,
      userId: req.user?.userId,
      contentLength: res.get('Content-Length')
    });
  }

  logError(error, req = null) {
    const errorInfo = {
      name: error.name,
      message: error.message,
      stack: error.stack
    };

    if (req) {
      errorInfo.request = {
        method: req.method,
        url: req.originalUrl,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        userId: req.user?.userId,
        body: req.body,
        params: req.params,
        query: req.query
      };
    }

    this.error('Application Error', errorInfo);
  }

  logSecurityEvent(event, details = {}) {
    this.warn('Security Event', {
      event,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  logPerformance(metric, value, unit = 'ms', context = {}) {
    this.info('Performance Metric', {
      metric,
      value,
      unit,
      timestamp: new Date().toISOString(),
      ...context
    });
  }

  logDatabaseOperation(operation, table, duration, rowsAffected = 0) {
    this.debug('Database Operation', {
      operation,
      table,
      duration: `${duration}ms`,
      rowsAffected,
      timestamp: new Date().toISOString()
    });
  }

  logAuthentication(userId, event, success = true, details = {}) {
    const level = success ? 'info' : 'warn';
    
    this[level]('Authentication Event', {
      userId,
      event,
      success,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  logPayment(userId, amount, currency, status, details = {}) {
    this.info('Payment Event', {
      userId,
      amount,
      currency,
      status,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  logFileOperation(operation, fileName, fileSize, userId, success = true) {
    const level = success ? 'info' : 'error';
    
    this[level]('File Operation', {
      operation,
      fileName,
      fileSize,
      userId,
      success,
      timestamp: new Date().toISOString()
    });
  }

  logSocketEvent(event, userId, details = {}) {
    this.debug('Socket Event', {
      event,
      userId,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  logAPIUsage(endpoint, method, statusCode, duration, userId = null) {
    this.info('API Usage', {
      endpoint,
      method,
      statusCode,
      duration: `${duration}ms`,
      userId,
      timestamp: new Date().toISOString()
    });
  }

  // Health and monitoring
  logSystemHealth(metrics) {
    this.info('System Health Check', {
      metrics,
      timestamp: new Date().toISOString()
    });
  }

  logExternalService(service, operation, success, responseTime, details = {}) {
    const level = success ? 'info' : 'warn';
    
    this[level]('External Service Call', {
      service,
      operation,
      success,
      responseTime: `${responseTime}ms`,
      timestamp: new Date().toISOString(),
      ...details
    });
  }

  // Log aggregation and search
  searchLogs(level = 'all', query = '', startDate = null, endDate = null) {
    // This would typically integrate with ELK stack or similar
    // For now, return memory transport logs
    return this.memoryTransport.writeStream.toArray();
  }

  // Monitoring and alerting
  checkMemoryUsage() {
    const used = process.memoryUsage();
    const memoryInfo = {
      rss: Math.round(used.rss / 1024 / 1024) + 'MB',
      heapTotal: Math.round(used.heapTotal / 1024 / 1024) + 'MB',
      heapUsed: Math.round(used.heapUsed / 1024 / 1024) + 'MB',
      external: Math.round(used.external / 1024 / 1024) + 'MB'
    };

    this.logPerformance('memory_usage', memoryInfo, 'MB', { type: 'system' });
    
    return memoryInfo;
  }

  checkCPUUsage() {
    const cpuUsage = process.cpuUsage();
    this.logPerformance('cpu_usage', cpuUsage, 'microseconds', { type: 'system' });
    
    return cpuUsage;
  }

  // Cleanup old log files
  cleanupOldLogs(daysToKeep = 30) {
    const logsDir = path.join(__dirname, '../../logs');
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

    fs.readdirSync(logsDir).forEach(file => {
      const filePath = path.join(logsDir, file);
      const stats = fs.statSync(filePath);
      
      if (stats.isFile() && stats.mtime < cutoffDate) {
        fs.unlinkSync(filePath);
        this.info('Cleaned up old log file', { file, mtime: stats.mtime });
      }
    });
  }

  // Get log statistics
  getLogStats() {
    const logsDir = path.join(__dirname, '../../logs');
    let totalSize = 0;
    let fileCount = 0;

    if (fs.existsSync(logsDir)) {
      const files = fs.readdirSync(logsDir);
      fileCount = files.length;

      files.forEach(file => {
        const filePath = path.join(logsDir, file);
        const stats = fs.statSync(filePath);
        if (stats.isFile()) {
          totalSize += stats.size;
        }
      });
    }

    return {
      totalFiles: fileCount,
      totalSize: totalSize,
      totalSizeFormatted: this.formatBytes(totalSize),
      lastCheck: new Date().toISOString()
    };
  }

  formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  // Flush logs to ensure they're written
  flush() {
    return new Promise((resolve) => {
      this.logger.on('finish', () => {
        resolve();
      });
      this.logger.end();
    });
  }
}

module.exports = LoggingService;