class StockModel {
  final int id;
  final String symbol;
  final String companyName;
  final double price;
  final double changePercent;
  final int volume;
  final bool isActive;
  final DateTime? updatedAt;

  const StockModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.isActive,
    this.updatedAt,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id'] as int,
      symbol: map['symbol'] as String,
      companyName: map['company_name'] as String,
      price: (map['price'] as num).toDouble(),
      changePercent: (map['change_percent'] as num).toDouble(),
      volume: (map['volume'] as num).toInt(),
      isActive: map['is_active'] as bool? ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}
