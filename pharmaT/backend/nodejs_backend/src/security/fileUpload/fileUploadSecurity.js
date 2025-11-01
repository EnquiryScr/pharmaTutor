/**
 * File Upload Security
 * Comprehensive file upload security with virus scanning, type validation, and size limits
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const { spawn } = require('child_process');
const multer = require('multer');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');
const { EncryptionService } = require('../encryption/encryption');
const { VirusScanner } = require('./virusScanner');

class FileUploadSecurity {
  constructor() {
    this.encryptionService = new EncryptionService();
    this.virusScanner = new VirusScanner();
    this.config = {
      // File size limits
      maxFileSize: {
        general: 10 * 1024 * 1024, // 10MB
        image: 5 * 1024 * 1024, // 5MB
        document: 20 * 1024 * 1024, // 20MB
        video: 100 * 1024 * 1024, // 100MB
        audio: 50 * 1024 * 1024 // 50MB
      },
      
      // Allowed file types
      allowedTypes: {
        image: [
          'image/jpeg', 'image/png', 'image/gif', 'image/webp',
          'image/svg+xml', 'image/bmp', 'image/tiff'
        ],
        document: [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'text/plain',
          'text/csv',
          'application/rtf'
        ],
        archive: [
          'application/zip',
          'application/x-rar-compressed',
          'application/x-7z-compressed',
          'application/x-tar',
          'application/gzip'
        ],
        audio: [
          'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/m4a',
          'audio/aac', 'audio/flac', 'audio/x-ms-wma'
        ],
        video: [
          'video/mp4', 'video/avi', 'video/mov', 'video/wmv',
          'video/flv', 'video/webm', 'video/mkv'
        ]
      },
      
      // Blocked file extensions
      blockedExtensions: [
        '.exe', '.bat', '.cmd', '.com', '.pif', '.scr', '.vbs', '.js', '.jar',
        '.ps1', '.sh', '.php', '.asp', '.aspx', '.jsp', '.pl', '.py', '.rb',
        '.lnk', '.reg', '.inf', '.dll', '.sys', '.tmp'
      ],
      
      // Scanning options
      scanForViruses: true,
      scanForMalware: true,
      quarantineInfected: true,
      maxQuarantineRetention: 7 * 24 * 60 * 60 * 1000, // 7 days
      
      // Storage options
      encryptFiles: true,
      randomizeNames: true,
      storeInCloud: false,
      cloudProvider: null,
      
      // Processing options
      processImages: true,
      generateThumbnails: true,
      maxThumbnailSize: 200,
      stripMetadata: true
    };
    
    this.uploadStats = {
      totalUploads: 0,
      successfulUploads: 0,
      blockedUploads: 0,
      infectedFiles: 0,
      fileTypes: {}
    };
  }

  async initialize() {
    try {
      await this.encryptionService.initialize();
      await this.virusScanner.initialize();
      console.log('✅ File Upload Security initialized');
    } catch (error) {
      throw new Error(`Failed to initialize File Upload Security: ${error.message}`);
    }
  }

  // Multer configuration for secure file uploads
  configureMulter(options = {}) {
    const {
      storage = multer.memoryStorage(),
      limits = {
        fileSize: this.config.maxFileSize.general,
        files: 5 // Maximum 5 files per request
      },
      fileFilter = this.createFileFilter()
    } = options;

    const upload = multer({
      storage,
      limits,
      fileFilter,
      preservePath: false
    });

    return upload;
  }

  // Create secure file filter
  createFileFilter() {
    return (req, file, cb) => {
      try {
        const result = this.validateFile(file, req);
        
        if (result.isValid) {
          cb(null, true);
        } else {
          cb(new Error(result.error), false);
        }
      } catch (error) {
        cb(error, false);
      }
    };
  }

  // Comprehensive file validation
  validateFile(file, req = null) {
    const errors = [];
    const warnings = [];

    // Basic file validation
    if (!file) {
      return { isValid: false, error: 'No file provided' };
    }

    if (!file.originalname) {
      errors.push('File must have a name');
    }

    if (!file.mimetype) {
      errors.push('File must have a MIME type');
    }

    // Check file size
    const fileSize = file.size || (file.buffer ? file.buffer.length : 0);
    const category = this.getFileCategory(file.mimetype);
    const maxSize = this.config.maxFileSize[category] || this.config.maxFileSize.general;

    if (fileSize > maxSize) {
      errors.push(`File size (${this.formatBytes(fileSize)}) exceeds maximum allowed size (${this.formatBytes(maxSize)})`);
    }

    if (fileSize === 0) {
      errors.push('File cannot be empty');
    }

    // Check file extension
    if (file.originalname) {
      const extension = path.extname(file.originalname).toLowerCase();
      if (this.config.blockedExtensions.includes(extension)) {
        errors.push(`File extension ${extension} is blocked for security reasons`);
      }
    }

    // Check MIME type
    const isAllowedType = this.isAllowedMimeType(file.mimetype);
    if (!isAllowedType) {
      errors.push(`File type ${file.mimetype} is not allowed`);
    }

    // Filename validation
    if (file.originalname) {
      const filenameValidation = this.validateFilename(file.originalname);
      if (!filenameValidation.isValid) {
        errors.push(...filenameValidation.errors);
      }
      
      warnings.push(...filenameValidation.warnings);
    }

    // Additional checks for specific file types
    if (category === 'image') {
      const imageValidation = this.validateImageFile(file);
      if (!imageValidation.isValid) {
        errors.push(...imageValidation.errors);
      }
      warnings.push(...imageValidation.warnings);
    }

    // Check for double extensions
    if (file.originalname) {
      const doubleExt = this.checkDoubleExtension(file.originalname);
      if (doubleExt) {
        errors.push(`Double file extension detected: ${doubleExt}`);
      }
    }

    // Check for path traversal
    if (file.originalname && file.originalname.includes('..')) {
      errors.push('Filename contains path traversal characters');
    }

    // Check for special characters
    if (file.originalname) {
      const specialCharCheck = this.checkSpecialCharacters(file.originalname);
      if (specialCharCheck.hasIssues) {
        warnings.push(`Filename contains unusual characters: ${specialCharCheck.issues.join(', ')}`);
      }
    }

    const result = {
      isValid: errors.length === 0,
      errors,
      warnings,
      fileSize,
      category,
      maxSize,
      shouldScan: this.config.scanForViruses && category !== 'document', // Don't scan text documents
      shouldEncrypt: this.config.encryptFiles
    };

    // Log validation results
    if (!result.isValid) {
      console.warn(`File validation failed: ${file.originalname}`, errors);
    } else if (warnings.length > 0) {
      console.warn(`File validation warnings: ${file.originalname}`, warnings);
    }

    return result;
  }

  // Check for double file extensions
  checkDoubleExtension(filename) {
    const doubleExts = [
      '.exe.php', '.exe.jsp', '.exe.asp', '.exe.cfc',
      '.txt.php', '.txt.jsp', '.txt.asp',
      '.jpg.php', '.jpg.jsp', '.jpg.asp',
      '.png.php', '.png.jsp', '.png.asp'
    ];

    const lowerFilename = filename.toLowerCase();
    return doubleExts.find(ext => lowerFilename.endsWith(ext));
  }

  // Check for special characters in filename
  checkSpecialCharacters(filename) {
    const allowedChars = /^[a-zA-Z0-9._\-\s]+$/;
    const hasNonASCII = /[^\x00-\x7F]/;
    const hasControlChars = /[\x00-\x1F\x7F]/;
    
    const issues = [];
    
    if (!allowedChars.test(filename)) {
      issues.push('special characters');
    }
    
    if (hasNonASCII.test(filename)) {
      issues.push('non-ASCII characters');
    }
    
    if (hasControlChars.test(filename)) {
      issues.push('control characters');
    }

    return {
      hasIssues: issues.length > 0,
      issues
    };
  }

  // Validate filename
  validateFilename(filename) {
    const errors = [];
    const warnings = [];

    // Check length
    if (filename.length > 255) {
      errors.push('Filename is too long (max 255 characters)');
    }

    if (filename.length === 0) {
      errors.push('Filename cannot be empty');
    }

    // Check for reserved names (Windows)
    const reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4',
      'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2',
      'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];

    const nameWithoutExt = path.parse(filename).name.toUpperCase();
    if (reservedNames.includes(nameWithoutExt)) {
      errors.push(`Reserved filename: ${filename}`);
    }

    // Check for suspicious patterns
    const suspiciousPatterns = [
      /script/i,
      /eval/i,
      /exec/i,
      /system/i,
      /cmd\.exe/i,
      /powershell/i
    ];

    for (const pattern of suspiciousPatterns) {
      if (pattern.test(filename)) {
        errors.push(`Suspicious pattern detected: ${pattern.source}`);
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }

  // Validate image file
  validateImageFile(file) {
    const errors = [];
    const warnings = [];

    if (!file.mimetype.startsWith('image/')) {
      errors.push('File is not a valid image type');
      return { isValid: false, errors, warnings };
    }

    // Check if image is corrupted by trying to process it
    if (file.buffer) {
      try {
        // Use sharp to validate image integrity
        sharp(file.buffer).metadata().then(metadata => {
          if (metadata.width && metadata.height) {
            warnings.push(`Image dimensions: ${metadata.width}x${metadata.height}`);
          }
        }).catch(error => {
          errors.push(`Invalid image file: ${error.message}`);
        });
      } catch (error) {
        errors.push(`Image validation error: ${error.message}`);
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }

  // Get file category
  getFileCategory(mimetype) {
    for (const [category, types] of Object.entries(this.config.allowedTypes)) {
      if (types.includes(mimetype)) {
        return category;
      }
    }
    return 'general';
  }

  // Check if MIME type is allowed
  isAllowedMimeType(mimetype) {
    for (const types of Object.values(this.config.allowedTypes)) {
      if (types.includes(mimetype)) {
        return true;
      }
    }
    return false;
  }

  // Format bytes to human readable
  formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }

  // Process secure file upload
  async processSecureUpload(file, options = {}) {
    const {
      userId = null,
      metadata = {},
      encrypt = this.config.encryptFiles,
      scan = this.config.scanForViruses,
      generateThumbnail = this.config.generateThumbnails
    } = options;

    try {
      const validation = this.validateFile(file);
      if (!validation.isValid) {
        throw new Error(`File validation failed: ${validation.errors.join(', ')}`);
      }

      this.updateUploadStats('validation', file.mimetype);

      // Generate secure filename
      const secureFilename = this.generateSecureFilename(file.originalname);

      // Generate file hash
      const fileHash = this.generateFileHash(file);

      // Scan for viruses/malware
      let scanResult = { clean: true };
      if (scan && validation.shouldScan) {
        scanResult = await this.virusScanner.scanFile(file);
        this.updateUploadStats('scan', file.mimetype);
        
        if (!scanResult.clean) {
          this.updateUploadStats('infected', file.mimetype);
          
          if (this.config.quarantineInfected) {
            await this.quarantineFile(file, scanResult.threats, userId);
          }
          
          throw new Error(`File rejected due to security threats: ${scanResult.threats.join(', ')}`);
        }
      }

      // Process file based on type
      const processedFile = await this.processFile(file, {
        encrypt,
        generateThumbnail,
        metadata,
        userId
      });

      // Store file information
      const fileInfo = await this.storeFileInfo(processedFile, {
        userId,
        originalName: file.originalname,
        validation,
        scanResult,
        hash: fileHash,
        metadata
      });

      this.updateUploadStats('success', file.mimetype);

      console.log(`File processed successfully: ${secureFilename} (${fileHash})`);
      return {
        success: true,
        fileInfo,
        processedFile,
        validation,
        scanResult
      };
    } catch (error) {
      this.updateUploadStats('blocked', file.mimetype);
      console.error('File upload processing error:', error);
      throw error;
    }
  }

  // Generate secure filename
  generateSecureFilename(originalName) {
    const extension = path.extname(originalName);
    const baseName = path.parse(originalName).name;
    
    let safeName = baseName
      .replace(/[^a-zA-Z0-9._-]/g, '_') // Replace special chars with underscore
      .replace(/_{2,}/g, '_') // Replace multiple underscores with single
      .replace(/^_+|_+$/g, ''); // Remove leading/trailing underscores
    
    if (this.config.randomizeNames) {
      const uuid = uuidv4().replace(/-/g, '').substring(0, 8);
      return `${uuid}_${safeName}${extension}`;
    }
    
    return `${safeName}${extension}`;
  }

  // Generate file hash
  generateFileHash(file) {
    const hash = crypto.createHash('sha256');
    hash.update(file.buffer || file.stream);
    return hash.digest('hex');
  }

  // Process file based on type
  async processFile(file, options = {}) {
    const { encrypt, generateThumbnail, metadata, userId } = options;
    
    const processedFile = {
      originalData: file,
      processed: false,
      encrypted: false,
      thumbnail: null,
      metadata: {
        ...metadata,
        originalName: file.originalname,
        originalSize: file.size,
        originalType: file.mimetype,
        processedAt: Date.now()
      }
    };

    try {
      // Process images
      if (file.mimetype.startsWith('image/') && this.config.processImages) {
        processedFile.thumbnail = await this.generateThumbnail(file.buffer);
        processedFile.metadata.width = file.mimetype.startsWith('image/') ? 
          (await sharp(file.buffer).metadata()).width : null;
        processedFile.metadata.height = file.mimetype.startsWith('image/') ? 
          (await sharp(file.buffer).metadata()).height : null;
      }

      // Encrypt file if required
      if (encrypt) {
        const encryptionResult = await this.encryptionService.encrypt(
          file.buffer.toString('base64'),
          await this.getFileEncryptionKey(userId)
        );
        
        processedFile.encryptedData = encryptionResult;
        processedFile.encrypted = true;
      }

      processedFile.processed = true;
      return processedFile;
    } catch (error) {
      console.error('File processing error:', error);
      throw error;
    }
  }

  // Generate thumbnail for images
  async generateThumbnail(imageBuffer) {
    try {
      const thumbnail = await sharp(imageBuffer)
        .resize(this.config.maxThumbnailSize, this.config.maxThumbnailSize, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .jpeg({ quality: 80 })
        .toBuffer();

      return thumbnail;
    } catch (error) {
      console.error('Thumbnail generation error:', error);
      return null;
    }
  }

  // Get file encryption key
  async getFileEncryptionKey(userId) {
    // This should integrate with your key management system
    const keyMaterial = `file_${userId || 'anonymous'}_${Date.now()}`;
    return crypto.createHash('sha256').update(keyMaterial).digest();
  }

  // Quarantine infected file
  async quarantineFile(file, threats, userId) {
    try {
      const quarantineId = uuidv4();
      const quarantineData = {
        id: quarantineId,
        originalName: file.originalname,
        fileData: file.buffer.toString('base64'),
        threats,
        userId,
        quarantinedAt: Date.now(),
        expiresAt: Date.now() + this.config.maxQuarantineRetention
      };

      const quarantineKey = `quarantine:${quarantineId}`;
      await fs.writeFile(
        path.join(process.cwd(), 'quarantine', quarantineId + '.json'),
        JSON.stringify(quarantineData, null, 2)
      );

      console.log(`File quarantined: ${quarantineId} due to threats: ${threats.join(', ')}`);
    } catch (error) {
      console.error('File quarantine error:', error);
    }
  }

  // Store file information in database
  async storeFileInfo(processedFile, options) {
    const {
      userId,
      originalName,
      validation,
      scanResult,
      hash,
      metadata
    } = options;

    const fileInfo = {
      id: uuidv4(),
      userId,
      originalName,
      secureName: this.generateSecureFilename(originalName),
      hash,
      type: processedFile.originalData.mimetype,
      size: processedFile.originalData.size,
      processed: processedFile.processed,
      encrypted: processedFile.encrypted,
      thumbnail: processedFile.thumbnail ? true : false,
      validation: {
        isValid: validation.isValid,
        errors: validation.errors,
        warnings: validation.warnings
      },
      security: {
        scanned: scanResult.scanned,
        clean: scanResult.clean,
        threats: scanResult.threats || []
      },
      metadata,
      uploadedAt: Date.now(),
      isActive: true
    };

    // In a real implementation, store this in your database
    // For now, we'll store it in memory and log it
    console.log('File info stored:', fileInfo.id);

    return fileInfo;
  }

  // Update upload statistics
  updateUploadStats(action, mimetype) {
    this.uploadStats.totalUploads++;
    
    switch (action) {
      case 'success':
        this.uploadStats.successfulUploads++;
        break;
      case 'blocked':
        this.uploadStats.blockedUploads++;
        break;
      case 'infected':
        this.uploadStats.infectedFiles++;
        break;
    }

    // Update file type statistics
    const category = this.getFileCategory(mimetype);
    this.uploadStats.fileTypes[category] = (this.uploadStats.fileTypes[category] || 0) + 1;
  }

  // Get upload statistics
  getUploadStats() {
    return {
      ...this.uploadStats,
      successRate: this.uploadStats.totalUploads > 0 ? 
        (this.uploadStats.successfulUploads / this.uploadStats.totalUploads * 100).toFixed(2) + '%' : '0%',
      infectedRate: this.uploadStats.successfulUploads > 0 ? 
        (this.uploadStats.infectedFiles / this.uploadStats.successfulUploads * 100).toFixed(2) + '%' : '0%'
    };
  }

  // Clean up old quarantined files
  async cleanupQuarantine() {
    try {
      const quarantineDir = path.join(process.cwd(), 'quarantine');
      const files = await fs.readdir(quarantineDir);
      const now = Date.now();
      let cleaned = 0;

      for (const file of files) {
        if (file.endsWith('.json')) {
          const filePath = path.join(quarantineDir, file);
          const data = JSON.parse(await fs.readFile(filePath, 'utf8'));
          
          if (now > data.expiresAt) {
            await fs.unlink(filePath);
            cleaned++;
          }
        }
      }

      console.log(`Cleaned up ${cleaned} quarantined files`);
      return cleaned;
    } catch (error) {
      console.error('Quarantine cleanup error:', error);
      return 0;
    }
  }

  // Health check for file upload security
  async healthCheck() {
    try {
      const stats = this.getUploadStats();
      
      return {
        healthy: true,
        totalUploads: stats.totalUploads,
        successRate: stats.successRate,
        infectedRate: stats.infectedRate,
        virusScannerStatus: await this.virusScanner.healthCheck()
      };
    } catch (error) {
      return {
        healthy: false,
        error: error.message
      };
    }
  }
}

module.exports = {
  FileUploadSecurity
};