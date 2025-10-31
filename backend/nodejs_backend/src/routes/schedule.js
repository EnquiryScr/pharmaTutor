const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { handleValidationErrors, commonValidations, scheduleValidations } = require('../middleware/validation');
const { logger } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Create appointment
router.post('/appointment', [
  authMiddleware,
  ...scheduleValidations.createAppointment
], handleValidationErrors, async (req, res, next) => {
  try {
    const studentId = req.user.userId;
    const {
      tutorId,
      startTime,
      endTime,
      subject,
      notes,
      meetingLink
    } = req.body;

    const appointmentId = uuidv4();

    // Check if tutor is available at the requested time
    const conflictCheck = await databaseService.query(
      'SELECT COUNT(*) FROM appointments WHERE tutor_id = $1 AND status NOT IN ($2, $3) AND (start_time < $4 AND end_time > $5)',
      [tutorId, 'cancelled', 'completed', endTime, startTime]
    );

    if (parseInt(conflictCheck.rows[0].count, 10) > 0) {
      return res.status(400).json({
        success: false,
        message: 'Tutor is not available at the requested time'
      });
    }

    const result = await databaseService.query(
      databaseService.queries.schedules.createAppointment,
      [
        appointmentId,
        studentId,
        tutorId,
        subject,
        new Date(startTime),
        new Date(endTime),
        'scheduled',
        notes,
        meetingLink
      ]
    );

    const appointment = result.rows[0];

    logger.info('Appointment created', {
      appointmentId,
      studentId,
      tutorId,
      subject,
      startTime
    });

    res.status(201).json({
      success: true,
      message: 'Appointment scheduled successfully',
      data: { appointment }
    });

  } catch (error) {
    next(error);
  }
});

// Get user's appointments
router.get('/appointments', [
  authMiddleware,
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const query = req.user.role === 'tutor' 
      ? databaseService.queries.schedules.findByTutor
      : databaseService.queries.schedules.findByStudent;

    const result = await databaseService.query(
      query,
      [userId, limit, offset]
    );

    const appointments = result.rows;

    res.json({
      success: true,
      data: { appointments }
    });

  } catch (error) {
    next(error);
  }
});

// Update appointment
router.put('/appointment/:id', [
  authMiddleware,
  param('id').isUUID().withMessage('Invalid appointment ID'),
  body('subject').optional().isString(),
  body('startTime').optional().isISO8601(),
  body('endTime').optional().isISO8601(),
  body('status').optional().isIn(['scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show']),
  body('notes').optional().isLength({ max: 500 }),
  body('meetingLink').optional().isURL()
], handleValidationErrors, async (req, res, next) => {
  try {
    const appointmentId = req.params.id;
    const userId = req.user.userId;
    const { subject, startTime, endTime, status, notes, meetingLink } = req.body;

    // Get appointment
    const appointmentResult = await databaseService.query(
      databaseService.queries.schedules.findById,
      [appointmentId]
    );

    if (appointmentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found'
      });
    }

    const appointment = appointmentResult.rows[0];

    // Check permissions
    if (appointment.student_id !== userId && appointment.tutor_id !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    let result;
    if (status) {
      // Update status only
      result = await databaseService.query(
        databaseService.queries.schedules.updateStatus,
        [appointmentId, status]
      );
    } else {
      // Full update
      result = await databaseService.query(
        databaseService.queries.schedules.update,
        [
          appointmentId,
          subject || appointment.subject,
          startTime ? new Date(startTime) : appointment.start_time,
          endTime ? new Date(endTime) : appointment.end_time,
          appointment.status,
          notes || appointment.notes,
          meetingLink || appointment.meeting_link
        ]
      );
    }

    const updatedAppointment = result.rows[0];

    logger.info('Appointment updated', {
      appointmentId,
      updatedBy: userId,
      updatedFields: Object.keys(req.body)
    });

    res.json({
      success: true,
      message: 'Appointment updated successfully',
      data: { appointment: updatedAppointment }
    });

  } catch (error) {
    next(error);
  }
});

// Get tutor availability
router.get('/tutor/:tutorId/availability', [
  authMiddleware,
  param('tutorId').isUUID().withMessage('Invalid tutor ID'),
  query('date').isISO8601().withMessage('Date must be in ISO format')
], handleValidationErrors, async (req, res, next) => {
  try {
    const tutorId = req.params.tutorId;
    const { date } = req.query;

    const result = await databaseService.query(
      databaseService.queries.schedules.getAvailability,
      [tutorId, date]
    );

    const availability = result.rows;

    res.json({
      success: true,
      data: { availability }
    });

  } catch (error) {
    next(error);
  }
});

// Update tutor availability
router.post('/tutor/availability', [
  authMiddleware,
  requireRole(['tutor', 'admin']),
  ...scheduleValidations.updateAvailability
], handleValidationErrors, async (req, res, next) => {
  try {
    const tutorId = req.user.userId;
    const { date, timeSlots } = req.body;

    // Delete existing availability for the date
    await databaseService.query(
      'DELETE FROM availability WHERE tutor_id = $1 AND date = $2',
      [tutorId, date]
    );

    // Insert new availability
    for (const slot of timeSlots) {
      await databaseService.query(
        'INSERT INTO availability (id, tutor_id, date, start_time, end_time, is_available) VALUES ($1, $2, $3, $4, $5, $6)',
        [uuidv4(), tutorId, date, slot.start, slot.end, slot.isAvailable]
      );
    }

    logger.info('Tutor availability updated', {
      tutorId,
      date,
      timeSlotsCount: timeSlots.length
    });

    res.json({
      success: true,
      message: 'Availability updated successfully'
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;