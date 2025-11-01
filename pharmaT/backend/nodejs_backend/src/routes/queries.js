const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { handleValidationErrors, queryValidations, commonValidations } = require('../middleware/validation');
const { logger } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads/queries');
    try {
      await fs.mkdir(uploadDir, { recursive: true });
      cb(null, uploadDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `query_${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 20 * 1024 * 1024, // 20MB per file
    files: 5
  }
});

// Handle query file uploads
const handleQueryUpload = (req, res, next) => {
  const uploadMultiple = upload.array('attachments', 5);
  
  uploadMultiple(req, res, (error) => {
    if (error instanceof multer.MulterError) {
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File too large. Maximum size is 20MB per file.'
        });
      }
      if (error.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Maximum 5 files allowed.'
        });
      }
    }
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    
    if (req.files && req.files.length > 0) {
      req.attachmentFiles = req.files.map(file => ({
        id: uuidv4(),
        originalName: file.originalname,
        filename: file.filename,
        path: file.path,
        size: file.size,
        mimetype: file.mimetype,
        uploadedAt: new Date().toISOString()
      }));
    }
    
    next();
  });
};

// Create support query/ticket
router.post('/', [
  authMiddleware,
  handleQueryUpload,
  ...queryValidations.create
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { subject, description, priority, category } = req.body;
    const attachments = req.attachmentFiles || [];

    // Generate query ID
    const queryId = uuidv4();

    // Create query in database
    const result = await databaseService.query(
      databaseService.queries.queries.create,
      [
        queryId,
        userId,
        subject,
        description,
        priority,
        category,
        'open',
        JSON.stringify(attachments)
      ]
    );

    const query = result.rows[0];

    // Auto-assign to available support staff (simplified)
    // In a real implementation, this would use a more sophisticated assignment logic
    const supportStaffResult = await databaseService.query(
      'SELECT id FROM users WHERE role = $1 AND is_active = true LIMIT 1',
      ['admin']
    );

    if (supportStaffResult.rows.length > 0) {
      const assignedTo = supportStaffResult.rows[0].id;
      await databaseService.query(
        'UPDATE queries SET assigned_to = $1, status = $2 WHERE id = $3',
        [assignedTo, 'in_progress', queryId]
      );
    }

    logger.info('Support query created', {
      queryId,
      userId,
      subject,
      priority,
      category
    });

    res.status(201).json({
      success: true,
      message: 'Support query created successfully',
      data: { 
        query: {
          ...query,
          attachments: query.attachments ? JSON.parse(query.attachments) : []
        }
      }
    });

  } catch (error) {
    // Clean up uploaded files if query creation fails
    if (req.attachmentFiles) {
      for (const file of req.attachmentFiles) {
        try {
          await fs.unlink(file.path);
        } catch (unlinkError) {
          logger.error('Failed to clean up file:', unlinkError);
        }
      }
    }
    next(error);
  }
});

// Get user's queries
router.get('/', [
  authMiddleware,
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await databaseService.query(
      databaseService.queries.queries.findByUser,
      [userId, limit, offset]
    );

    const queries = result.rows.map(query => ({
      ...query,
      attachments: query.attachments ? JSON.parse(query.attachments) : []
    }));

    // Get total count
    const countResult = await databaseService.query(
      'SELECT COUNT(*) FROM queries WHERE user_id = $1',
      [userId]
    );

    const totalCount = parseInt(countResult.rows[0].count, 10);
    const totalPages = Math.ceil(totalCount / limit);

    res.json({
      success: true,
      data: {
        queries,
        pagination: {
          page: parseInt(page, 10),
          limit: parseInt(limit, 10),
          totalCount,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get all queries (Admin/Support only)
router.get('/all', [
  authMiddleware,
  requireRole(['admin']),
  ...commonValidations.validatePagination,
  query('status').optional().isIn(['open', 'in_progress', 'resolved', 'closed']),
  query('priority').optional().isIn(['low', 'medium', 'high', 'urgent']),
  query('category').optional().isString()
], handleValidationErrors, async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      priority,
      category,
      sort = 'created_at',
      order = 'desc'
    } = req.query;
    const offset = (page - 1) * limit;

    let query = databaseService.queries.queries.findAll;
    let params = [];

    // Add filters
    if (status || priority || category) {
      const conditions = [];
      if (status) {
        conditions.push('status = $1');
        params.push(status);
      }
      if (priority) {
        conditions.push('priority = $' + (params.length + 1));
        params.push(priority);
      }
      if (category) {
        conditions.push('category = $' + (params.length + 1));
        params.push(category);
      }
      query += ' AND ' + conditions.join(' AND ');
    }

    // Add sorting
    query += ` ORDER BY ${sort} ${order}`;
    query += ` LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await databaseService.query(query, params);

    const queries = result.rows.map(query => ({
      ...query,
      attachments: query.attachments ? JSON.parse(query.attachments) : []
    }));

    res.json({
      success: true,
      data: { queries }
    });

  } catch (error) {
    next(error);
  }
});

// Get specific query
router.get('/:id', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid query ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const queryId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;

    const result = await databaseService.query(
      databaseService.queries.queries.findById,
      [queryId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Query not found'
      });
    }

    const query = result.rows[0];

    // Check access permissions
    if (query.user_id !== userId && userRole !== 'admin' && query.assigned_to !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Get query comments
    const commentsResult = await databaseService.query(
      'SELECT qc.*, u.first_name, u.last_name, u.role FROM query_comments qc JOIN users u ON qc.user_id = u.id WHERE qc.query_id = $1 ORDER BY qc.created_at ASC',
      [queryId]
    );

    const processedQuery = {
      ...query,
      attachments: query.attachments ? JSON.parse(query.attachments) : [],
      comments: commentsResult.rows
    };

    res.json({
      success: true,
      data: { query: processedQuery }
    });

  } catch (error) {
    next(error);
  }
});

// Update query
router.put('/:id', [
  authMiddleware,
  ...queryValidations.update,
  param('id').isUUID().withMessage('Invalid query ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const queryId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;
    const { status, priority, assignedTo, resolution } = req.body;

    // Get existing query
    const existingResult = await databaseService.query(
      databaseService.queries.queries.findById,
      [queryId]
    );

    if (existingResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Query not found'
      });
    }

    const existingQuery = existingResult.rows[0];

    // Check permissions
    const canUpdate = existingQuery.user_id === userId || 
                     userRole === 'admin' || 
                     existingQuery.assigned_to === userId;

    if (!canUpdate) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Update query
    const result = await databaseService.query(
      databaseService.queries.queries.update,
      [
        queryId,
        existingQuery.subject,
        existingQuery.description,
        priority || existingQuery.priority,
        existingQuery.category,
        status || existingQuery.status,
        assignedTo || existingQuery.assigned_to,
        resolution || existingQuery.resolution
      ]
    );

    const updatedQuery = result.rows[0];

    logger.info('Query updated', {
      queryId,
      updatedBy: userId,
      updatedFields: Object.keys(req.body)
    });

    res.json({
      success: true,
      message: 'Query updated successfully',
      data: {
        query: {
          ...updatedQuery,
          attachments: updatedQuery.attachments ? JSON.parse(updatedQuery.attachments) : []
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Add comment to query
router.post('/:id/comments', [
  authMiddleware,
  body('comment').isLength({ min: 1, max: 1000 }).withMessage('Comment must be between 1 and 1000 characters'),
  body('isInternal').optional().isBoolean().withMessage('isInternal must be a boolean'),
  param('id').isUUID().withMessage('Invalid query ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const queryId = req.params.id;
    const userId = req.user.userId;
    const { comment, isInternal = false } = req.body;

    // Check if query exists and user has access
    const queryResult = await databaseService.query(
      databaseService.queries.queries.findById,
      [queryId]
    );

    if (queryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Query not found'
      });
    }

    const query = queryResult.rows[0];

    // Create comment
    const commentId = uuidv4();
    const result = await databaseService.query(
      databaseService.queries.queries.addComment,
      [commentId, queryId, userId, comment]
    );

    const newComment = result.rows[0];

    logger.info('Query comment added', {
      queryId,
      commentId,
      userId,
      isInternal
    });

    res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      data: { comment: newComment }
    });

  } catch (error) {
    next(error);
  }
});

// Delete query (Admin only)
router.delete('/:id', [
  authMiddleware,
  requireRole(['admin']),
  param('id').isUUID().withMessage('Invalid query ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const queryId = req.params.id;

    // Get query to delete files
    const queryResult = await databaseService.query(
      databaseService.queries.queries.findById,
      [queryId]
    );

    if (queryResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Query not found'
      });
    }

    const query = queryResult.rows[0];

    // Delete query files
    if (query.attachments) {
      const attachments = JSON.parse(query.attachments);
      for (const attachment of attachments) {
        try {
          await fs.unlink(attachment.path);
        } catch (fileError) {
          logger.warn('Failed to delete query file:', fileError);
        }
      }
    }

    // Delete from database
    await databaseService.query('DELETE FROM queries WHERE id = $1', [queryId]);

    logger.info('Query deleted by admin', {
      queryId,
      deletedBy: req.user.userId
    });

    res.json({
      success: true,
      message: 'Query deleted successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Get query statistics (Admin only)
router.get('/stats/overview', [
  authMiddleware,
  requireRole(['admin'])
], async (req, res, next) => {
  try {
    const cacheKey = 'stats:queries:overview';
    const cached = await redisService.get(cacheKey);
    
    if (cached) {
      return res.json({
        success: true,
        data: cached
      });
    }

    const statsQueries = [
      'SELECT COUNT(*) as total FROM queries',
      'SELECT COUNT(*) as open FROM queries WHERE status = $1',
      'SELECT COUNT(*) as in_progress FROM queries WHERE status = $1',
      'SELECT COUNT(*) as resolved FROM queries WHERE status = $1',
      'SELECT COUNT(*) as closed FROM queries WHERE status = $1',
      'SELECT COUNT(*) as overdue FROM queries WHERE priority IN ($1, $2) AND status IN ($3, $4) AND created_at < NOW() - INTERVAL $5'
    ];

    const [total, open, inProgress, resolved, closed, overdue] = await Promise.all([
      databaseService.query(statsQueries[0]),
      databaseService.query(statsQueries[1], ['open']),
      databaseService.query(statsQueries[2], ['in_progress']),
      databaseService.query(statsQueries[3], ['resolved']),
      databaseService.query(statsQueries[4], ['closed']),
      databaseService.query(statsQueries[5], ['high', 'urgent', 'open', 'in_progress', '48 hours'])
    ]);

    const stats = {
      total: parseInt(total.rows[0].total, 10),
      open: parseInt(open.rows[0].open, 10),
      inProgress: parseInt(inProgress.rows[0].in_progress, 10),
      resolved: parseInt(resolved.rows[0].resolved, 10),
      closed: parseInt(closed.rows[0].closed, 10),
      overdue: parseInt(overdue.rows[0].overdue, 10)
    };

    // Cache for 30 minutes
    await redisService.set(cacheKey, stats, 1800);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;