const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const rateLimit = require('express-rate-limit');
const { authMiddleware } = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');
const { logAuthEvent } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window per IP
  message: {
    error: 'Too many authentication attempts, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false
});

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 login attempts per window per IP
  skipSuccessfulRequests: true,
  message: {
    error: 'Too many login attempts, please try again later.'
  }
});

// Generate JWT token
const generateToken = (user) => {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role,
      permissions: user.permissions || []
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRE || '24h',
      issuer: 'tutoring-platform',
      audience: 'tutoring-users'
    }
  );
};

// Generate refresh token
const generateRefreshToken = (user) => {
  return jwt.sign(
    {
      userId: user.id,
      type: 'refresh'
    },
    process.env.JWT_REFRESH_SECRET,
    {
      expiresIn: '7d',
      issuer: 'tutoring-platform',
      audience: 'tutoring-users'
    }
  );
};

// Register endpoint
router.post('/register', [
  authLimiter,
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
  body('firstName').isLength({ min: 2, max: 50 }).withMessage('First name must be between 2 and 50 characters'),
  body('lastName').isLength({ min: 2, max: 50 }).withMessage('Last name must be between 2 and 50 characters'),
  body('role').isIn(['student', 'tutor', 'admin']).withMessage('Role must be student, tutor, or admin'),
  body('phone').optional().isMobilePhone('any').withMessage('Please provide a valid phone number'),
  body('dateOfBirth').optional().isISO8601().withMessage('Date of birth must be a valid date')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, role, phone, dateOfBirth } = req.body;

    // Check if user already exists
    const existingUser = await databaseService.query(
      databaseService.queries.users.findByEmail,
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Generate user ID
    const userId = uuidv4();

    // Set default permissions based on role
    const defaultPermissions = {
      student: ['read_own_assignments', 'submit_assignments', 'chat'],
      tutor: ['create_assignments', 'grade_assignments', 'chat', 'schedule_sessions'],
      admin: ['full_access']
    };

    // Create user
    const user = await databaseService.query(
      databaseService.queries.users.create,
      [
        userId,
        email,
        hashedPassword,
        firstName,
        lastName,
        role,
        phone || null,
        null, // bio
        JSON.stringify([]), // subjects as JSON array
        'UTC', // default timezone
      ]
    );

    const userData = user.rows[0];

    // Generate tokens
    const token = generateToken(userData);
    const refreshToken = generateRefreshToken(userData);

    // Store refresh token in Redis
    await redisService.set(`refresh_token:${userId}`, refreshToken, 604800); // 7 days

    // Log registration
    logAuthEvent(userId, 'register', req.ip, req.get('User-Agent'), true, {
      email,
      role
    });

    // Return user data (without password)
    const { password: _, ...userWithoutPassword } = userData;

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: userWithoutPassword,
        token,
        refreshToken
      }
    });

  } catch (error) {
    logAuthEvent(null, 'register', req.ip, req.get('User-Agent'), false, {
      error: error.message,
      email: req.body.email
    });
    next(error);
  }
});

// Login endpoint
router.post('/login', [
  loginLimiter,
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password, rememberMe = false } = req.body;

    // Find user by email
    const userResult = await databaseService.query(
      databaseService.queries.users.findByEmail,
      [email]
    );

    if (userResult.rows.length === 0) {
      logAuthEvent(null, 'login', req.ip, req.get('User-Agent'), false, {
        email,
        reason: 'User not found'
      });

      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    const user = userResult.rows[0];

    // Check if user is active
    if (!user.is_active) {
      logAuthEvent(user.id, 'login', req.ip, req.get('User-Agent'), false, {
        email,
        reason: 'Account deactivated'
      });

      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      logAuthEvent(user.id, 'login', req.ip, req.get('User-Agent'), false, {
        email,
        reason: 'Invalid password'
      });

      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate tokens
    const token = generateToken(user);
    const refreshToken = generateRefreshToken(user);

    // Store refresh token in Redis with extended TTL if rememberMe
    const ttl = rememberMe ? 2592000 : 604800; // 30 days if rememberMe, 7 days otherwise
    await redisService.set(`refresh_token:${user.id}`, refreshToken, ttl);

    // Update last login
    await databaseService.query(
      'UPDATE users SET last_login = NOW() WHERE id = $1',
      [user.id]
    );

    // Log successful login
    logAuthEvent(user.id, 'login', req.ip, req.get('User-Agent'), true, {
      email,
      rememberMe
    });

    // Return user data (without password)
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userWithoutPassword,
        token,
        refreshToken
      }
    });

  } catch (error) {
    logAuthEvent(null, 'login', req.ip, req.get('User-Agent'), false, {
      error: error.message,
      email: req.body.email
    });
    next(error);
  }
});

// Refresh token endpoint
router.post('/refresh', [
  authLimiter,
  body('refreshToken').notEmpty().withMessage('Refresh token is required')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token type'
      });
    }

    // Check if refresh token exists in Redis
    const storedToken = await redisService.get(`refresh_token:${decoded.userId}`);

    if (storedToken !== refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Get user data
    const userResult = await databaseService.query(
      databaseService.queries.users.findById,
      [decoded.userId]
    );

    if (userResult.rows.length === 0 || !userResult.rows[0].is_active) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    const user = userResult.rows[0];

    // Generate new access token
    const newToken = generateToken(user);

    // Log token refresh
    logAuthEvent(user.id, 'token_refresh', req.ip, req.get('User-Agent'), true);

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      data: {
        token: newToken
      }
    });

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired refresh token'
      });
    }

    logAuthEvent(null, 'token_refresh', req.ip, req.get('User-Agent'), false, {
      error: error.message
    });

    next(error);
  }
});

// Logout endpoint
router.post('/logout', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.userId;

    // Remove refresh token from Redis
    await redisService.del(`refresh_token:${userId}`);

    // Log logout
    logAuthEvent(userId, 'logout', req.ip, req.get('User-Agent'), true);

    res.json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    logAuthEvent(req.user?.userId, 'logout', req.ip, req.get('User-Agent'), false, {
      error: error.message
    });
    next(error);
  }
});

// Logout from all devices
router.post('/logout-all', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.userId;

    // Remove all refresh tokens for the user
    await redisService.invalidatePattern(`refresh_token:${userId}`);

    // Log logout all
    logAuthEvent(userId, 'logout_all', req.ip, req.get('User-Agent'), true);

    res.json({
      success: true,
      message: 'Logged out from all devices successfully'
    });

  } catch (error) {
    logAuthEvent(req.user?.userId, 'logout_all', req.ip, req.get('User-Agent'), false, {
      error: error.message
    });
    next(error);
  }
});

// Verify token endpoint
router.get('/verify', authMiddleware, async (req, res, next) => {
  try {
    // Get fresh user data
    const userResult = await databaseService.query(
      databaseService.queries.users.findById,
      [req.user.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];

    // Return user data (without password)
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      data: {
        user: userWithoutPassword,
        tokenValid: true
      }
    });

  } catch (error) {
    next(error);
  }
});

// Forgot password endpoint
router.post('/forgot-password', [
  authLimiter,
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { email } = req.body;

    // Check if user exists
    const userResult = await databaseService.query(
      databaseService.queries.users.findByEmail,
      [email]
    );

    // Always return success to prevent email enumeration
    if (userResult.rows.length === 0) {
      return res.json({
        success: true,
        message: 'If the email exists, a password reset link has been sent'
      });
    }

    const user = userResult.rows[0];

    // Generate reset token
    const resetToken = jwt.sign(
      {
        userId: user.id,
        type: 'password_reset'
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '1h'
      }
    );

    // Store reset token in Redis
    await redisService.set(`reset_token:${user.id}`, resetToken, 3600); // 1 hour

    // TODO: Send email with reset link
    // await sendPasswordResetEmail(user.email, resetToken);

    logAuthEvent(user.id, 'password_reset_requested', req.ip, req.get('User-Agent'), true);

    res.json({
      success: true,
      message: 'If the email exists, a password reset link has been sent'
    });

  } catch (error) {
    logAuthEvent(null, 'password_reset_requested', req.ip, req.get('User-Agent'), false, {
      error: error.message,
      email: req.body.email
    });
    next(error);
  }
});

// Reset password endpoint
router.post('/reset-password', [
  authLimiter,
  body('token').notEmpty().withMessage('Reset token is required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { token, password } = req.body;

    // Verify reset token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.type !== 'password_reset') {
      return res.status(400).json({
        success: false,
        message: 'Invalid token type'
      });
    }

    // Check if reset token exists in Redis
    const storedToken = await redisService.get(`reset_token:${decoded.userId}`);

    if (storedToken !== token) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token'
      });
    }

    // Hash new password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Update password
    await databaseService.query(
      databaseService.queries.users.updatePassword,
      [decoded.userId, hashedPassword]
    );

    // Remove reset token
    await redisService.del(`reset_token:${decoded.userId}`);

    // Remove all refresh tokens (force re-login from all devices)
    await redisService.del(`refresh_token:${decoded.userId}`);

    logAuthEvent(decoded.userId, 'password_reset', req.ip, req.get('User-Agent'), true);

    res.json({
      success: true,
      message: 'Password reset successfully'
    });

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired reset token'
      });
    }

    logAuthEvent(null, 'password_reset', req.ip, req.get('User-Agent'), false, {
      error: error.message
    });
    next(error);
  }
});

module.exports = router;