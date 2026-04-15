class PriceAlertModel {
  final int id;
  final String stockSymbol;
  final String alertType; // buy | sell
  final String condition; // gte | lte
  final double targetPrice;
  final bool isActive;
  final DateTime? triggeredAt;
  final DateTime createdAt;

  // Embedded stock info (optional)
  final String? companyName;
  final double? currentPrice;
  final double? changePercent;

  const PriceAlertModel({
    required this.id,
    required this.stockSymbol,
    required this.alertType,
    required this.condition,
    required this.targetPrice,
    required this.isActive,
    required this.createdAt,
    this.triggeredAt,
    this.companyName,
    this.currentPrice,
    this.changePercent,
  });

  factory PriceAlertModel.fromMap(Map<String, dynamic> map) {
    final stock = map['stocks'];
    final stockMap = stock is Map<String, dynamic> ? stock : null;

    return PriceAlertModel(
      id: (map['id'] as num).toInt(),
      stockSymbol: map['stock_symbol'] as String,
      alertType: map['alert_type'] as String,
      condition: map['condition'] as String,
      targetPrice: (map['target_price'] as num).toDouble(),
      isActive: map['is_active'] as bool? ?? true,
      triggeredAt: map['triggered_at'] != null
          ? DateTime.tryParse(map['triggered_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      companyName: stockMap?['company_name'] as String?,
      currentPrice: (stockMap?['price'] as num?)?.toDouble(),
      changePercent: (stockMap?['change_percent'] as num?)?.toDouble(),
    );
  }

  bool get isBuy => alertType == 'buy';
}
