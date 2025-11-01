const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware, requireRole, requirePermission } = require('../middleware/auth');
const { handleValidationErrors, commonValidations } = require('../middleware/validation');
const { logger } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Get current user profile
router.get('/profile', 
  authMiddleware,
  async (req, res, next) => {
    try {
      const userId = req.user.userId;

      // Try to get from cache first
      const cached = await redisService.get(`user:${userId}`);
      if (cached) {
        return res.json({
          success: true,
          data: { user: cached }
        });
      }

      // Fetch from database
      const userResult = await databaseService.query(
        databaseService.queries.users.findById,
        [userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      const user = userResult.rows[0];

      // Remove sensitive data
      const { password, ...userWithoutPassword } = user;

      // Cache the result
      await redisService.set(`user:${userId}`, userWithoutPassword, 3600); // 1 hour

      res.json({
        success: true,
        data: { user: userWithoutPassword }
      });

    } catch (error) {
      next(error);
    }
  }
);

// Update user profile
router.put('/profile', [
  authMiddleware,
  body('firstName').optional().isLength({ min: 2, max: 50 }).withMessage('First name must be between 2 and 50 characters'),
  body('lastName').optional().isLength({ min: 2, max: 50 }).withMessage('Last name must be between 2 and 50 characters'),
  body('phone').optional().isMobilePhone('any').withMessage('Please provide a valid phone number'),
  body('bio').optional().isLength({ max: 500 }).withMessage('Bio must be less than 500 characters'),
  body('subjects').optional().isArray().withMessage('Subjects must be an array'),
  body('subjects.*').optional().isString().withMessage('Each subject must be a string'),
  body('timezone').optional().isString().withMessage('Timezone must be a string'),
  body('availability').optional().isObject().withMessage('Availability must be an object'),
  body('profileImage').optional().isURL().withMessage('Profile image must be a valid URL')
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const updates = req.body;

    // Build dynamic update query
    const allowedFields = ['firstName', 'lastName', 'phone', 'bio', 'subjects', 'timezone', 'availability', 'profileImage'];
    const setClause = [];
    const values = [];
    let paramCount = 1;

    for (const [field, value] of Object.entries(updates)) {
      if (allowedFields.includes(field)) {
        setClause.push(`${field.replace(/([A-Z])/g, '_$1').toLowerCase()} = $${paramCount}`);
        values.push(field === 'subjects' || field === 'availability' ? JSON.stringify(value) : value);
        paramCount++;
      }
    }

    if (setClause.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    setClause.push(`updated_at = NOW()`);
    values.push(userId);

    const updateQuery = `
      UPDATE users 
      SET ${setClause.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await databaseService.query(updateQuery, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const updatedUser = result.rows[0];
    const { password, ...userWithoutPassword } = updatedUser;

    // Update cache
    await redisService.set(`user:${userId}`, userWithoutPassword, 3600);

    // Invalidate any related cache
    await redisService.invalidatePattern(`users:${updatedUser.role}:*`);

    logger.info('User profile updated', { userId, updatedFields: Object.keys(updates) });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: { user: userWithoutPassword }
    });

  } catch (error) {
    next(error);
  }
});

// Change password
router.put('/change-password', [
  authMiddleware,
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 8 }).withMessage('New password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('New password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
  body('confirmPassword').custom((value, { req }) => {
    if (value !== req.body.newPassword) {
      throw new Error('Password confirmation does not match');
    }
    return true;
  })
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;

    // Get current user data
    const userResult = await databaseService.query(
      databaseService.queries.users.findById,
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];

    // Verify current password
    const bcrypt = require('bcryptjs');
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);

    if (!isCurrentPasswordValid) {
      logger.warn('Invalid current password provided', { userId });
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const saltRounds = 12;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await databaseService.query(
      databaseService.queries.users.updatePassword,
      [userId, hashedNewPassword]
    );

    // Invalidate all refresh tokens (force re-login from other devices)
    await redisService.del(`refresh_token:${userId}`);

    logger.info('Password changed successfully', { userId });

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Get users list (Admin only)
router.get('/', [
  authMiddleware,
  requireRole(['admin']),
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const { page = 1, limit = 20, sort = 'created_at', order = 'desc', role, search } = req.query;
    const offset = (page - 1) * limit;

    let query = '';
    let params = [];
    let paramCount = 1;

    if (search) {
      query = databaseService.queries.users.search;
      params = [`%${search}%`, role || 'student', limit, offset];
    } else if (role) {
      query = databaseService.queries.users.findAll;
      params = [role, limit, offset];
    } else {
      query = 'SELECT * FROM users WHERE is_active = true ORDER BY created_at DESC LIMIT $1 OFFSET $2';
      params = [limit, offset];
    }

    const result = await databaseService.query(query, params);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM users WHERE is_active = true';
    let countParams = [];

    if (role) {
      countQuery += ' AND role = $1';
      countParams = [role];
    }

    if (search) {
      if (role) {
        countQuery += ' AND (first_name ILIKE $2 OR last_name ILIKE $2 OR email ILIKE $2)';
        countParams = [role, `%${search}%`];
      } else {
        countQuery = 'SELECT COUNT(*) FROM users WHERE (first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1) AND is_active = true';
        countParams = [`%${search}%`];
      }
    }

    const countResult = await databaseService.query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count, 10);
    const totalPages = Math.ceil(totalCount / limit);

    // Remove passwords from response
    const users = result.rows.map(user => {
      const { password, ...userWithoutPassword } = user;
      return userWithoutPassword;
    });

    res.json({
      success: true,
      data: {
        users,
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

// Get specific user by ID (Admin or own profile)
router.get('/:id', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid user ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const currentUserId = req.user.userId;
    const userRole = req.user.role;

    // Check if user can access this profile
    if (targetUserId !== currentUserId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const result = await databaseService.query(
      databaseService.queries.users.findById,
      [targetUserId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = result.rows[0];
    const { password, ...userWithoutPassword } = user;

    res.json({
      success: true,
      data: { user: userWithoutPassword }
    });

  } catch (error) {
    next(error);
  }
});

// Update user (Admin only)
router.put('/:id', [
  authMiddleware,
  requireRole(['admin']),
  param('id').isUUID().withMessage('Invalid user ID'),
  body('firstName').optional().isLength({ min: 2, max: 50 }),
  body('lastName').optional().isLength({ min: 2, max: 50 }),
  body('role').optional().isIn(['student', 'tutor', 'admin']),
  body('phone').optional().isMobilePhone('any'),
  body('bio').optional().isLength({ max: 500 }),
  body('subjects').optional().isArray(),
  body('subjects.*').optional().isString(),
  body('timezone').optional().isString(),
  body('isActive').optional().isBoolean()
], handleValidationErrors, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const updates = req.body;

    // Build dynamic update query
    const allowedFields = ['firstName', 'lastName', 'role', 'phone', 'bio', 'subjects', 'timezone', 'isActive'];
    const setClause = [];
    const values = [];
    let paramCount = 1;

    for (const [field, value] of Object.entries(updates)) {
      if (allowedFields.includes(field)) {
        const dbField = field.replace(/([A-Z])/g, '_$1').toLowerCase();
        setClause.push(`${dbField} = $${paramCount}`);
        values.push(field === 'subjects' ? JSON.stringify(value) : value);
        paramCount++;
      }
    }

    if (setClause.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    setClause.push(`updated_at = NOW()`);
    values.push(targetUserId);

    const updateQuery = `
      UPDATE users 
      SET ${setClause.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await databaseService.query(updateQuery, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const updatedUser = result.rows[0];
    const { password, ...userWithoutPassword } = updatedUser;

    // Invalidate cache
    await redisService.del(`user:${targetUserId}`);
    await redisService.invalidatePattern(`users:${updatedUser.role}:*`);

    logger.info('User updated by admin', { 
      adminUserId: req.user.userId, 
      targetUserId, 
      updates: Object.keys(updates) 
    });

    res.json({
      success: true,
      message: 'User updated successfully',
      data: { user: userWithoutPassword }
    });

  } catch (error) {
    next(error);
  }
});

// Deactivate user (Admin only)
router.delete('/:id', [
  authMiddleware,
  requireRole(['admin']),
  param('id').isUUID().withMessage('Invalid user ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;
    const { reason } = req.body;

    const result = await databaseService.query(
      'UPDATE users SET is_active = false, updated_at = NOW() WHERE id = $1 RETURNING *',
      [targetUserId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const deactivatedUser = result.rows[0];

    // Invalidate all related cache
    await redisService.del(`user:${targetUserId}`);
    await redisService.del(`refresh_token:${targetUserId}`);
    await redisService.invalidatePattern(`users:${deactivatedUser.role}:*`);

    // TODO: Send deactivation email notification

    logger.info('User deactivated by admin', { 
      adminUserId: req.user.userId, 
      targetUserId, 
      reason 
    });

    res.json({
      success: true,
      message: 'User deactivated successfully'
    });

  } catch (error) {
    next(error);
  }
});

// Activate user (Admin only)
router.post('/:id/activate', [
  authMiddleware,
  requireRole(['admin']),
  param('id').isUUID().withMessage('Invalid user ID')
], handleValidationErrors, async (req, res, next) => {
  try {
    const targetUserId = req.params.id;

    const result = await databaseService.query(
      databaseService.queries.users.activate,
      [targetUserId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const activatedUser = result.rows[0];
    const { password, ...userWithoutPassword } = activatedUser;

    logger.info('User activated by admin', { 
      adminUserId: req.user.userId, 
      targetUserId 
    });

    res.json({
      success: true,
      message: 'User activated successfully',
      data: { user: userWithoutPassword }
    });

  } catch (error) {
    next(error);
  }
});

// Get user statistics (Admin only)
router.get('/stats/overview', [
  authMiddleware,
  requireRole(['admin'])
], async (req, res, next) => {
  try {
    const cacheKey = 'stats:users:overview';
    const cached = await redisService.get(cacheKey);
    
    if (cached) {
      return res.json({
        success: true,
        data: cached
      });
    }

    // Get total users by role
    const roleStatsQuery = `
      SELECT role, COUNT(*) as count 
      FROM users 
      WHERE is_active = true 
      GROUP BY role
    `;
    
    const roleStatsResult = await databaseService.query(roleStatsQuery);
    
    // Get recent registrations (last 30 days)
    const recentRegistrationsQuery = `
      SELECT DATE(created_at) as date, COUNT(*) as count
      FROM users
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY DATE(created_at)
      ORDER BY date DESC
      LIMIT 30
    `;
    
    const recentRegistrationsResult = await databaseService.query(recentRegistrationsQuery);
    
    // Get total users
    const totalUsersQuery = 'SELECT COUNT(*) as total FROM users WHERE is_active = true';
    const totalUsersResult = await databaseService.query(totalUsersQuery);
    
    // Get active users (users who logged in last 7 days)
    const activeUsersQuery = `
      SELECT COUNT(*) as active
      FROM users
      WHERE is_active = true AND last_login >= NOW() - INTERVAL '7 days'
    `;
    
    const activeUsersResult = await databaseService.query(activeUsersQuery);

    const stats = {
      totalUsers: parseInt(totalUsersResult.rows[0].total, 10),
      activeUsers: parseInt(activeUsersResult.rows[0].active, 10),
      roleDistribution: roleStatsResult.rows.reduce((acc, row) => {
        acc[row.role] = parseInt(row.count, 10);
        return acc;
      }, {}),
      recentRegistrations: recentRegistrationsResult.rows.map(row => ({
        date: row.date,
        count: parseInt(row.count, 10)
      }))
    };

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

// Search users (Public endpoint for finding tutors/students)
router.get('/search', [
  ...commonValidations.validatePagination,
  query('role').optional().isIn(['student', 'tutor']).withMessage('Role must be student or tutor'),
  query('subjects').optional().isString().withMessage('Subjects filter must be a string'),
  query('location').optional().isString().withMessage('Location filter must be a string'),
  query('availability').optional().isString().withMessage('Availability filter must be a string')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      role = 'tutor', 
      search, 
      subjects, 
      location, 
      availability,
      sort = 'rating',
      order = 'desc'
    } = req.query;
    
    const offset = (page - 1) * limit;

    let query = `
      SELECT u.id, u.first_name, u.last_name, u.bio, u.subjects, u.timezone, 
             u.profile_image, u.rating, u.total_sessions
      FROM users u
      WHERE u.is_active = true AND u.role = $1
    `;
    
    const params = [role];
    let paramCount = 2;

    // Add search conditions
    if (search) {
      query += ` AND (u.first_name ILIKE $${paramCount} OR u.last_name ILIKE $${paramCount})`;
      params.push(`%${search}%`);
      paramCount++;
    }

    if (subjects) {
      query += ` AND u.subjects::text ILIKE $${paramCount}`;
      params.push(`%${subjects}%`);
      paramCount++;
    }

    // Add sorting
    let orderBy = '';
    switch (sort) {
      case 'rating':
        orderBy = 'ORDER BY u.rating DESC NULLS LAST';
        break;
      case 'experience':
        orderBy = 'ORDER BY u.total_sessions DESC NULLS LAST';
        break;
      case 'name':
        orderBy = `ORDER BY u.first_name ${order.toUpperCase()}`;
        break;
      case 'recent':
        orderBy = 'ORDER BY u.created_at DESC';
        break;
      default:
        orderBy = 'ORDER BY u.rating DESC NULLS LAST';
    }

    query += ` ${orderBy} LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await databaseService.query(query, params);

    // Parse subjects JSON for each user
    const users = result.rows.map(user => ({
      ...user,
      subjects: user.subjects ? JSON.parse(user.subjects) : []
    }));

    res.json({
      success: true,
      data: { users }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;