class HoldingModel {
  final String symbol;
  final String companyName;
  final int shares;
  final double avgCost;

  final double currentPrice;
  final double changePercent; // from stocks.change_percent

  HoldingModel({
    required this.symbol,
    required this.companyName,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    required this.changePercent,
  });

  double get marketValue => shares * currentPrice;
  double get totalCost => shares * avgCost;
  double get gainLoss => marketValue - totalCost;
  double get gainLossPercent =>
      totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;

  HoldingModel copyWith({double? currentPrice, double? changePercent}) {
    return HoldingModel(
      symbol: symbol,
      companyName: companyName,
      shares: shares,
      avgCost: avgCost,
      currentPrice: currentPrice ?? this.currentPrice,
      changePercent: changePercent ?? this.changePercent,
    );
  }
}
