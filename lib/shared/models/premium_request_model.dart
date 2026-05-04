class PremiumRequestModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String? payerReference;
  final String receiptPath;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  const PremiumRequestModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.receiptPath,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.payerReference,
    this.adminNote,
  });

  factory PremiumRequestModel.fromMap(Map<String, dynamic> map) {
    return PremiumRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? 'MWK',
      paymentMethod: map['payment_method'] as String?,
      payerReference: map['payer_reference'] as String?,
      receiptPath: map['receipt_path'] as String,
      status: (map['status'] as String?) ?? 'pending',
      adminNote: map['admin_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
