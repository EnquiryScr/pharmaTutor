import 'package:equatable/equatable.dart';
import '../../core/utils/base_model.dart';

/// Payment model
class PaymentModel extends BaseModelWithId {
  final String userId;
  final String sessionId;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String? transactionId;
  final String? gatewayTransactionId;
  final String? gateway;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? refundedAt;
  final String? description;
  final Map<String, dynamic>? gatewayResponse;
  final RefundInfo? refundInfo;

  const PaymentModel({
    required String id,
    required this.userId,
    required this.sessionId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.gatewayTransactionId,
    this.gateway,
    required this.createdAt,
    this.processedAt,
    this.refundedAt,
    this.description,
    this.gatewayResponse,
    this.refundInfo,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod.toString(),
      'status': status.toString(),
      'transactionId': transactionId,
      'gatewayTransactionId': gatewayTransactionId,
      'gateway': gateway,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
      'description': description,
      'gatewayResponse': gatewayResponse,
      'refundInfo': refundInfo?.toJson(),
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['paymentMethod'],
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transactionId'] as String?,
      gatewayTransactionId: json['gatewayTransactionId'] as String?,
      gateway: json['gateway'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
      description: json['description'] as String?,
      gatewayResponse: json['gatewayResponse'] as Map<String, dynamic>?,
      refundInfo: json['refundInfo'] != null
          ? RefundInfo.fromJson(json['refundInfo'])
          : null,
    );
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? sessionId,
    double? amount,
    String? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    String? transactionId,
    String? gatewayTransactionId,
    String? gateway,
    DateTime? createdAt,
    DateTime? processedAt,
    DateTime? refundedAt,
    String? description,
    Map<String, dynamic>? gatewayResponse,
    RefundInfo? refundInfo,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gateway: gateway ?? this.gateway,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      description: description ?? this.description,
      gatewayResponse: gatewayResponse ?? this.gatewayResponse,
      refundInfo: refundInfo ?? this.refundInfo,
    );
  }

  /// Check if payment is successful
  bool get isSuccessful => status == PaymentStatus.completed;

  /// Check if payment is failed
  bool get isFailed => status == PaymentStatus.failed;

  /// Check if payment is refunded
  bool get isRefunded => status == PaymentStatus.refunded;

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        userId,
        sessionId,
        amount,
        currency,
        paymentMethod,
        status,
        transactionId,
        gatewayTransactionId,
        gateway,
        createdAt,
        processedAt,
        refundedAt,
        description,
        gatewayResponse,
        refundInfo,
      ];
}

/// Payment method enum
enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  stripe,
  bankTransfer,
  applePay,
  googlePay,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  partialRefund,
}

/// Payment method model
class PaymentMethodModel extends BaseModelWithId {
  final String userId;
  final String type;
  final String? last4;
  final String? brand;
  final String? expiryMonth;
  final String? expiryYear;
  final bool isDefault;
  final String? cardholderName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentMethodModel({
    required String id,
    required this.userId,
    required this.type,
    this.last4,
    this.brand,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    this.cardholderName,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
      'cardholderName': cardholderName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      last4: json['last4'] as String?,
      brand: json['brand'] as String?,
      expiryMonth: json['expiryMonth'] as String?,
      expiryYear: json['expiryYear'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      cardholderName: json['cardholderName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
    String? cardholderName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
      cardholderName: cardholderName ?? this.cardholderName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get masked card number for display
  String get maskedCardNumber {
    if (last4 == null) return '****';
    return '**** **** **** $last4';
  }

  /// Get formatted expiry date
  String get formattedExpiryDate {
    if (expiryMonth == null || expiryYear == null) return '';
    return '$expiryMonth/$expiryYear';
  }

  /// Check if card is expired
  bool get isExpired {
    if (expiryMonth == null || expiryYear == null) return false;
    final now = DateTime.now();
    final expiryDate = DateTime(
      int.parse(expiryYear!),
      int.parse(expiryMonth!),
    );
    return now.isAfter(expiryDate);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        last4,
        brand,
        expiryMonth,
        expiryYear,
        isDefault,
        cardholderName,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Payment result model
class PaymentResult extends BaseModel with EquatableMixin {
  final bool success;
  final String? message;
  final String? paymentId;
  final String? transactionId;
  final String? gatewayResponse;
  final Map<String, dynamic>? additionalData;

  const PaymentResult({
    required this.success,
    this.message,
    this.paymentId,
    this.transactionId,
    this.gatewayResponse,
    this.additionalData,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'paymentId': paymentId,
      'transactionId': transactionId,
      'gatewayResponse': gatewayResponse,
      'additionalData': additionalData,
    };
  }

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool,
      message: json['message'] as String?,
      paymentId: json['paymentId'] as String?,
      transactionId: json['transactionId'] as String?,
      gatewayResponse: json['gatewayResponse'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        success,
        message,
        paymentId,
        transactionId,
        gatewayResponse,
        additionalData,
      ];
}

/// Refund info model
class RefundInfo extends BaseModel with EquatableMixin {
  final String refundId;
  final double refundAmount;
  final String reason;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final RefundStatus status;
  final String? gatewayRefundId;

  const RefundInfo({
    required this.refundId,
    required this.refundAmount,
    required this.reason,
    required this.requestedAt,
    this.processedAt,
    this.status = RefundStatus.pending,
    this.gatewayRefundId,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'refundId': refundId,
      'refundAmount': refundAmount,
      'reason': reason,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'status': status.toString(),
      'gatewayRefundId': gatewayRefundId,
    };
  }

  factory RefundInfo.fromJson(Map<String, dynamic> json) {
    return RefundInfo(
      refundId: json['refundId'] as String,
      refundAmount: (json['refundAmount'] as num).toDouble(),
      reason: json['reason'] as String,
      requestedAt: DateTime.parse(json['requestedAt']),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'])
          : null,
      status: RefundStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => RefundStatus.pending,
      ),
      gatewayRefundId: json['gatewayRefundId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        refundId,
        refundAmount,
        reason,
        requestedAt,
        processedAt,
        status,
        gatewayRefundId,
      ];
}

/// Refund status enum
enum RefundStatus {
  pending,
  processing,
  completed,
  failed,
  rejected,
}

/// Refund request model
class RefundRequest extends BaseModelWithId {
  final String paymentId;
  final String userId;
  final double refundAmount;
  final String reason;
  final String? description;
  final DateTime requestedAt;
  final RefundStatus status;
  final String? adminResponse;
  final String? adminNotes;

  const RefundRequest({
    required String id,
    required this.paymentId,
    required this.userId,
    required this.refundAmount,
    required this.reason,
    this.description,
    required this.requestedAt,
    this.status = RefundStatus.pending,
    this.adminResponse,
    this.adminNotes,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'userId': userId,
      'refundAmount': refundAmount,
      'reason': reason,
      'description': description,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.toString(),
      'adminResponse': adminResponse,
      'adminNotes': adminNotes,
    };
  }

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] as String,
      paymentId: json['paymentId'] as String,
      userId: json['userId'] as String,
      refundAmount: (json['refundAmount'] as num).toDouble(),
      reason: json['reason'] as String,
      description: json['description'] as String?,
      requestedAt: DateTime.parse(json['requestedAt']),
      status: RefundStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => RefundStatus.pending,
      ),
      adminResponse: json['adminResponse'] as String?,
      adminNotes: json['adminNotes'] as String?,
    );
  }

  RefundRequest copyWith({
    String? id,
    String? paymentId,
    String? userId,
    double? refundAmount,
    String? reason,
    String? description,
    DateTime? requestedAt,
    RefundStatus? status,
    String? adminResponse,
    String? adminNotes,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      userId: userId ?? this.userId,
      refundAmount: refundAmount ?? this.refundAmount,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        paymentId,
        userId,
        refundAmount,
        reason,
        description,
        requestedAt,
        status,
        adminResponse,
        adminNotes,
      ];
}

/// Invoice model
class InvoiceModel extends BaseModelWithId {
  final String invoiceNumber;
  final String userId;
  final String paymentId;
  final double amount;
  final String currency;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? description;
  final List<InvoiceItem> items;
  final double tax;
  final double discount;
  final InvoiceStatus status;

  const InvoiceModel({
    required String id,
    required this.invoiceNumber,
    required this.userId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    required this.issueDate,
    required this.dueDate,
    this.description,
    this.items = const [],
    this.tax = 0.0,
    this.discount = 0.0,
    this.status = InvoiceStatus.pending,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'userId': userId,
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'tax': tax,
      'discount': discount,
      'status': status.toString(),
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      userId: json['userId'] as String,
      paymentId: json['paymentId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      issueDate: DateTime.parse(json['issueDate']),
      dueDate: DateTime.parse(json['dueDate']),
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      tax: json['tax'] as double? ?? 0.0,
      discount: json['discount'] as double? ?? 0.0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => InvoiceStatus.pending,
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        userId,
        paymentId,
        amount,
        currency,
        issueDate,
        dueDate,
        description,
        items,
        tax,
        discount,
        status,
      ];
}

/// Invoice item model
class InvoiceItem extends BaseModel with EquatableMixin {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [description, quantity, unitPrice, totalPrice];
}

/// Invoice status enum
enum InvoiceStatus {
  pending,
  paid,
  overdue,
  cancelled,
}