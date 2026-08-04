class TradeOrderModel {
  final String id;
  final String stockSymbol;
  final String side; // buy|sell
  final int quantity;
  final String status;

  final String brokerId;
  final String? brokerName;

  final double? totalEstimate;

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
  });

  factory TradeOrderModel.fromMap(Map<String, dynamic> map) {
    return TradeOrderModel(
      id: map['id'] as String,
      stockSymbol: map['stock_symbol'] as String,
      side: map['side'] as String,
      quantity: (map['quantity'] as num).toInt(),
      status: (map['status'] as String?) ?? 'submitted',
      brokerId: map['broker_id'] as String,
      totalEstimate: (map['total_estimate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  TradeOrderModel copyWith({String? brokerName}) {
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
    );
  }
}
