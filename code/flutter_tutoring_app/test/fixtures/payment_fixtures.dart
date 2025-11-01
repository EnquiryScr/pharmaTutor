import '../test_config.dart';

/// Payment test fixtures for consistent test data
class PaymentFixtures {
  // Test payment methods
  static const validCreditCard = {
    'type': 'credit_card',
    'cardNumber': PaymentTestConfig.testCardNumber,
    'expiryMonth': 12,
    'expiryYear': 2025,
    'cvv': PaymentTestConfig.testCardCvc,
    'cardholderName': 'John Doe',
    'billingAddress': {
      'street': '123 Main St',
      'city': 'Anytown',
      'state': 'CA',
      'zipCode': PaymentTestConfig.testZipCode,
      'country': 'US',
    },
  };

  static const validDebitCard = {
    'type': 'debit_card',
    'cardNumber': '5555555555554444',
    'expiryMonth': 10,
    'expiryYear': 2026,
    'cvv': '456',
    'cardholderName': 'John Doe',
    'billingAddress': {
      'street': '123 Main St',
      'city': 'Anytown',
      'state': 'CA',
      'zipCode': '12345',
      'country': 'US',
    },
  };

  static const expiredCard = {
    'type': 'credit_card',
    'cardNumber': '4111111111111111',
    'expiryMonth': 1,
    'expiryYear': 2020,
    'cvv': '123',
    'cardholderName': 'John Doe',
  };

  static const invalidCardNumber = {
    'type': 'credit_card',
    'cardNumber': '1234567890123456', // Invalid Luhn checksum
    'expiryMonth': 12,
    'expiryYear': 2025,
    'cvv': '123',
    'cardholderName': 'John Doe',
  };

  // Test payment transactions
  static const successfulPaymentTransaction = {
    'id': 'txn-123',
    'userId': 'student-123',
    'amount': PaymentTestConfig.testAmount,
    'currency': PaymentTestConfig.testCurrency,
    'status': 'completed',
    'paymentMethod': validCreditCard,
    'description': 'Tutoring Session Payment',
    'createdAt': '2024-01-01T10:00:00Z',
    'completedAt': '2024-01-01T10:00:30Z',
    'metadata': {
      'sessionId': 'session-123',
      'tutorId': 'tutor-456',
      'duration': 60,
    },
    'fees': {
      'platformFee': 2.99,
      'processingFee': 1.50,
    },
    'refundStatus': null,
  };

  static const pendingPaymentTransaction = {
    'id': 'txn-124',
    'userId': 'student-123',
    'amount': PaymentTestConfig.testAmount,
    'currency': PaymentTestConfig.testCurrency,
    'status': 'pending',
    'paymentMethod': validCreditCard,
    'description': 'Tutoring Session Payment',
    'createdAt': '2024-01-01T10:00:00Z',
    'metadata': {
      'sessionId': 'session-124',
      'tutorId': 'tutor-456',
      'duration': 60,
    },
    'fees': null,
    'refundStatus': null,
  };

  static const failedPaymentTransaction = {
    'id': 'txn-125',
    'userId': 'student-123',
    'amount': PaymentTestConfig.testAmount,
    'currency': PaymentTestConfig.testCurrency,
    'status': 'failed',
    'paymentMethod': validCreditCard,
    'description': 'Tutoring Session Payment',
    'createdAt': '2024-01-01T10:00:00Z',
    'failedAt': '2024-01-01T10:00:05Z',
    'metadata': {
      'sessionId': 'session-125',
      'tutorId': 'tutor-456',
    },
    'fees': null,
    'refundStatus': null,
    'failureReason': 'Insufficient funds',
  };

  static const refundedPaymentTransaction = {
    'id': 'txn-126',
    'userId': 'student-123',
    'amount': PaymentTestConfig.testAmount,
    'currency': PaymentTestConfig.testCurrency,
    'status': 'refunded',
    'paymentMethod': validCreditCard,
    'description': 'Tutoring Session Payment',
    'createdAt': '2024-01-01T10:00:00Z',
    'completedAt': '2024-01-01T10:00:30Z',
    'refundedAt': '2024-01-01T12:00:00Z',
    'metadata': {
      'sessionId': 'session-126',
      'tutorId': 'tutor-456',
      'duration': 60,
    },
    'fees': {
      'platformFee': 2.99,
      'processingFee': 1.50,
    },
    'refundStatus': {
      'id': 'refund-123',
      'amount': PaymentTestConfig.testAmount,
      'reason': 'Session cancelled',
      'status': 'completed',
      'createdAt': '2024-01-01T12:00:00Z',
      'completedAt': '2024-01-01T12:00:30Z',
    },
  };

  // Test payment intents
  static const createPaymentIntentRequest = {
    'amount': PaymentTestConfig.testAmount,
    'currency': PaymentTestConfig.testCurrency,
    'description': 'Tutoring Session Payment',
    'metadata': {
      'sessionId': 'session-123',
      'tutorId': 'tutor-456',
      'duration': 60,
    },
    'paymentMethodId': 'pm_123456789',
  };

  static const createPaymentIntentResponse = {
    'success': true,
    'data': {
      'id': 'pi_123',
      'clientSecret': 'pi_123_secret_456',
      'amount': PaymentTestConfig.testAmount,
      'currency': PaymentTestConfig.testCurrency,
      'status': 'requires_payment_method',
      'created': 1640995200,
      'metadata': {
        'sessionId': 'session-123',
        'tutorId': 'tutor-456',
      },
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const confirmPaymentIntentResponse = {
    'success': true,
    'data': {
      'id': 'pi_123',
      'amount': PaymentTestConfig.testAmount,
      'currency': PaymentTestConfig.testCurrency,
      'status': 'succeeded',
      'created': 1640995200,
      'metadata': {
        'sessionId': 'session-123',
        'tutorId': 'tutor-456',
      },
      'charges': {
        'data': [
          {
            'id': 'ch_123',
            'amount': PaymentTestConfig.testAmount,
            'currency': PaymentTestConfig.testCurrency,
            'status': 'succeeded',
            'created': 1640995200,
          }
        ],
      },
    },
    'timestamp': '2024-01-01T10:00:30Z',
  };

  // Test subscriptions
  static const tutoringSubscription = {
    'id': 'sub-123',
    'userId': 'student-123',
    'planId': 'tutoring_premium',
    'status': 'active',
    'currentPeriodStart': '2024-01-01T00:00:00Z',
    'currentPeriodEnd': '2024-02-01T00:00:00Z',
    'cancelAtPeriodEnd': false,
    'createdAt': '2024-01-01T00:00:00Z',
    'metadata': {
      'planName': 'Premium Tutoring Plan',
      'features': ['unlimited_sessions', 'priority_support', 'advanced_analytics'],
    },
    'items': {
      'data': [
        {
          'id': 'si_123',
          'price': {
            'id': 'price_123',
            'unitAmount': 9999, // $99.99
            'currency': PaymentTestConfig.testCurrency,
            'recurring': {
              'interval': 'month',
            },
          },
          'quantity': 1,
        },
      ],
    },
  };

  static const subscriptionPlans = {
    'success': true,
    'data': {
      'plans': [
        {
          'id': 'tutoring_basic',
          'name': 'Basic Tutoring',
          'description': 'Basic tutoring services',
          'price': {
            'id': 'price_basic',
            'unitAmount': 2999, // $29.99
            'currency': PaymentTestConfig.testCurrency,
            'recurring': {
              'interval': 'month',
            },
          },
          'features': [
            '5_sessions_per_month',
            'basic_support',
            'standard_tutors',
          ],
          'isPopular': false,
        },
        {
          'id': 'tutoring_premium',
          'name': 'Premium Tutoring',
          'description': 'Premium tutoring services',
          'price': {
            'id': 'price_premium',
            'unitAmount': 9999, // $99.99
            'currency': PaymentTestConfig.testCurrency,
            'recurring': {
              'interval': 'month',
            },
          },
          'features': [
            'unlimited_sessions',
            'priority_support',
            'advanced_analytics',
            'priority_tutors',
          ],
          'isPopular': true,
        },
      ],
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // Payment method responses
  static const savePaymentMethodResponse = {
    'success': true,
    'data': {
      'id': 'pm_123',
      'type': 'card',
      'card': {
        'brand': 'visa',
        'last4': '4242',
        'expMonth': 12,
        'expYear': 2025,
      },
      'isDefault': false,
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const getPaymentMethodsResponse = {
    'success': true,
    'data': {
      'paymentMethods': [
        {
          'id': 'pm_123',
          'type': 'card',
          'card': {
            'brand': 'visa',
            'last4': '4242',
            'expMonth': 12,
            'expYear': 2025,
          },
          'isDefault': true,
        },
        {
          'id': 'pm_456',
          'type': 'card',
          'card': {
            'brand': 'mastercard',
            'last4': '4444',
            'expMonth': 10,
            'expYear': 2026,
          },
          'isDefault': false,
        },
      ],
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // Payout requests (for tutors)
  static const payoutRequest = {
    'amount': 50000, // $500.00
    'currency': PaymentTestConfig.testCurrency,
    'method': 'bank_account',
    'description': 'Monthly tutoring earnings',
    'metadata': {
      'period': 'January 2024',
      'sessionCount': 25,
    },
  };

  static const payoutResponse = {
    'success': true,
    'data': {
      'id': 'po_123',
      'amount': 50000,
      'currency': PaymentTestConfig.testCurrency,
      'status': 'pending',
      'method': 'bank_account',
      'description': 'Monthly tutoring earnings',
      'createdAt': '2024-01-01T10:00:00Z',
      'arrivalDate': '2024-01-04T00:00:00Z',
      'metadata': {
        'period': 'January 2024',
        'sessionCount': 25,
      },
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // Payment history
  static const paymentHistoryResponse = {
    'success': true,
    'data': {
      'transactions': [
        successfulPaymentTransaction,
        pendingPaymentTransaction,
        refundedPaymentTransaction,
      ],
      'totalCount': 3,
      'hasMore': false,
      'currentPage': 1,
      'totalPages': 1,
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // Error responses
  static const paymentFailedResponse = {
    'success': false,
    'error': {
      'code': 'PAYMENT_FAILED',
      'message': 'Payment processing failed',
      'details': {
        'reason': 'card_declined',
        'declineCode': 'insufficient_funds',
      },
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const cardExpiredResponse = {
    'success': false,
    'error': {
      'code': 'CARD_EXPIRED',
      'message': 'The payment method has expired',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const insufficientFundsResponse = {
    'success': false,
    'error': {
      'code': 'INSUFFICIENT_FUNDS',
      'message': 'Insufficient funds for this transaction',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  static const subscriptionNotFoundResponse = {
    'success': false,
    'error': {
      'code': 'SUBSCRIPTION_NOT_FOUND',
      'message': 'Subscription not found',
    },
    'timestamp': '2024-01-01T10:00:00Z',
  };

  // Webhook events
  static const paymentSucceededWebhook = {
    'id': 'evt_123',
    'object': 'event',
    'type': 'payment_intent.succeeded',
    'data': {
      'object': createPaymentIntentResponse['data'],
    },
    'created': 1640995200,
  };

  static const paymentFailedWebhook = {
    'id': 'evt_124',
    'object': 'event',
    'type': 'payment_intent.payment_failed',
    'data': {
      'object': {
        'id': 'pi_failed',
        'amount': PaymentTestConfig.testAmount,
        'currency': PaymentTestConfig.testCurrency,
        'status': 'failed',
        'lastPaymentError': {
          'message': 'Your card was declined',
          'type': 'card_error',
          'code': 'card_declined',
        },
      },
    },
    'created': 1640995200,
  };

  // Helper methods
  static Map<String, dynamic> createPaymentTransaction({
    String? id,
    String? userId,
    double? amount,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return {
      'id': id ?? 'txn-${DateTime.now().millisecondsSinceEpoch}',
      'userId': userId ?? 'student-123',
      'amount': amount ?? PaymentTestConfig.testAmount,
      'currency': PaymentTestConfig.testCurrency,
      'status': status ?? 'pending',
      'paymentMethod': validCreditCard,
      'description': 'Tutoring Session Payment',
      'createdAt': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
      'fees': null,
      'refundStatus': null,
    };
  }

  static Map<String, dynamic> createPaymentResponse({
    bool success = true,
    Map<String, dynamic>? data,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? errorDetails,
  }) {
    if (success) {
      return {
        'success': true,
        'data': data ?? successfulPaymentTransaction,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else {
      return {
        'success': false,
        'error': {
          'code': errorCode ?? 'PAYMENT_ERROR',
          'message': errorMessage ?? 'Payment operation failed',
          ...?errorDetails,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static bool isValidCardNumber(String cardNumber) {
    // Luhn algorithm for card validation
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cardNumber.length < 13 || cardNumber.length > 19) return false;
    
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static bool isValidExpiryDate(int month, int year) {
    final now = DateTime.now();
    final expiry = DateTime(year, month);
    return expiry.isAfter(now);
  }

  static bool isValidCvv(String cvv) {
    return cvv.length >= 3 && cvv.length <= 4 && RegExp(r'^\d+$').hasMatch(cvv);
  }

  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 999999.99;
  }

  static bool isValidCurrency(String currency) {
    const validCurrencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];
    return validCurrencies.contains(currency.toUpperCase());
  }
}