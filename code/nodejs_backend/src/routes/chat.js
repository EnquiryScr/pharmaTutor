const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware } = require('../middleware/auth');
const { handleValidationErrors, commonValidations, chatValidations } = require('../middleware/validation');
const { logger } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Get conversation history with a user
router.get('/conversation/:userId', [
  authMiddleware,
  param('userId').isUUID().withMessage('Invalid user ID'),
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const currentUserId = req.user.userId;
    const otherUserId = req.params.userId;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    // Get messages between the two users
    const result = await databaseService.query(
      databaseService.queries.chat.findConversation,
      [currentUserId, otherUserId, limit, offset]
    );

    const messages = result.rows.map(message => ({
      ...message,
      attachments: message.attachments ? JSON.parse(message.attachments) : []
    }));

    // Mark messages as read
    await databaseService.query(
      'UPDATE messages SET is_read = true, read_at = NOW() WHERE sender_id = $1 AND recipient_id = $2 AND is_read = false',
      [otherUserId, currentUserId]
    );

    res.json({
      success: true,
      data: { messages }
    });

  } catch (error) {
    next(error);
  }
});

// Send a message
router.post('/message', [
  authMiddleware,
  ...chatValidations.sendMessage
], handleValidationErrors, async (req, res, next) => {
  try {
    const senderId = req.user.userId;
    const { recipientId, message, messageType = 'text', attachments = [] } = req.body;

    // Generate message ID
    const messageId = uuidv4();

    // Save message to database
    const result = await databaseService.query(
      databaseService.queries.chat.sendMessage,
      [messageId, senderId, recipientId, null, message, messageType, JSON.stringify(attachments)]
    );

    const savedMessage = result.rows[0];

    // Cache message for quick access
    await redisService.storeMessage(messageId, {
      ...savedMessage,
      attachments
    });

    // Add to conversation history
    await redisService.addToConversation(`user_${senderId}_user_${recipientId}`, messageId);
    await redisService.addToConversation(`user_${recipientId}_user_${senderId}`, messageId);

    logger.info('Message sent', {
      messageId,
      from: senderId,
      to: recipientId,
      type: messageType
    });

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: { message: { ...savedMessage, attachments } }
    });

  } catch (error) {
    next(error);
  }
});

// Create chat room
router.post('/room', [
  authMiddleware,
  ...chatValidations.createRoom
], handleValidationErrors, async (req, res, next) => {
  try {
    const createdBy = req.user.userId;
    const { name, type, participants } = req.body;

    // Add creator to participants if not already included
    if (!participants.includes(createdBy)) {
      participants.push(createdBy);
    }

    // Generate room ID
    const roomId = uuidv4();

    // Create room
    const result = await databaseService.query(
      databaseService.queries.chat.createRoom,
      [roomId, name, type, JSON.stringify(participants), createdBy]
    );

    const room = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Chat room created successfully',
      data: { room }
    });

  } catch (error) {
    next(error);
  }
});

// Get room messages
router.get('/room/:roomId/messages', [
  authMiddleware,
  param('roomId').isUUID().withMessage('Invalid room ID'),
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const roomId = req.params.roomId;
    const { limit = 50, offset = 0 } = req.query;

    // Check if user is participant of the room
    const roomResult = await databaseService.query(
      databaseService.queries.chat.findRoom,
      [roomId]
    );

    if (roomResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Room not found'
      });
    }

    const room = roomResult.rows[0];
    const participants = JSON.parse(room.participants);

    if (!participants.includes(req.user.userId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Get messages
    const result = await databaseService.query(
      databaseService.queries.chat.findRoomMessages,
      [roomId, limit, offset]
    );

    const messages = result.rows.map(message => ({
      ...message,
      attachments: message.attachments ? JSON.parse(message.attachments) : []
    }));

    res.json({
      success: true,
      data: { messages }
    });

  } catch (error) {
    next(error);
  }
});

// Send room message
router.post('/room/:roomId/message', [
  authMiddleware,
  param('roomId').isUUID().withMessage('Invalid room ID'),
  body('message').isLength({ min: 1, max: 2000 }).withMessage('Message must be between 1 and 2000 characters'),
  body('messageType').optional().isIn(['text', 'file', 'image', 'audio', 'video']).withMessage('Invalid message type'),
  body('attachments').optional().isArray().withMessage('Attachments must be an array')
], handleValidationErrors, async (req, res, next) => {
  try {
    const roomId = req.params.roomId;
    const senderId = req.user.userId;
    const { message, messageType = 'text', attachments = [] } = req.body;

    // Check room access
    const roomResult = await databaseService.query(
      databaseService.queries.chat.findRoom,
      [roomId]
    );

    if (roomResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Room not found'
      });
    }

    const room = roomResult.rows[0];
    const participants = JSON.parse(room.participants);

    if (!participants.includes(senderId)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Generate message ID
    const messageId = uuidv4();

    // Save message
    const result = await databaseService.query(
      databaseService.queries.chat.sendMessage,
      [messageId, senderId, null, roomId, message, messageType, JSON.stringify(attachments)]
    );

    const savedMessage = result.rows[0];

    // Cache and add to conversation
    await redisService.storeMessage(messageId, {
      ...savedMessage,
      attachments
    });
    await redisService.addToConversation(`room_${roomId}`, messageId);

    res.status(201).json({
      success: true,
      message: 'Room message sent successfully',
      data: { message: { ...savedMessage, attachments } }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;