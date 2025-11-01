const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { body, param, validationResult } = require('express-validator');
const { authMiddleware } = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');
const { logger, logFileOperation } = require('../middleware/logger');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Configure multer
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads');
    try {
      await fs.mkdir(uploadDir, { recursive: true });
      cb(null, uploadDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    cb(null, `${name}_${uniqueSuffix}${ext}`);
  }
});

const fileFilter = (req, file, cb) => {
  // Allow images, documents, videos, and archives
  const allowedTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'text/csv',
    'video/mp4',
    'video/avi',
    'video/mov',
    'video/quicktime',
    'audio/mp3',
    'audio/wav',
    'audio/ogg',
    'application/zip',
    'application/x-zip-compressed'
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('File type not allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB
    files: 5
  }
});

// Single file upload
router.post('/single', [
  authMiddleware,
  body('purpose').optional().isString().withMessage('Purpose must be a string'),
  body('entityId').optional().isUUID().withMessage('Entity ID must be a valid UUID')
], upload.single('file'), handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { purpose = 'general', entityId } = req.body;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const file = req.file;

    // Save file record to database (simplified - would need actual database service)
    const fileRecord = {
      id: uuidv4(),
      userId,
      originalName: file.originalname,
      fileName: file.filename,
      filePath: file.path,
      fileSize: file.size,
      mimeType: file.mimetype,
      purpose,
      entityId,
      isPublic: false,
      uploadedAt: new Date().toISOString()
    };

    logFileOperation('upload', file.originalname, file.size, userId, true);

    res.json({
      success: true,
      message: 'File uploaded successfully',
      data: {
        file: fileRecord,
        downloadUrl: `/api/v1/uploads/${fileRecord.id}/download`
      }
    });

  } catch (error) {
    // Clean up uploaded file if database operation fails
    if (req.file) {
      try {
        await fs.unlink(req.file.path);
      } catch (unlinkError) {
        logger.error('Failed to clean up uploaded file:', unlinkError);
      }
    }
    next(error);
  }
});

// Multiple file upload
router.post('/multiple', [
  authMiddleware,
  body('purpose').optional().isString(),
  body('entityId').optional().isUUID()
], upload.array('files', 5), handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { purpose = 'general', entityId } = req.body;

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No files uploaded'
      });
    }

    const files = req.files.map(file => ({
      id: uuidv4(),
      userId,
      originalName: file.originalname,
      fileName: file.filename,
      filePath: file.path,
      fileSize: file.size,
      mimeType: file.mimetype,
      purpose,
      entityId,
      isPublic: false,
      uploadedAt: new Date().toISOString()
    }));

    logFileOperation('upload_multiple', `${req.files.length} files`, 
      req.files.reduce((sum, file) => sum + file.size, 0), userId, true);

    res.json({
      success: true,
      message: 'Files uploaded successfully',
      data: {
        files: files.map(file => ({
          ...file,
          downloadUrl: `/api/v1/uploads/${file.id}/download`
        }))
      }
    });

  } catch (error) {
    // Clean up uploaded files
    if (req.files) {
      for (const file of req.files) {
        try {
          await fs.unlink(file.path);
        } catch (unlinkError) {
          logger.error('Failed to clean up uploaded file:', unlinkError);
        }
      }
    }
    next(error);
  }
});

// Download file
router.get('/:fileId/download', [
  authMiddleware,
  param('fileId').isUUID().withMessage('Invalid file ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const fileId = req.params.fileId;

    // In a real implementation, you would fetch file record from database
    // For now, we'll simulate it
    // const fileRecord = await getFileRecord(fileId);

    // Check file permissions
    // if (!fileRecord.isPublic && fileRecord.userId !== req.user.userId && req.user.role !== 'admin') {
    //   return res.status(403).json({
    //     success: false,
    //     message: 'Access denied'
    //   });
    // }

    // Check if file exists (simplified)
    try {
      await fs.access('/path/to/uploaded/file'); // This would be fileRecord.filePath
    } catch (error) {
      return res.status(404).json({
        success: false,
        message: 'File not found'
      });
    }

    logFileOperation('download', 'filename', 0, req.user.userId, true);

    // res.download(fileRecord.filePath, fileRecord.originalName);
    res.json({
      success: true,
      message: 'File download endpoint'
    });

  } catch (error) {
    next(error);
  }
});

// Delete file
router.delete('/:fileId', [
  authMiddleware,
  param('fileId').isUUID().withMessage('Invalid file ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const fileId = req.params.fileId;

    // In a real implementation:
    // 1. Fetch file record from database
    // 2. Check permissions
    // 3. Delete file from disk
    // 4. Remove record from database

    logFileOperation('delete', 'filename', 0, req.user.userId, true);

    res.json({
      success: true,
      message: 'File deleted successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Get file information
router.get('/:fileId', [
  authMiddleware,
  param('fileId').isUUID().withMessage('Invalid file ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const fileId = req.params.fileId;

    // In a real implementation, fetch from database
    // const fileRecord = await getFileRecord(fileId);

    res.json({
      success: true,
      data: {
        file: {
          id: fileId,
          // ...file details
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;