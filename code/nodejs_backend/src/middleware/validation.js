const { body, param, query, validationResult } = require('express-validator');
const { AppError } = require('./errorHandler');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(error => ({
      field: error.param,
      message: error.msg,
      value: error.value
    }));
    
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: formattedErrors
    });
  }
  
  next();
};

// Validate request middleware
const validateRequest = (req, res, next) => {
  // Sanitize input
  if (req.body) {
    Object.keys(req.body).forEach(key => {
      if (typeof req.body[key] === 'string') {
        req.body[key] = req.body[key].trim();
      }
    });
  }
  
  if (req.query) {
    Object.keys(req.query).forEach(key => {
      if (typeof req.query[key] === 'string') {
        req.query[key] = req.query[key].trim();
      }
    });
  }
  
  next();
};

// Common validation rules
const commonValidations = {
  // ID validation
  validateId: [
    param('id').isMongoId().withMessage('Invalid ID format')
  ],
  
  // Pagination validation
  validatePagination: [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('sort').optional().isString().withMessage('Sort must be a string'),
    query('order').optional().isIn(['asc', 'desc', 'ascending', 'descending']).withMessage('Order must be asc or desc')
  ],
  
  // Search validation
  validateSearch: [
    query('search').optional().isLength({ min: 1, max: 100 }).withMessage('Search term must be between 1 and 100 characters'),
    query('filters').optional().isJSON().withMessage('Filters must be a valid JSON')
  ]
};

// User validations
const userValidations = {
  register: [
    body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
    body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
      .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
    body('firstName').isLength({ min: 2, max: 50 }).withMessage('First name must be between 2 and 50 characters'),
    body('lastName').isLength({ min: 2, max: 50 }).withMessage('Last name must be between 2 and 50 characters'),
    body('role').isIn(['student', 'tutor', 'admin']).withMessage('Role must be student, tutor, or admin'),
    body('phone').optional().isMobilePhone('any').withMessage('Please provide a valid phone number'),
    body('dateOfBirth').optional().isISO8601().withMessage('Date of birth must be a valid date')
  ],
  
  login: [
    body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
    body('password').notEmpty().withMessage('Password is required')
  ],
  
  updateProfile: [
    body('firstName').optional().isLength({ min: 2, max: 50 }).withMessage('First name must be between 2 and 50 characters'),
    body('lastName').optional().isLength({ min: 2, max: 50 }).withMessage('Last name must be between 2 and 50 characters'),
    body('phone').optional().isMobilePhone('any').withMessage('Please provide a valid phone number'),
    body('bio').optional().isLength({ max: 500 }).withMessage('Bio must be less than 500 characters'),
    body('subjects').optional().isArray().withMessage('Subjects must be an array'),
    body('subjects.*').optional().isString().withMessage('Each subject must be a string'),
    body('timezone').optional().isString().withMessage('Timezone must be a string'),
    body('availability').optional().isObject().withMessage('Availability must be an object')
  ]
};

// Assignment validations
const assignmentValidations = {
  create: [
    body('title').isLength({ min: 3, max: 200 }).withMessage('Title must be between 3 and 200 characters'),
    body('description').isLength({ min: 10, max: 2000 }).withMessage('Description must be between 10 and 2000 characters'),
    body('subject').isString().withMessage('Subject is required'),
    body('gradeLevel').isIn(['elementary', 'middle', 'high', 'college', 'graduate']).withMessage('Invalid grade level'),
    body('deadline').isISO8601().withMessage('Deadline must be a valid date'),
    body('attachments').optional().isArray().withMessage('Attachments must be an array'),
    body('attachments.*').optional().isString().withMessage('Each attachment must be a string')
  ],
  
  submit: [
    body('content').optional().isLength({ min: 1, max: 10000 }).withMessage('Content must be between 1 and 10000 characters'),
    body('attachments').optional().isArray().withMessage('Attachments must be an array'),
    body('attachments.*').optional().isString().withMessage('Each attachment must be a string')
  ],
  
  grade: [
    body('grade').isFloat({ min: 0, max: 100 }).withMessage('Grade must be between 0 and 100'),
    body('feedback').isLength({ min: 1, max: 2000 }).withMessage('Feedback must be between 1 and 2000 characters'),
    body('rubricScores').optional().isObject().withMessage('Rubric scores must be an object')
  ]
};

// Query/Ticket validations
const queryValidations = {
  create: [
    body('subject').isLength({ min: 3, max: 200 }).withMessage('Subject must be between 3 and 200 characters'),
    body('description').isLength({ min: 10, max: 2000 }).withMessage('Description must be between 10 and 2000 characters'),
    body('priority').isIn(['low', 'medium', 'high', 'urgent']).withMessage('Priority must be low, medium, high, or urgent'),
    body('category').isString().withMessage('Category is required'),
    body('attachments').optional().isArray().withMessage('Attachments must be an array')
  ],
  
  update: [
    body('status').optional().isIn(['open', 'in_progress', 'resolved', 'closed']).withMessage('Invalid status'),
    body('priority').optional().isIn(['low', 'medium', 'high', 'urgent']).withMessage('Invalid priority'),
    body('assignedTo').optional().isMongoId().withMessage('Invalid assigned user ID'),
    body('resolution').optional().isLength({ min: 1, max: 1000 }).withMessage('Resolution must be between 1 and 1000 characters')
  ]
};

// Chat/Messaging validations
const chatValidations = {
  sendMessage: [
    body('recipientId').isMongoId().withMessage('Invalid recipient ID'),
    body('message').isLength({ min: 1, max: 2000 }).withMessage('Message must be between 1 and 2000 characters'),
    body('type').optional().isIn(['text', 'file', 'image', 'audio', 'video']).withMessage('Invalid message type'),
    body('attachments').optional().isArray().withMessage('Attachments must be an array')
  ],
  
  createRoom: [
    body('name').isLength({ min: 3, max: 100 }).withMessage('Room name must be between 3 and 100 characters'),
    body('type').isIn(['private', 'group']).withMessage('Room type must be private or group'),
    body('participants').isArray({ min: 1 }).withMessage('At least one participant is required'),
    body('participants.*').isMongoId().withMessage('Each participant must have a valid ID')
  ]
};

// Article validations
const articleValidations = {
  create: [
    body('title').isLength({ min: 3, max: 200 }).withMessage('Title must be between 3 and 200 characters'),
    body('content').isLength({ min: 10, max: 10000 }).withMessage('Content must be between 10 and 10000 characters'),
    body('summary').optional().isLength({ max: 500 }).withMessage('Summary must be less than 500 characters'),
    body('tags').optional().isArray().withMessage('Tags must be an array'),
    body('tags.*').optional().isString().withMessage('Each tag must be a string'),
    body('category').isString().withMessage('Category is required'),
    body('difficultyLevel').optional().isIn(['beginner', 'intermediate', 'advanced']).withMessage('Invalid difficulty level'),
    body('estimatedReadTime').optional().isInt({ min: 1 }).withMessage('Estimated read time must be a positive integer')
  ]
};

// Schedule validations
const scheduleValidations = {
  createAppointment: [
    body('tutorId').isMongoId().withMessage('Invalid tutor ID'),
    body('startTime').isISO8601().withMessage('Start time must be a valid date'),
    body('endTime').isISO8601().withMessage('End time must be a valid date'),
    body('subject').isString().withMessage('Subject is required'),
    body('notes').optional().isLength({ max: 500 }).withMessage('Notes must be less than 500 characters'),
    body('meetingLink').optional().isURL().withMessage('Meeting link must be a valid URL')
  ],
  
  updateAvailability: [
    body('date').isISO8601().withMessage('Date must be a valid date'),
    body('timeSlots').isArray().withMessage('Time slots must be an array'),
    body('timeSlots.*.start').isString().withMessage('Start time is required'),
    body('timeSlots.*.end').isString().withMessage('End time is required'),
    body('timeSlots.*.isAvailable').isBoolean().withMessage('Availability status must be boolean')
  ]
};

// Payment validations
const paymentValidations = {
  createPaymentIntent: [
    body('amount').isInt({ min: 100 }).withMessage('Amount must be at least 100 cents ($1.00)'),
    body('currency').isIn(['usd', 'eur', 'gbp']).withMessage('Currency must be USD, EUR, or GBP'),
    body('description').optional().isLength({ max: 200 }).withMessage('Description must be less than 200 characters'),
    body('appointmentId').optional().isMongoId().withMessage('Invalid appointment ID'),
    body('metadata').optional().isObject().withMessage('Metadata must be an object')
  ]
};

module.exports = {
  handleValidationErrors,
  validateRequest,
  commonValidations,
  userValidations,
  assignmentValidations,
  queryValidations,
  chatValidations,
  articleValidations,
  scheduleValidations,
  paymentValidations
};