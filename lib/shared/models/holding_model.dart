class HoldingModel {
  final String symbol;
  final int shares;
  final double avgCost;
  final double currentPrice;
  final String companyName;

  HoldingModel({
    required this.symbol,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
    required this.companyName,
  });

  double get marketValue => shares * currentPrice;
  double get totalCost => shares * avgCost;
  double get gainLoss => marketValue - totalCost;
  double get gainLossPercent => totalCost > 0 ? (gainLoss / totalCost) * 100 : 0;
}
