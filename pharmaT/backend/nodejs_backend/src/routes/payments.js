const express = require('express');
const Stripe = require('stripe');
const { body, param, query, validationResult } = require('express-validator');
const { authMiddleware } = require('../middleware/auth');
const { handleValidationErrors, commonValidations, paymentValidations } = require('../middleware/validation');
const { logger } = require('../middleware/logger');
const DatabaseService = require('../services/databaseService');
const RedisService = require('../services/redisService');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const databaseService = new DatabaseService();
const redisService = new RedisService();

// Create payment intent
router.post('/create-intent', [
  authMiddleware,
  ...paymentValidations.createPaymentIntent
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { amount, currency = 'usd', description, appointmentId, metadata = {} } = req.body;

    // Create payment record in database
    const paymentId = uuidv4();
    
    const paymentResult = await databaseService.query(
      databaseService.queries.payments.create,
      [
        paymentId,
        userId,
        amount,
        currency,
        'pending',
        'stripe',
        JSON.stringify(metadata)
      ]
    );

    // Create Stripe payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      description,
      metadata: {
        paymentId,
        userId,
        appointmentId: appointmentId || '',
        ...metadata
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Update payment record with Stripe ID
    await databaseService.query(
      databaseService.queries.payments.updateStatus,
      [paymentId, 'processing', paymentIntent.id]
    );

    logger.info('Payment intent created', {
      paymentId,
      userId,
      amount,
      currency
    });

    res.json({
      success: true,
      data: {
        clientSecret: paymentIntent.client_secret,
        paymentId,
        amount,
        currency
      }
    });

  } catch (error) {
    if (error.type === 'StripeCardError') {
      return res.status(400).json({
        success: false,
        message: `Payment failed: ${error.message}`
      });
    }
    next(error);
  }
});

// Confirm payment
router.post('/confirm/:paymentId', [
  authMiddleware,
  param('paymentId').isUUID().withMessage('Invalid payment ID'),
  body('paymentIntentId').notEmpty().withMessage('Payment intent ID is required')
], handleValidationErrors, async (req, res, next) => {
  try {
    const paymentId = req.params.paymentId;
    const { paymentIntentId } = req.body;

    // Get payment from database
    const paymentResult = await databaseService.query(
      databaseService.queries.payments.findById,
      [paymentId]
    );

    if (paymentResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    const payment = paymentResult.rows[0];

    // Check if user owns this payment
    if (payment.user_id !== req.user.userId && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Retrieve payment intent from Stripe
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    let status = 'failed';
    if (paymentIntent.status === 'succeeded') {
      status = 'completed';
    } else if (paymentIntent.status === 'processing') {
      status = 'processing';
    }

    // Update payment status
    await databaseService.query(
      databaseService.queries.payments.updateStatus,
      [paymentId, status, paymentIntentId]
    );

    if (status === 'completed') {
      // Process successful payment
      await processSuccessfulPayment(payment);
    }

    logger.info('Payment confirmed', {
      paymentId,
      status,
      amount: payment.amount
    });

    res.json({
      success: true,
      message: `Payment ${status}`,
      data: {
        paymentId,
        status,
        amount: payment.amount,
        currency: payment.currency
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get payment history
router.get('/history', [
  authMiddleware,
  ...commonValidations.validatePagination
], handleValidationErrors, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await databaseService.query(
      databaseService.queries.payments.findByUser,
      [userId, limit, offset]
    );

    const payments = result.rows.map(payment => ({
      ...payment,
      metadata: payment.metadata ? JSON.parse(payment.metadata) : {}
    }));

    res.json({
      success: true,
      data: { payments }
    });

  } catch (error) {
    next(error);
  }
});

// Process successful payment
async function processSuccessfulPayment(payment) {
  try {
    // Create tutor payout record if applicable
    if (payment.metadata) {
      const metadata = JSON.parse(payment.metadata);
      
      if (metadata.appointmentId) {
        const appointment = await databaseService.query(
          'SELECT tutor_id FROM appointments WHERE id = $1',
          [metadata.appointmentId]
        );

        if (appointment.rows.length > 0) {
          const tutorId = appointment.rows[0].tutor_id;
          const commissionRate = 0.15; // 15% platform commission
          const tutorAmount = payment.amount * (1 - commissionRate);

          await databaseService.query(
            'INSERT INTO tutor_payouts (id, tutor_id, amount, currency, status, metadata) VALUES ($1, $2, $3, $4, $5, $6)',
            [
              uuidv4(),
              tutorId,
              tutorAmount,
              payment.currency,
              'pending',
              JSON.stringify({
                paymentId: payment.id,
                appointmentId: metadata.appointmentId,
                commissionRate
              })
            ]
          );
        }
      }
    }

    logger.info('Successful payment processed', {
      paymentId: payment.id,
      amount: payment.amount,
      userId: payment.user_id
    });

  } catch (error) {
    logger.error('Error processing successful payment:', error);
  }
}

module.exports = router;