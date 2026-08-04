class TradeOrderModel {
  final String id;
  final String stockSymbol; // e.g. 'AHL'
  final String side; // 'buy' | 'sell'
  final int quantity;
  final String status;

  final String brokerId;
  final String? brokerName;

  final double? totalEstimate;

  final String?
  rejectReason; // optional: reason from broker when status == 'rejected'

  final DateTime createdAt;
  final DateTime updatedAt;

  const TradeOrderModel({
    required this.id,
    required this.stockSymbol,
    required this.side,
    required this.quantity,
    required this.status,
    required this.brokerId,
    required this.createdAt,
    required this.updatedAt,
    this.brokerName,
    this.totalEstimate,
    this.rejectReason,
  });

  factory TradeOrderModel.fromMap(Map<String, dynamic> map) {
    String? rr = map['reject_reason'] as String?;
    rr ??= map['rejection_reason'] as String?;
    rr ??= map['broker_reason'] as String?;
    rr ??= map['reason'] as String?;

    return TradeOrderModel(
      id: map['id'] as String,
      stockSymbol: map['stock_symbol'] as String,
      side: map['side'] as String,
      quantity: (map['quantity'] as num).toInt(),
      status: (map['status'] as String?) ?? 'submitted',
      brokerId: map['broker_id'] as String,
      totalEstimate: (map['total_estimate'] as num?)?.toDouble(),
      rejectReason: rr,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TradeOrderModel copyWith({String? brokerName, String? rejectReason}) {
    return TradeOrderModel(
      id: id,
      stockSymbol: stockSymbol,
      side: side,
      quantity: quantity,
      status: status,
      brokerId: brokerId,
      brokerName: brokerName ?? this.brokerName,
      totalEstimate: totalEstimate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
