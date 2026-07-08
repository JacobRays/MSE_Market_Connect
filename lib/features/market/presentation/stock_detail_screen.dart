import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/features/market/presentation/set_price_alert_screen.dart';
import 'package:mse_market_connect/features/trade/presentation/buy_order_screen.dart';
import 'package:mse_market_connect/shared/models/stock_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockDetailScreen extends StatefulWidget {
  final StockModel stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late StockModel _stock;
  late Future<List<_HistoryPoint>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _stock = widget.stock;
    _historyFuture = _loadHistory();
  }

  Future<List<_HistoryPoint>> _loadHistory() async {
    final db = Supabase.instance.client;

    final res = await db
        .from('stock_price_history')
        .select('price, recorded_at')
        .eq('symbol', _stock.symbol)
        .order('recorded_at', ascending: false)
        .limit(30);

    final rows = (res as List).cast<Map<String, dynamic>>();

    final pts = rows.map((r) {
      final price = (r['price'] as num?)?.toDouble() ?? 0.0;
      final recordedAt = DateTime.tryParse((r['recorded_at'] ?? '').toString());
      return _HistoryPoint(price: price, recordedAt: recordedAt);
    }).toList();

    // reverse to chronological order
    return pts.reversed.toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _loadHistory();
    });
    await _historyFuture;

    // Refresh the live stock row too (so detail matches latest)
    final db = Supabase.instance.client;
    final row = await db
        .from('stocks')
        .select(
          'id, symbol, company_name, price, change_percent, volume, is_active, updated_at',
        )
        .eq('symbol', _stock.symbol)
        .maybeSingle();

    if (!mounted) return;
    if (row != null) {
      setState(() {
        _stock = StockModel.fromMap(row as Map<String, dynamic>);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _stock.changePercent >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_stock.symbol),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stock.symbol,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_stock.companyName),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricItem(
                              label: 'Price',
                              value: 'MWK ${_stock.price.toStringAsFixed(2)}',
                            ),
                          ),
                          Expanded(
                            child: _MetricItem(
                              label: 'Change',
                              value:
                                  '${isPositive ? '+' : ''}${_stock.changePercent.toStringAsFixed(2)}%',
                              valueColor: isPositive
                                  ? AppTheme.gainColor
                                  : AppTheme.lossColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MetricItem(
                        label: 'Volume',
                        value: _stock.volume.toString(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Price history chart ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<List<_HistoryPoint>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 140,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 140,
                          child: Center(
                            child: Text(
                              'Failed to load chart:\n${snapshot.error}',
                            ),
                          ),
                        );
                      }

                      final pts = snapshot.data ?? [];
                      if (pts.length < 2) {
                        return const SizedBox(
                          height: 140,
                          child: Center(
                            child: Text(
                              'Not enough history yet.\nSync prices a few times to see a chart.',
                            ),
                          ),
                        );
                      }

                      final values = pts.map((p) => p.price).toList();
                      final minV = values.reduce(math.min);
                      final maxV = values.reduce(math.max);
                      final last = values.last;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Price History',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Last 30 syncs',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            width: double.infinity,
                            child: _Sparkline(
                              values: values,
                              lineColor: AppTheme.primaryColor,
                              fillColor: AppTheme.primaryColor.withOpacity(
                                0.10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _SmallStat(
                                label: 'Min',
                                value: 'MWK ${minV.toStringAsFixed(2)}',
                              ),
                              _SmallStat(
                                label: 'Max',
                                value: 'MWK ${maxV.toStringAsFixed(2)}',
                              ),
                              _SmallStat(
                                label: 'Latest',
                                value: 'MWK ${last.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This app routes order requests to licensed brokers and provides market information. '
                    'It does not execute trades or hold client funds.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SetPriceAlertScreen(
                                stockSymbol: _stock.symbol,
                                companyName: _stock.companyName,
                                currentPrice: _stock.price,
                              ),
                            ),
                          );
                        },
                        child: const Text('Set Price Alert'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BuyOrderScreen(stock: _stock),
                            ),
                          );
                        },
                        child: const Text('Buy Shares'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryPoint {
  final double price;
  final DateTime? recordedAt;
  const _HistoryPoint({required this.price, required this.recordedAt});
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;
  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  const _Sparkline({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        lineColor: lineColor,
        fillColor: fillColor,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.000001 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);

    double yFor(double v) {
      final t = (v - minV) / range; // 0..1
      // invert: higher value is higher on chart
      return size.height - (t * size.height);
    }

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = yFor(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // draw light fill then line
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
