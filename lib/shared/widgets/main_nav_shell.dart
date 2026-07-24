import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/fcm_service.dart';
import 'package:mse_market_connect/features/home/presentation/home_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/profile_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/upgrade_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MarketScreen(),
    MyAlertsScreen(), // Watchlist
    ProfileScreen(),
  ];

  // Draggable pill position (initialized after first layout)
  Offset? _pillOffset;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      FCMService().initNotifications();
    }
  }

  void _openUpgrade() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
  }

  void _initPillOffsetIfNeeded(Size size, EdgeInsets padding) {
    if (_pillOffset != null) return;

    // Default: bottom-right above bottom nav
    final defaultX = size.width - 16 - _UpgradePill.width;
    final defaultY =
        size.height -
        padding.bottom -
        kBottomNavigationBarHeight -
        14 -
        _UpgradePill.height;

    _pillOffset = Offset(defaultX, defaultY);
  }

  Offset _clampToSafeArea(Offset raw, Size size, EdgeInsets padding) {
    final minX = 8.0;
    final maxX = size.width - 8 - _UpgradePill.width;

    final minY = padding.top + 8;
    final maxY =
        size.height -
        padding.bottom -
        kBottomNavigationBarHeight -
        8 -
        _UpgradePill.height;

    return Offset(raw.dx.clamp(minX, maxX), raw.dy.clamp(minY, maxY));
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.sizeOf(context);

    _initPillOffsetIfNeeded(size, padding);

    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],

          // Draggable floating "Upgrade" pill across the entire app
          Positioned(
            left: _pillOffset!.dx,
            top: _pillOffset!.dy,
            child: Draggable(
              feedback: Material(
                color: Colors.transparent,
                child: _UpgradePill(onTap: _openUpgrade),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: _UpgradePill(onTap: _openUpgrade),
              ),
              onDragEnd: (details) {
                final newOffset = _clampToSafeArea(
                  details.offset,
                  size,
                  padding,
                );
                setState(() => _pillOffset = newOffset);
              },
              child: _UpgradePill(onTap: _openUpgrade),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _UpgradePill extends StatelessWidget {
  static const double width = 118;
  static const double height = 40;

  final VoidCallback onTap;
  const _UpgradePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.workspace_premium, size: 18, color: Colors.black),
              SizedBox(width: 8),
              Text(
                'Upgrade',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
