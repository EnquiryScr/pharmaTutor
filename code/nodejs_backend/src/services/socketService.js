const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { logger, logAuthEvent } = require('../middleware/logger');

class SocketService {
  constructor(server) {
    this.server = server;
    this.io = null;
    this.connectedUsers = new Map(); // userId -> socket info
    this.chatRooms = new Map(); // roomId -> room info
    this.activeCalls = new Map(); // callId -> call info
    this.userSockets = new Map(); // socketId -> userId
  }

  initialize(io) {
    this.io = io;
    
    // Authentication middleware for socket connections
    io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token;
        
        if (!token) {
          return next(new Error('Authentication error: No token provided'));
        }

        // Verify JWT token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.userId = decoded.userId;
        socket.userRole = decoded.role;
        socket.userEmail = decoded.email;
        
        next();
      } catch (error) {
        logAuthEvent('socket_auth_failed', null, socket.handshake.address, socket.handshake.headers['user-agent'], false, {
          error: error.message
        });
        
        next(new Error('Authentication error: Invalid token'));
      }
    });

    io.on('connection', (socket) => {
      this.handleConnection(socket);
    });

    logger.info('Socket service initialized');
  }

  handleConnection(socket) {
    const userId = socket.userId;
    const userInfo = {
      socketId: socket.id,
      email: socket.userEmail,
      role: socket.userRole,
      connectedAt: new Date()
    };

    // Store user connection info
    this.connectedUsers.set(userId, userInfo);
    this.userSockets.set(socket.id, userId);

    // Join user's personal room
    socket.join(`user_${userId}`);

    logAuthEvent('socket_connected', userId, socket.handshake.address, socket.handshake.headers['user-agent'], true);

    // Emit connection success
    socket.emit('connected', {
      message: 'Connected successfully',
      userId,
      socketId: socket.id
    });

    // Notify relevant users about online status
    this.broadcastUserStatus(userId, 'online');

    // Handle disconnection
    socket.on('disconnect', () => {
      this.handleDisconnection(socket, userId);
    });

    // Register event handlers
    this.registerEventHandlers(socket, userId);
  }

  handleDisconnection(socket, userId) {
    // Remove from maps
    this.connectedUsers.delete(userId);
    this.userSockets.delete(socket.id);

    // Clean up active calls
    for (const [callId, callInfo] of this.activeCalls.entries()) {
      if (callInfo.participants.includes(userId)) {
        this.endCall(callId, userId, 'disconnected');
      }
    }

    logAuthEvent('socket_disconnected', userId, socket.handshake.address, socket.handshake.headers['user-agent'], true);

    // Broadcast user offline status
    this.broadcastUserStatus(userId, 'offline');
  }

  registerEventHandlers(socket, userId) {
    // Chat messaging
    socket.on('send_message', (data) => {
      this.handleSendMessage(socket, userId, data);
    });

    socket.on('typing_start', (data) => {
      this.handleTypingStart(socket, userId, data);
    });

    socket.on('typing_stop', (data) => {
      this.handleTypingStop(socket, userId, data);
    });

    // Video calls
    socket.on('join_call', (data) => {
      this.handleJoinCall(socket, userId, data);
    });

    socket.on('leave_call', (data) => {
      this.handleLeaveCall(socket, userId, data);
    });

    socket.on('webrtc_offer', (data) => {
      this.handleWebRTCOffer(socket, userId, data);
    });

    socket.on('webrtc_answer', (data) => {
      this.handleWebRTCAnswer(socket, userId, data);
    });

    socket.on('webrtc_ice_candidate', (data) => {
      this.handleWebRTCIceCandidate(socket, userId, data);
    });

    // Assignment notifications
    socket.on('assignment_updated', (data) => {
      this.handleAssignmentUpdate(socket, userId, data);
    });

    socket.on('grade_submitted', (data) => {
      this.handleGradeSubmitted(socket, userId, data);
    });

    // Query/Ticket updates
    socket.on('query_updated', (data) => {
      this.handleQueryUpdate(socket, userId, data);
    });

    // Appointment notifications
    socket.on('appointment_scheduled', (data) => {
      this.handleAppointmentScheduled(socket, userId, data);
    });

    socket.on('appointment_cancelled', (data) => {
      this.handleAppointmentCancelled(socket, userId, data);
    });

    // File sharing
    socket.on('file_shared', (data) => {
      this.handleFileShared(socket, userId, data);
    });

    // Whiteboard collaboration
    socket.on('whiteboard_draw', (data) => {
      this.handleWhiteboardDraw(socket, userId, data);
    });

    socket.on('whiteboard_clear', (data) => {
      this.handleWhiteboardClear(socket, userId, data);
    });

    // Screen sharing
    socket.on('start_screen_share', (data) => {
      this.handleStartScreenShare(socket, userId, data);
    });

    socket.on('stop_screen_share', (data) => {
      this.handleStopScreenShare(socket, userId, data);
    });
  }

  // Chat messaging methods
  handleSendMessage(socket, userId, data) {
    try {
      const { recipientId, message, messageType = 'text', attachments = [] } = data;
      
      if (!recipientId || !message) {
        socket.emit('error', { message: 'Recipient ID and message are required' });
        return;
      }

      const messageId = uuidv4();
      const messageData = {
        id: messageId,
        senderId: userId,
        recipientId,
        message,
        messageType,
        attachments,
        timestamp: new Date(),
        delivered: false,
        read: false
      };

      // Send to recipient
      this.io.to(`user_${recipientId}`).emit('new_message', messageData);
      
      // Send confirmation to sender
      socket.emit('message_sent', {
        messageId,
        status: 'sent',
        timestamp: messageData.timestamp
      });

      logger.info('Message sent', {
        messageId,
        from: userId,
        to: recipientId,
        type: messageType
      });

    } catch (error) {
      logger.error('Error handling send_message:', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  }

  handleTypingStart(socket, userId, data) {
    const { recipientId } = data;
    this.io.to(`user_${recipientId}`).emit('user_typing', {
      userId,
      isTyping: true
    });
  }

  handleTypingStop(socket, userId, data) {
    const { recipientId } = data;
    this.io.to(`user_${recipientId}`).emit('user_typing', {
      userId,
      isTyping: false
    });
  }

  // Video call methods
  handleJoinCall(socket, userId, data) {
    try {
      const { callId, participants, isVideo = true, isAudio = true } = data;
      
      if (!callId || !participants.includes(userId)) {
        socket.emit('error', { message: 'Invalid call parameters' });
        return;
      }

      // Create call if it doesn't exist
      if (!this.activeCalls.has(callId)) {
        this.activeCalls.set(callId, {
          id: callId,
          participants: participants,
          startTime: new Date(),
          isVideo,
          isAudio,
          status: 'active'
        });
      }

      const callInfo = this.activeCalls.get(callId);
      
      // Add user to call
      socket.join(`call_${callId}`);
      
      // Notify other participants
      socket.to(`call_${callId}`).emit('user_joined_call', {
        userId,
        isVideo,
        isAudio
      });

      logger.info('User joined call', { callId, userId });

    } catch (error) {
      logger.error('Error handling join_call:', error);
      socket.emit('error', { message: 'Failed to join call' });
    }
  }

  handleLeaveCall(socket, userId, data) {
    const { callId } = data;
    this.endCall(callId, userId, 'left');
  }

  handleWebRTCOffer(socket, userId, data) {
    const { callId, offer, targetUserId } = data;
    this.io.to(`user_${targetUserId}`).emit('webrtc_offer', {
      callId,
      offer,
      fromUserId: userId
    });
  }

  handleWebRTCAnswer(socket, userId, data) {
    const { callId, answer, targetUserId } = data;
    this.io.to(`user_${targetUserId}`).emit('webrtc_answer', {
      callId,
      answer,
      fromUserId: userId
    });
  }

  handleWebRTCIceCandidate(socket, userId, data) {
    const { callId, candidate, targetUserId } = data;
    this.io.to(`user_${targetUserId}`).emit('webrtc_ice_candidate', {
      callId,
      candidate,
      fromUserId: userId
    });
  }

  endCall(callId, userId, reason = 'ended') {
    try {
      const callInfo = this.activeCalls.get(callId);
      
      if (callInfo) {
        // Notify all participants
        this.io.to(`call_${callId}`).emit('call_ended', {
          callId,
          endedBy: userId,
          reason,
          duration: Date.now() - callInfo.startTime
        });

        // Clean up
        this.activeCalls.delete(callId);
        this.io.socketsLeave(`call_${callId}`);

        logger.info('Call ended', { callId, userId, reason });
      }
    } catch (error) {
      logger.error('Error ending call:', error);
    }
  }

  // Assignment methods
  handleAssignmentUpdate(socket, userId, data) {
    const { assignmentId, studentId, action } = data;
    
    // Notify student about assignment update
    this.io.to(`user_${studentId}`).emit('assignment_update', {
      assignmentId,
      action,
      updatedBy: userId,
      timestamp: new Date()
    });
  }

  handleGradeSubmitted(socket, userId, data) {
    const { assignmentId, studentId, grade } = data;
    
    // Notify student about grade submission
    this.io.to(`user_${studentId}`).emit('grade_submitted', {
      assignmentId,
      grade,
      gradedBy: userId,
      timestamp: new Date()
    });
  }

  // Query methods
  handleQueryUpdate(socket, userId, data) {
    const { queryId, status, assignedTo } = data;
    
    // Notify relevant users about query updates
    if (assignedTo) {
      this.io.to(`user_${assignedTo}`).emit('query_assigned', {
        queryId,
        assignedTo,
        assignedBy: userId,
        timestamp: new Date()
      });
    }
  }

  // Appointment methods
  handleAppointmentScheduled(socket, userId, data) {
    const { appointmentId, studentId, tutorId, startTime } = data;
    
    // Notify both student and tutor
    this.io.to(`user_${studentId}`).emit('appointment_scheduled', {
      appointmentId,
      tutorId,
      startTime,
      scheduledBy: userId,
      timestamp: new Date()
    });

    this.io.to(`user_${tutorId}`).emit('appointment_scheduled', {
      appointmentId,
      studentId,
      startTime,
      scheduledBy: userId,
      timestamp: new Date()
    });
  }

  handleAppointmentCancelled(socket, userId, data) {
    const { appointmentId, studentId, tutorId, reason } = data;
    
    // Notify both student and tutor
    [studentId, tutorId].forEach(userId => {
      this.io.to(`user_${userId}`).emit('appointment_cancelled', {
        appointmentId,
        cancelledBy: userId,
        reason,
        timestamp: new Date()
      });
    });
  }

  // File sharing methods
  handleFileShared(socket, userId, data) {
    const { recipientId, fileName, fileSize, fileType, fileUrl } = data;
    
    this.io.to(`user_${recipientId}`).emit('file_received', {
      from: userId,
      fileName,
      fileSize,
      fileType,
      fileUrl,
      timestamp: new Date()
    });
  }

  // Whiteboard methods
  handleWhiteboardDraw(socket, userId, data) {
    const { callId, drawData } = data;
    socket.to(`call_${callId}`).emit('whiteboard_draw', {
      from: userId,
      drawData,
      timestamp: new Date()
    });
  }

  handleWhiteboardClear(socket, userId, data) {
    const { callId } = data;
    socket.to(`call_${callId}`).emit('whiteboard_clear', {
      from: userId,
      timestamp: new Date()
    });
  }

  // Screen sharing methods
  handleStartScreenShare(socket, userId, data) {
    const { callId } = data;
    socket.to(`call_${callId}`).emit('screen_share_started', {
      userId,
      timestamp: new Date()
    });
  }

  handleStopScreenShare(socket, userId, data) {
    const { callId } = data;
    socket.to(`call_${callId}`).emit('screen_share_stopped', {
      userId,
      timestamp: new Date()
    });
  }

  // Utility methods
  broadcastUserStatus(userId, status) {
    // This would typically broadcast to contacts/friends list
    // For now, just log the status change
    logger.info('User status changed', { userId, status });
  }

  getConnectedUsers() {
    return Array.from(this.connectedUsers.keys());
  }

  isUserOnline(userId) {
    return this.connectedUsers.has(userId);
  }

  sendNotification(userId, notification) {
    this.io.to(`user_${userId}`).emit('notification', notification);
  }

  broadcastToRoom(room, event, data) {
    this.io.to(room).emit(event, data);
  }

  getActiveCalls() {
    return Array.from(this.activeCalls.keys());
  }
}

module.exports = SocketService;