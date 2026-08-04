class StockModel {
  final int id;
  final String symbol;
  final String companyName;
  final double price;
  final double changePercent;
  final int volume;
  final bool isActive;
  final DateTime? updatedAt;

  final String? logoUrl;

  const StockModel({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.price,
    required this.changePercent,
    required this.volume,
    required this.isActive,
    this.updatedAt,
    this.logoUrl,
  });

  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: (map['id'] as num).toInt(),
      symbol: (map['symbol'] ?? '').toString(),
      companyName: (map['company_name'] ?? '').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      changePercent: (map['change_percent'] as num?)?.toDouble() ?? 0.0,
      volume: (map['volume'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      logoUrl: map['logo_url'] as String?,
    );
  }
}
