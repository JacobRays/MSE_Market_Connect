import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/shared/models/ad_model.dart';

class AdCarousel extends StatefulWidget {
  final List<AdModel> ads;

  /// If true, ads without imageUrl are ignored (recommended).
  final bool hideMissingImages;

  const AdCarousel({
    super.key,
    required this.ads,
    this.hideMissingImages = true,
  });

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  List<AdModel> get _items {
    final ads = widget.ads;
    if (!widget.hideMissingImages) return ads;
    return ads.where((a) => (a.imageUrl ?? '').trim().isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _restart();
  }

  @override
  void didUpdateWidget(covariant AdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ads.length != widget.ads.length) {
      _index = 0;
      if (_controller.hasClients) _controller.jumpToPage(0);
      _restart();
    }
  }

  void _restart() {
    _timer?.cancel();
    final items = _items;
    if (items.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;

      final items2 = _items;
      if (items2.length <= 1) return;

      _index = (_index + 1) % items2.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    if (items.isEmpty) {
      return const _AdCard(
        title: 'Advertise Here',
        subtitle: 'Reach all MSE investors',
        imageUrl: null,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _AdCard(
              title: items[i].title,
              subtitle: items[i].subtitle ?? 'Sponsored',
              imageUrl: items[i].imageUrl,
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: active ? 18 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;

  const _AdCard({required this.title, required this.subtitle, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned.fill(
            child: (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: AppTheme.primaryColor),
                  )
                : Container(color: AppTheme.primaryColor),
          ),
          Container(color: Colors.black38),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
