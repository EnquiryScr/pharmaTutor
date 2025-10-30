const express = require('express');
const { query, validationResult } = require('express-validator');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { handleValidationErrors, commonValidations } = require('../middleware/validation');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Platform overview analytics
router.get('/overview', [
  authMiddleware,
  requireRole(['admin'])
], async (req, res, next) => {
  try {
    const cacheKey = 'analytics:platform:overview';
    const cached = await redisService.get(cacheKey);
    
    if (cached) {
      return res.json({
        success: true,
        data: cached
      });
    }

    const queries = {
      totalUsers: 'SELECT COUNT(*) as count FROM users WHERE is_active = true',
      totalTutors: 'SELECT COUNT(*) as count FROM users WHERE role = $1 AND is_active = true',
      totalStudents: 'SELECT COUNT(*) as count FROM users WHERE role = $1 AND is_active = true',
      totalAssignments: 'SELECT COUNT(*) as count FROM assignments',
      totalAppointments: 'SELECT COUNT(*) as count FROM appointments',
      totalRevenue: 'SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE status = $1',
      monthlyRevenue: `
        SELECT DATE_TRUNC('month', created_at) as month, SUM(amount) as revenue
        FROM payments 
        WHERE status = $1 AND created_at >= NOW() - INTERVAL '12 months'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY month DESC
      `,
      activeUsers: `
        SELECT COUNT(DISTINCT user_id) as count 
        FROM analytics_events 
        WHERE created_at >= NOW() - INTERVAL '30 days'
      `
    };

    const [
      totalUsers,
      totalTutors,
      totalStudents,
      totalAssignments,
      totalAppointments,
      totalRevenue,
      monthlyRevenue,
      activeUsers
    ] = await Promise.all([
      databaseService.query(queries.totalUsers),
      databaseService.query(queries.totalTutors, ['tutor']),
      databaseService.query(queries.totalStudents, ['student']),
      databaseService.query(queries.totalAssignments),
      databaseService.query(queries.totalAppointments),
      databaseService.query(queries.totalRevenue, ['completed']),
      databaseService.query(queries.monthlyRevenue, ['completed']),
      databaseService.query(queries.activeUsers)
    ]);

    const overview = {
      users: {
        total: parseInt(totalUsers.rows[0].count, 10),
        tutors: parseInt(totalTutors.rows[0].count, 10),
        students: parseInt(totalStudents.rows[0].count, 10),
        active: parseInt(activeUsers.rows[0].count, 10)
      },
      content: {
        assignments: parseInt(totalAssignments.rows[0].count, 10),
        appointments: parseInt(totalAppointments.rows[0].count, 10)
      },
      revenue: {
        total: parseFloat(totalRevenue.rows[0].total),
        monthly: monthlyRevenue.rows.map(row => ({
          month: row.month,
          revenue: parseFloat(row.revenue)
        }))
      },
      lastUpdated: new Date().toISOString()
    };

    // Cache for 1 hour
    await redisService.set(cacheKey, overview, 3600);

    res.json({
      success: true,
      data: overview
    });

  } catch (error) {
    next(error);
  }
});

// User engagement analytics
router.get('/engagement', [
  authMiddleware,
  requireRole(['admin']),
  query('period').optional().isIn(['7d', '30d', '90d', '1y']).withMessage('Invalid period'),
  query('userType').optional().isIn(['all', 'tutors', 'students']).withMessage('Invalid user type')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { period = '30d', userType = 'all' } = req.query;
    
    const cacheKey = `analytics:engagement:${period}:${userType}`;
    const cached = await redisService.get(cacheKey);
    
    if (cached) {
      return res.json({
        success: true,
        data: cached
      });
    }

    const intervalMap = {
      '7d': '7 days',
      '30d': '30 days',
      '90d': '90 days',
      '1y': '365 days'
    };

    const interval = intervalMap[period];

    let userFilter = '';
    if (userType !== 'all') {
      userFilter = `AND u.role = '${userType.slice(0, -1)}'`; // Remove 's' from 'tutors'/'students'
    }

    const queries = {
      dailyActiveUsers: `
        SELECT DATE(created_at) as date, COUNT(DISTINCT user_id) as count
        FROM analytics_events 
        WHERE created_at >= NOW() - INTERVAL '${interval}'
        GROUP BY DATE(created_at)
        ORDER BY date DESC
      `,
      sessionData: `
        SELECT 
          AVG(session_duration) as avg_session_duration,
          COUNT(DISTINCT session_id) as total_sessions
        FROM analytics_events 
        WHERE created_at >= NOW() - INTERVAL '${interval}' AND event_type = 'session_end'
      `,
      featureUsage: `
        SELECT event_type, COUNT(*) as count
        FROM analytics_events 
        WHERE created_at >= NOW() - INTERVAL '${interval}'
        GROUP BY event_type
        ORDER BY count DESC
        LIMIT 10
      `
    };

    const [
      dailyActiveUsers,
      sessionData,
      featureUsage
    ] = await Promise.all([
      databaseService.query(queries.dailyActiveUsers),
      databaseService.query(queries.sessionData),
      databaseService.query(queries.featureUsage)
    ]);

    const engagement = {
      dailyActiveUsers: dailyActiveUsers.rows.map(row => ({
        date: row.date,
        count: parseInt(row.count, 10)
      })),
      sessionMetrics: {
        averageDuration: parseFloat(sessionData.rows[0].avg_session_duration || 0),
        totalSessions: parseInt(sessionData.rows[0].total_sessions || 0, 10)
      },
      featureUsage: featureUsage.rows.map(row => ({
        feature: row.event_type,
        usage: parseInt(row.count, 10)
      })),
      period,
      userType,
      lastUpdated: new Date().toISOString()
    };

    // Cache for 30 minutes
    await redisService.set(cacheKey, engagement, 1800);

    res.json({
      success: true,
      data: engagement
    });

  } catch (error) {
    next(error);
  }
});

// Revenue analytics
router.get('/revenue', [
  authMiddleware,
  requireRole(['admin']),
  query('period').optional().isIn(['7d', '30d', '90d', '1y']).withMessage('Invalid period'),
  query('groupBy').optional().isIn(['day', 'week', 'month']).withMessage('Invalid groupBy')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { period = '30d', groupBy = 'day' } = req.query;
    
    const cacheKey = `analytics:revenue:${period}:${groupBy}`;
    const cached = await redisService.get(cacheKey);
    
    if (cached) {
      return res.json({
        success: true,
        data: cached
      });
    }

    const intervalMap = {
      '7d': '7 days',
      '30d': '30 days',
      '90d': '90 days',
      '1y': '365 days'
    };

    const interval = intervalMap[period];
    const groupByClause = `DATE_TRUNC('${groupBy}', created_at)`;

    const queries = {
      revenueOverTime: `
        SELECT ${groupByClause} as period, SUM(amount) as revenue, COUNT(*) as transactions
        FROM payments 
        WHERE status = 'completed' AND created_at >= NOW() - INTERVAL '${interval}'
        GROUP BY ${groupByClause}
        ORDER BY period DESC
      `,
      revenueByCurrency: `
        SELECT currency, SUM(amount) as total, COUNT(*) as count
        FROM payments 
        WHERE status = 'completed' AND created_at >= NOW() - INTERVAL '${interval}'
        GROUP BY currency
      `,
      averageTransactionValue: `
        SELECT AVG(amount) as avg_amount
        FROM payments 
        WHERE status = 'completed' AND created_at >= NOW() - INTERVAL '${interval}'
      `
    };

    const [
      revenueOverTime,
      revenueByCurrency,
      avgTransactionValue
    ] = await Promise.all([
      databaseService.query(queries.revenueOverTime),
      databaseService.query(queries.revenueByCurrency),
      databaseService.query(queries.averageTransactionValue)
    ]);

    const revenue = {
      overTime: revenueOverTime.rows.map(row => ({
        period: row.period,
        revenue: parseFloat(row.revenue),
        transactions: parseInt(row.transactions, 10)
      })),
      byCurrency: revenueByCurrency.rows.map(row => ({
        currency: row.currency,
        total: parseFloat(row.total),
        count: parseInt(row.count, 10)
      })),
      averageTransactionValue: parseFloat(avgTransactionValue.rows[0].avg_amount || 0),
      period,
      groupBy,
      lastUpdated: new Date().toISOString()
    };

    // Cache for 1 hour
    await redisService.set(cacheKey, revenue, 3600);

    res.json({
      success: true,
      data: revenue
    });

  } catch (error) {
    next(error);
  }
});

// Track analytics event
router.post('/track', [
  authMiddleware,
  // Event tracking doesn't need extensive validation as it's for internal use
], async (req, res, next) => {
  try {
    const userId = req.user?.userId || null;
    const { eventType, eventData = {}, sessionId } = req.body;

    // Insert analytics event
    await databaseService.query(
      'INSERT INTO analytics_events (id, user_id, session_id, event_type, event_data, user_agent, ip_address) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [
        require('uuid').v4(),
        userId,
        sessionId,
        eventType,
        JSON.stringify(eventData),
        req.get('User-Agent'),
        req.ip
      ]
    );

    res.json({
      success: true,
      message: 'Event tracked successfully'
    });

  } catch (error) {
    next(error);
  }
});

// User-specific analytics (for tutors and students)
router.get('/user/:userId', [
  authMiddleware,
  query('period').optional().isIn(['7d', '30d', '90d', '1y']).withMessage('Invalid period')
], handleValidationErrors, async (req, res, next) => {
  try {
    const targetUserId = req.params.userId;
    const { period = '30d' } = req.query;
    const currentUserId = req.user.userId;
    const userRole = req.user.role;

    // Check permissions - users can only see their own analytics unless admin
    if (targetUserId !== currentUserId && userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const intervalMap = {
      '7d': '7 days',
      '30d': '30 days',
      '90d': '90 days',
      '1y': '365 days'
    };

    const interval = intervalMap[period];

    const queries = {
      userStats: `
        SELECT 
          COUNT(CASE WHEN event_type = 'assignment_viewed' THEN 1 END) as assignments_viewed,
          COUNT(CASE WHEN event_type = 'message_sent' THEN 1 END) as messages_sent,
          COUNT(CASE WHEN event_type = 'appointment_booked' THEN 1 END) as appointments_booked,
          COUNT(DISTINCT DATE(created_at)) as active_days
        FROM analytics_events 
        WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '${interval}'
      `,
      activityOverTime: `
        SELECT DATE(created_at) as date, COUNT(*) as events
        FROM analytics_events 
        WHERE user_id = $1 AND created_at >= NOW() - INTERVAL '${interval}'
        GROUP BY DATE(created_at)
        ORDER BY date DESC
      `
    };

    const [
      userStats,
      activityOverTime
    ] = await Promise.all([
      databaseService.query(queries.userStats, [targetUserId]),
      databaseService.query(queries.activityOverTime, [targetUserId])
    ]);

    const userAnalytics = {
      stats: {
        assignmentsViewed: parseInt(userStats.rows[0].assignments_viewed || 0, 10),
        messagesSent: parseInt(userStats.rows[0].messages_sent || 0, 10),
        appointmentsBooked: parseInt(userStats.rows[0].appointments_booked || 0, 10),
        activeDays: parseInt(userStats.rows[0].active_days || 0, 10)
      },
      activityOverTime: activityOverTime.rows.map(row => ({
        date: row.date,
        events: parseInt(row.events, 10)
      })),
      period,
      lastUpdated: new Date().toISOString()
    };

    res.json({
      success: true,
      data: userAnalytics
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;