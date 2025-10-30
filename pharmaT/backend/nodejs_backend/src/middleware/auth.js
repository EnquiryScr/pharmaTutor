const jwt = require('jsonwebtoken');
const { promisify } = require('util');

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    // Verify token
    const decoded = await promisify(jwt.verify)(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired. Please log in again.',
        code: 'TOKEN_EXPIRED'
      });
    } else if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token.',
        code: 'INVALID_TOKEN'
      });
    } else {
      return res.status(401).json({
        success: false,
        message: 'Token verification failed.',
        code: 'TOKEN_VERIFICATION_FAILED'
      });
    }
  }
};

// Optional auth middleware (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (token) {
      const decoded = await promisify(jwt.verify)(token, process.env.JWT_SECRET);
      req.user = decoded;
    }
    
    next();
  } catch (error) {
    // Continue without user if token is invalid
    next();
  }
};

// Role-based authorization
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions.'
      });
    }

    next();
  };
};

// Permission-based authorization
const requirePermission = (permission) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.'
      });
    }

    if (!req.user.permissions || !req.user.permissions.includes(permission)) {
      return res.status(403).json({
        success: false,
        message: `Permission '${permission}' required.`,
        code: 'INSUFFICIENT_PERMISSION'
      });
    }

    next();
  };
};

// Resource ownership check
const checkResourceOwnership = (resourceIdParam = 'id') => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required.'
        });
      }

      const resourceId = req.params[resourceIdParam];
      
      // Check if user owns the resource or is an admin
      if (req.user.role === 'admin' || req.user.userId === resourceId) {
        return next();
      }

      // Additional checks can be added here based on resource type
      // For example, checking if user is assigned to the assignment
      if (req.assignment && req.assignment.studentId === req.user.userId) {
        return next();
      }

      return res.status(403).json({
        success: false,
        message: 'Access denied. You do not own this resource.'
      });
    } catch (error) {
      next(error);
    }
  };
};

module.exports = {
  authMiddleware,
  optionalAuth,
  requireRole,
  requirePermission,
  checkResourceOwnership
};