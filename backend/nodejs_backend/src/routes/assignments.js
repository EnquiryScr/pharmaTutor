const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { handleValidationErrors, assignmentValidations, commonValidations } = require('../middleware/validation');
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
    const uploadDir = path.join(__dirname, '../../uploads/assignments');
    try {
      await fs.mkdir(uploadDir, { recursive: true });
      cb(null, uploadDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `assignment_${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'image/jpeg',
    'image/png',
    'image/gif',
    'video/mp4',
    'video/avi',
    'video/mov',
    'application/zip',
    'application/x-zip-compressed'
  ];

  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only PDF, DOC, DOCX, TXT, images, videos, and ZIP files are allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB per file
    files: 10 // Maximum 10 files per request
  }
});

// Middleware to handle assignment file uploads
const handleAssignmentUpload = (req, res, next) => {
  const uploadMultiple = upload.array('attachments', 10);
  
  uploadMultiple(req, res, (error) => {
    if (error instanceof multer.MulterError) {
      if (error.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
          success: false,
          message: 'File too large. Maximum size is 50MB per file.'
        });
      }
      if (error.code === 'LIMIT_FILE_COUNT') {
        return res.status(400).json({
          success: false,
          message: 'Too many files. Maximum 10 files allowed.'
        });
      }
    }
    
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.message
      });
    }
    
    // Process uploaded files
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

// Create assignment
router.post('/', [
  authMiddleware,
  requireRole(['tutor', 'admin']),
  handleAssignmentUpload,
  ...assignmentValidations.create
], handleValidationErrors, async (req, res, next) => {
  try {
    const tutorId = req.user.userId;
    const {
      title,
      description,
      subject,
      gradeLevel,
      deadline,
      instructions,
      attachments: existingAttachments = [],
      maxAttempts = 1,
      timeLimit,
      rubric
    } = req.body;

    // Process attachments
    const allAttachments = [
      ...existingAttachments,
      ...(req.attachmentFiles || [])
    ];

    // Generate assignment ID
    const assignmentId = uuidv4();

    // Create assignment in database
    const result = await databaseService.query(
      databaseService.queries.assignments.create,
      [
        assignmentId,
        tutorId,
        title,
        description,
        subject,
        gradeLevel,
        new Date(deadline),
        JSON.stringify(allAttachments),
        'draft',
      ]
    );

    const assignment = result.rows[0];

    // Cache assignment data
    await redisService.set(`assignment:${assignmentId}`, assignment, 3600);

    logger.info('Assignment created', {
      assignmentId,
      tutorId,
      subject,
      gradeLevel,
      deadline
    });

    res.status(201).json({
      success: true,
      message: 'Assignment created successfully',
      data: { assignment }
    });

  } catch (error) {
    // Clean up uploaded files if assignment creation fails
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

// Get assignments (with filtering and pagination)
router.get('/', [
  authMiddleware,
  ...commonValidations.validatePagination,
  query('subject').optional().isString(),
  query('gradeLevel').optional().isIn(['elementary', 'middle', 'high', 'college', 'graduate']),
  query('status').optional().isIn(['draft', 'published', 'closed']),
  query('search').optional().isLength({ min: 1, max: 100 })
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const userRole = req.user.role;
    const {
      page = 1,
      limit = 20,
      subject,
      gradeLevel,
      status,
      search,
      sort = 'created_at',
      order = 'desc'
    } = req.query;
    
    const offset = (page - 1) * limit;

    let query = '';
    let params = [];
    let paramCount = 1;

    if (userRole === 'tutor') {
      query = databaseService.queries.assignments.findByTutor;
      params = [userId, limit, offset];
    } else if (userRole === 'student') {
      query = databaseService.queries.assignments.findByStudent;
      params = [userId, limit, offset];
    } else {
      query = 'SELECT * FROM assignments ORDER BY created_at DESC LIMIT $1 OFFSET $2';
      params = [limit, offset];
    }

    // Add filters
    let whereConditions = [];
    
    if (subject) {
      whereConditions.push(`subject = $${paramCount}`);
      params.push(subject);
      paramCount++;
    }
    
    if (gradeLevel) {
      whereConditions.push(`grade_level = $${paramCount}`);
      params.push(gradeLevel);
      paramCount++;
    }
    
    if (status) {
      whereConditions.push(`status = $${paramCount}`);
      params.push(status);
      paramCount++;
    }
    
    if (search) {
      whereConditions.push(`(title ILIKE $${paramCount} OR description ILIKE $${paramCount})`);
      params.push(`%${search}%`);
      paramCount++;
    }

    if (whereConditions.length > 0) {
      query = query.replace('ORDER BY', `WHERE ${whereConditions.join(' AND ')} ORDER BY`);
    }

    // Add sorting
    const validSortFields = ['title', 'created_at', 'deadline', 'grade_level', 'subject'];
    const validOrders = ['asc', 'desc'];
    
    const sortField = validSortFields.includes(sort) ? sort : 'created_at';
    const sortOrder = validOrders.includes(order.toLowerCase()) ? order.toLowerCase() : 'desc';
    
    query += ` ${sort === 'created_at' ? '' : `ORDER BY ${sortField} ${sortOrder}`}`;

    // Update query with limit and offset
    query += ` LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await databaseService.query(query, params);

    // Parse attachments JSON for each assignment
    const assignments = result.rows.map(assignment => ({
      ...assignment,
      attachments: assignment.attachments ? JSON.parse(assignment.attachments) : [],
      submissionAttachments: assignment.submission_attachments ? JSON.parse(assignment.submission_attachments) : [],
      rubricScores: assignment.rubric_scores ? JSON.parse(assignment.rubric_scores) : null
    }));

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) FROM assignments';
    let countParams = [];
    let countParamCount = 1;

    if (userRole === 'tutor') {
      countQuery += ' WHERE tutor_id = $1';
      countParams = [userId];
    } else if (userRole === 'student') {
      countQuery += ' WHERE student_id = $1';
      countParams = [userId];
    }

    // Add same filters to count query
    if (whereConditions.length > 0) {
      countQuery += (userRole === 'tutor' || userRole === 'student') ? ' AND ' : ' WHERE ';
      countQuery += whereConditions.join(' AND ');
      countParams = [...countParams, ...params.slice(0, whereConditions.length)];
    }

    const countResult = await databaseService.query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count, 10);
    const totalPages = Math.ceil(totalCount / limit);

    res.json({
      success: true,
      data: {
        assignments,
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

// Get specific assignment by ID
router.get('/:id', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid assignment ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const assignmentId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Check cache first
    const cached = await redisService.get(`assignment:${assignmentId}`);
    if (cached) {
      // Check if user has access to this assignment
      if (cached.tutor_id !== userId && cached.student_id !== userId && userRole !== 'admin') {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }
      
      return res.json({
        success: true,
        data: {
          assignment: {
            ...cached,
            attachments: cached.attachments || [],
            submissionAttachments: cached.submission_attachments || [],
            rubricScores: cached.rubric_scores || null
          }
        }
      });
    }

    // Fetch from database
    const result = await databaseService.query(
      databaseService.queries.assignments.findById,
      [assignmentId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    const assignment = result.rows[0];

    // Check access permissions
    if (assignment.tutor_id !== userId && assignment.student_id !== userId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Parse JSON fields
    const processedAssignment = {
      ...assignment,
      attachments: assignment.attachments ? JSON.parse(assignment.attachments) : [],
      submissionAttachments: assignment.submission_attachments ? JSON.parse(assignment.submission_attachments) : [],
      rubricScores: assignment.rubric_scores ? JSON.parse(assignment.rubric_scores) : null
    };

    // Cache the assignment
    await redisService.set(`assignment:${assignmentId}`, assignment, 3600);

    res.json({
      success: true,
      data: { assignment: processedAssignment }
    });

  } catch (error) {
    next(error);
  }
});

// Update assignment
router.put('/:id', [
  authMiddleware,
  requireRole(['tutor', 'admin']),
  handleAssignmentUpload,
  param('id').isUUID().withMessage('Invalid assignment ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const assignmentId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Get existing assignment
    const existingResult = await databaseService.query(
      databaseService.queries.assignments.findById,
      [assignmentId]
    );

    if (existingResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    const existingAssignment = existingResult.rows[0];

    // Check permissions
    if (existingAssignment.tutor_id !== userId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const {
      title,
      description,
      subject,
      gradeLevel,
      deadline,
      instructions,
      attachments: existingAttachments = [],
      maxAttempts,
      timeLimit,
      rubric,
      status
    } = req.body;

    // Process attachments
    const allAttachments = [
      ...existingAttachments,
      ...(req.attachmentFiles || [])
    ];

    // Update assignment
    const result = await databaseService.query(
      databaseService.queries.assignments.update,
      [
        assignmentId,
        title || existingAssignment.title,
        description || existingAssignment.description,
        subject || existingAssignment.subject,
        gradeLevel || existingAssignment.grade_level,
        deadline ? new Date(deadline) : existingAssignment.deadline,
        JSON.stringify(allAttachments)
      ]
    );

    const updatedAssignment = result.rows[0];

    // Update cache
    await redisService.set(`assignment:${assignmentId}`, updatedAssignment, 3600);

    // Notify student if assignment status changed to published
    if (updatedAssignment.status === 'published' && updatedAssignment.student_id) {
      // Socket notification would be sent here
      logger.info('Assignment published, student notified', {
        assignmentId,
        studentId: updatedAssignment.student_id,
        tutorId: userId
      });
    }

    logger.info('Assignment updated', {
      assignmentId,
      tutorId: userId,
      updatedFields: Object.keys(req.body)
    });

    res.json({
      success: true,
      message: 'Assignment updated successfully',
      data: {
        assignment: {
          ...updatedAssignment,
          attachments: updatedAssignment.attachments ? JSON.parse(updatedAssignment.attachments) : []
        }
      }
    });

  } catch (error) {
    // Clean up uploaded files if update fails
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

// Submit assignment
router.post('/:id/submit', [
  authMiddleware,
  requireRole(['student', 'admin']),
  handleAssignmentUpload,
  param('id').isUUID().withMessage('Invalid assignment ID'),
  ...assignmentValidations.submit
], handleValidationErrors, async (req, res, next) => {
  try {
    const assignmentId = req.params.id;
    const userId = req.user.userId;
    const { content, notes } = req.body;

    // Get assignment to check submission status
    const assignmentResult = await databaseService.query(
      databaseService.queries.assignments.findById,
      [assignmentId]
    );

    if (assignmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    const assignment = assignmentResult.rows[0];

    // Check if assignment is assigned to this student
    if (assignment.student_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'This assignment is not assigned to you'
      });
    }

    // Check if assignment is already submitted
    if (assignment.status === 'submitted' || assignment.status === 'graded') {
      return res.status(400).json({
        success: false,
        message: 'Assignment has already been submitted'
      });
    }

    // Process file attachments
    const fileAttachments = req.attachmentFiles ? req.attachmentFiles.map(file => ({
      id: uuidv4(),
      originalName: file.originalname,
      filename: file.filename,
      path: file.path,
      size: file.size,
      mimetype: file.mimetype,
      uploadedAt: new Date().toISOString()
    })) : [];

    // Submit assignment
    const result = await databaseService.query(
      databaseService.queries.assignments.submit,
      [
        assignmentId,
        userId,
        content || null,
        JSON.stringify(fileAttachments),
        'submitted'
      ]
    );

    const submittedAssignment = result.rows[0];

    // Clear cache
    await redisService.del(`assignment:${assignmentId}`);

    // Notify tutor about submission
    logger.info('Assignment submitted', {
      assignmentId,
      studentId: userId,
      tutorId: assignment.tutor_id,
      hasContent: !!content,
      fileCount: fileAttachments.length
    });

    res.json({
      success: true,
      message: 'Assignment submitted successfully',
      data: {
        assignment: {
          ...submittedAssignment,
          attachments: submittedAssignment.attachments ? JSON.parse(submittedAssignment.attachments) : [],
          submissionAttachments: submittedAssignment.submission_attachments ? JSON.parse(submittedAssignment.submission_attachments) : []
        }
      }
    });

  } catch (error) {
    // Clean up uploaded files if submission fails
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

// Grade assignment
router.post('/:id/grade', [
  authMiddleware,
  requireRole(['tutor', 'admin']),
  param('id').isUUID().withMessage('Invalid assignment ID'),
  ...assignmentValidations.grade
], handleValidationErrors, async (req, res, next) => {
  try {
    const assignmentId = req.params.id;
    const userId = req.user.userId;
    const { grade, feedback, rubricScores = {}, isFinal = true } = req.body;

    // Get assignment
    const assignmentResult = await databaseService.query(
      databaseService.queries.assignments.findById,
      [assignmentId]
    );

    if (assignmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    const assignment = assignmentResult.rows[0];

    // Check permissions
    if (assignment.tutor_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Check if assignment is submitted
    if (assignment.status !== 'submitted') {
      return res.status(400).json({
        success: false,
        message: 'Cannot grade an assignment that is not submitted'
      });
    }

    // Grade assignment
    const result = await databaseService.query(
      databaseService.queries.assignments.grade,
      [
        assignmentId,
        grade,
        feedback,
        JSON.stringify(rubricScores),
        isFinal ? 'graded' : 'in_review'
      ]
    );

    const gradedAssignment = result.rows[0];

    // Clear cache
    await redisService.del(`assignment:${assignmentId}`);

    // Notify student about grade
    if (assignment.student_id) {
      logger.info('Assignment graded, student notified', {
        assignmentId,
        tutorId: userId,
        studentId: assignment.student_id,
        grade
      });
    }

    res.json({
      success: true,
      message: 'Assignment graded successfully',
      data: {
        assignment: {
          ...gradedAssignment,
          attachments: gradedAssignment.attachments ? JSON.parse(gradedAssignment.attachments) : [],
          submissionAttachments: gradedAssignment.submission_attachments ? JSON.parse(gradedAssignment.submission_attachments) : [],
          rubricScores: gradedAssignment.rubric_scores ? JSON.parse(gradedAssignment.rubric_scores) : null
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Delete assignment
router.delete('/:id', [
  authMiddleware,
  requireRole(['tutor', 'admin']),
  param('id').isUUID().withMessage('Invalid assignment ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const assignmentId = req.params.id;
    const userId = req.user.userId;
    const userRole = req.user.role;

    // Get assignment
    const assignmentResult = await databaseService.query(
      databaseService.queries.assignments.findById,
      [assignmentId]
    );

    if (assignmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    const assignment = assignmentResult.rows[0];

    // Check permissions
    if (assignment.tutor_id !== userId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Delete assignment files
    if (assignment.attachments) {
      const attachments = JSON.parse(assignment.attachments);
      for (const attachment of attachments) {
        try {
          await fs.unlink(attachment.path);
        } catch (fileError) {
          logger.warn('Failed to delete assignment file:', fileError);
        }
      }
    }

    // Delete submission files
    if (assignment.submission_attachments) {
      const submissionAttachments = JSON.parse(assignment.submission_attachments);
      for (const attachment of submissionAttachments) {
        try {
          await fs.unlink(attachment.path);
        } catch (fileError) {
          logger.warn('Failed to delete submission file:', fileError);
        }
      }
    }

    // Delete from database
    await databaseService.query(
      databaseService.queries.assignments.delete,
      [assignmentId]
    );

    // Clear cache
    await redisService.del(`assignment:${assignmentId}`);

    logger.info('Assignment deleted', {
      assignmentId,
      deletedBy: userId,
      hadSubmissions: !!assignment.submission_attachments
    });

    res.json({
      success: true,
      message: 'Assignment deleted successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Download assignment attachment
router.get('/:id/attachments/:attachmentId/download', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid assignment ID'),
  param('attachmentId').isUUID().withMessage('Invalid attachment ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const assignmentId = req.params.id;
    const attachmentId = req.params.attachmentId;
    const userId = req.user.userId;

    // Get assignment
    const assignmentResult = await databaseService.query(
      databaseService.queries.assignments.findById,
      [assignmentId]
    );

    if (assignmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Assignment not found'
      });
    }

    const assignment = assignmentResult.rows[0];

    // Check access permissions
    if (assignment.tutor_id !== userId && assignment.student_id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Find attachment
    const attachments = assignment.attachments ? JSON.parse(assignment.attachments) : [];
    const attachment = attachments.find(att => att.id === attachmentId);

    if (!attachment) {
      return res.status(404).json({
        success: false,
        message: 'Attachment not found'
      });
    }

    // Check if file exists
    try {
      await fs.access(attachment.path);
    } catch (error) {
      return res.status(404).json({
        success: false,
        message: 'File not found on server'
      });
    }

    // Log file download
    logger.info('Assignment attachment downloaded', {
      assignmentId,
      attachmentId,
      fileName: attachment.originalName,
      downloadedBy: userId
    });

    // Send file
    res.download(attachment.path, attachment.originalName);

  } catch (error) {
    next(error);
  }
});

// Get assignment statistics (for tutors and admins)
router.get('/stats/overview', [
  authMiddleware,
  requireRole(['tutor', 'admin'])
], async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const userRole = req.user.role;
    
    const cacheKey = `stats:assignments:${userId}`;
    const cached = await redisService.get(cacheKey);
    
    if (cached) {
      return res.json({
        success: true,
        data: cached
      });
    }

    let query = '';
    let params = [];

    if (userRole === 'tutor') {
      query = `
        SELECT 
          COUNT(*) as total_assignments,
          COUNT(CASE WHEN status = 'published' THEN 1 END) as published,
          COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft,
          COUNT(CASE WHEN status = 'submitted' THEN 1 END) as submitted,
          COUNT(CASE WHEN status = 'graded' THEN 1 END) as graded,
          COUNT(CASE WHEN submission_deadline < NOW() AND status NOT IN ('graded', 'closed') THEN 1 END) as overdue,
          AVG(CASE WHEN grade IS NOT NULL THEN grade END) as average_grade
        FROM assignments 
        WHERE tutor_id = $1
      `;
      params = [userId];
    } else {
      query = `
        SELECT 
          COUNT(*) as total_assignments,
          COUNT(CASE WHEN status = 'submitted' THEN 1 END) as submitted,
          COUNT(CASE WHEN status = 'graded' THEN 1 END) as graded,
          COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft,
          COUNT(CASE WHEN submission_deadline < NOW() AND status NOT IN ('graded', 'closed') THEN 1 END) as overdue,
          AVG(CASE WHEN grade IS NOT NULL THEN grade END) as average_grade
        FROM assignments 
        WHERE student_id = $1
      `;
      params = [userId];
    }

    const result = await databaseService.query(query, params);
    const stats = result.rows[0];

    // Convert string numbers to integers
    Object.keys(stats).forEach(key => {
      if (stats[key] !== null) {
        stats[key] = parseFloat(stats[key]);
      }
    });

    // Cache for 1 hour
    await redisService.set(cacheKey, stats, 3600);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;