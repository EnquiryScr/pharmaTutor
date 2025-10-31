import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/payment_model.dart';

/// Supabase data source for payment-related operations
class PaymentSupabaseDataSource {
  final SupabaseClient _supabase;

  PaymentSupabaseDataSource(this._supabase);

  // Create a new payment record
  Future<PaymentModel> createPayment({
    required String userId,
    required double amount,
    required String currency,
    required String status,
    String? paymentMethod,
    String? sessionId,
    String? courseId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from('payments')
          .insert({
            'user_id': userId,
            'amount': amount,
            'currency': currency,
            'status': status,
            'payment_method': paymentMethod,
            'session_id': sessionId,
            'course_id': courseId,
            'metadata': metadata,
          })
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPayment(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('''
            *,
            user:profiles!payments_user_id_fkey(id, full_name, email),
            session:sessions(id, start_time, end_time, subject),
            course:courses(id, title)
          ''')
          .eq('id', paymentId)
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  // Get payments for a user
  Future<List<PaymentModel>> getUserPayments({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('payments')
          .select('''
            *,
            session:sessions(id, start_time, end_time, subject),
            course:courses(id, title)
          ''')
          .eq('user_id', userId);

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      final response = await queryBuilder
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user payments: $e');
    }
  }

  // Get payments for a session
  Future<List<PaymentModel>> getSessionPayments(String sessionId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get session payments: $e');
    }
  }

  // Get payments for a course
  Future<List<PaymentModel>> getCoursePayments(String courseId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('course_id', courseId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get course payments: $e');
    }
  }

  // Update payment status
  Future<PaymentModel> updatePaymentStatus({
    required String paymentId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (metadata != null) {
        updates['metadata'] = metadata;
      }

      final response = await _supabase
          .from('payments')
          .update(updates)
          .eq('id', paymentId)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get total earnings for a tutor
  Future<double> getTutorEarnings({
    required String tutorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('payments')
          .select('amount')
          .eq('status', 'completed');

      // Join with sessions to filter by tutor
      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      final response = await _supabase.rpc('get_tutor_earnings', params: {
        'tutor_id': tutorId,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });

      return (response ?? 0.0) as double;
    } catch (e) {
      throw Exception('Failed to get tutor earnings: $e');
    }
  }

  // Get payment statistics for a user
  Future<Map<String, dynamic>> getPaymentStatistics(String userId) async {
    try {
      final response = await _supabase.rpc('get_payment_statistics', params: {
        'user_id': userId,
      });

      return response ?? {};
    } catch (e) {
      throw Exception('Failed to get payment statistics: $e');
    }
  }

  // Add payment method
  Future<Map<String, dynamic>> addPaymentMethod({
    required String userId,
    required String type,
    required String lastFour,
    bool isDefault = false,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .insert({
            'user_id': userId,
            'type': type,
            'last_four': lastFour,
            'is_default': isDefault,
            'metadata': metadata,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  // Get user's payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  // Update payment method
  Future<Map<String, dynamic>> updatePaymentMethod({
    required String paymentMethodId,
    bool? isDefault,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (isDefault != null) {
        updates['is_default'] = isDefault;
        
        // If setting as default, unset all other payment methods for this user
        if (isDefault) {
          final paymentMethod = await _supabase
              .from('payment_methods')
              .select('user_id')
              .eq('id', paymentMethodId)
              .single();

          await _supabase
              .from('payment_methods')
              .update({'is_default': false})
              .eq('user_id', paymentMethod['user_id'])
              .neq('id', paymentMethodId);
        }
      }

      if (metadata != null) {
        updates['metadata'] = metadata;
      }

      final response = await _supabase
          .from('payment_methods')
          .update(updates)
          .eq('id', paymentMethodId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update payment method: $e');
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _supabase
          .from('payment_methods')
          .delete()
          .eq('id', paymentMethodId);
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Get payment method by ID
  Future<Map<String, dynamic>?> getPaymentMethod(String paymentMethodId) async {
    try {
      final response = await _supabase
          .from('payment_methods')
          .select()
          .eq('id', paymentMethodId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to get payment method: $e');
    }
  }

  // Process refund (creates a new payment record with negative amount)
  Future<PaymentModel> processRefund({
    required String originalPaymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      // Get original payment
      final originalPayment = await getPayment(originalPaymentId);
      if (originalPayment == null) {
        throw Exception('Original payment not found');
      }

      // Create refund payment
      final response = await _supabase
          .from('payments')
          .insert({
            'user_id': originalPayment.userId,
            'amount': -amount,
            'currency': originalPayment.currency,
            'status': 'refunded',
            'payment_method': originalPayment.paymentMethod,
            'session_id': originalPayment.sessionId,
            'course_id': originalPayment.courseId,
            'metadata': {
              'refund_reason': reason,
              'original_payment_id': originalPaymentId,
            },
          })
          .select()
          .single();

      // Update original payment status
      await updatePaymentStatus(
        paymentId: originalPaymentId,
        status: 'refunded',
        metadata: {
          'refund_payment_id': response['id'],
          'refund_amount': amount,
          'refund_reason': reason,
        },
      );

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Real-time subscription to payment updates
  RealtimeChannel subscribeToPayment(
    String paymentId,
    void Function(PaymentModel) onUpdate,
  ) {
    return _supabase
        .channel('payment_$paymentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: paymentId,
          ),
          callback: (payload) {
            if (payload.newRecord != null) {
              onUpdate(PaymentModel.fromJson(payload.newRecord!));
            }
          },
        )
        .subscribe();
  }

  // Subscribe to user's payments (for real-time updates)
  RealtimeChannel subscribeToUserPayments(
    String userId,
    void Function(PaymentModel) onInsert,
    void Function(PaymentModel) onUpdate,
  ) {
    final channel = _supabase.channel('user_payments_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'payments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onInsert(PaymentModel.fromJson(payload.newRecord!));
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'payments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord != null) {
          onUpdate(PaymentModel.fromJson(payload.newRecord!));
        }
      },
    );

    return channel.subscribe();
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
