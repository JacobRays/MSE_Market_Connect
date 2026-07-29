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

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  // Draggable pill position (in screen coordinates)
  Offset? _pillOffset;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      FCMService().initNotifications();
    }
  }

  void _openUpgrade() {
    // Push inside the current tab navigator (keeps bottom nav visible)
    final nav = _navKeys[_currentIndex].currentState;
    nav?.push(MaterialPageRoute(builder: (_) => const UpgradeScreen()));
  }

  void _initPillOffsetIfNeeded(Size size, EdgeInsets padding) {
    if (_pillOffset != null) return;

    final defaultX = size.width - 16 - _UpgradePill.width;
    final defaultY =
        size.height -
        padding.bottom -
        kBottomNavigationBarHeight -
        14 -
        _UpgradePill.height;

    _pillOffset = Offset(defaultX, defaultY);
  }

  Offset _clampPill(Offset raw, Size size, EdgeInsets padding) {
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

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_currentIndex].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }

    // If not on Home tab, go to Home first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    return true; // allow app to close
  }

  Widget _tabNavigator({
    required GlobalKey<NavigatorState> key,
    required Widget root,
  }) {
    return Navigator(
      key: key,
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
    // Any pushes from within these screens will stay in this navigator,
    // keeping the bottom nav visible.
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.sizeOf(context);
    _initPillOffsetIfNeeded(size, padding);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _tabNavigator(key: _navKeys[0], root: const HomeScreen()),
                _tabNavigator(key: _navKeys[1], root: const MarketScreen()),
                _tabNavigator(key: _navKeys[2], root: const MyAlertsScreen()),
                _tabNavigator(key: _navKeys[3], root: const ProfileScreen()),
              ],
            ),

            // Draggable upgrade pill (visible on every tab/screen)
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
                  final newOffset = _clampPill(details.offset, size, padding);
                  setState(() => _pillOffset = newOffset);
                },
                child: _UpgradePill(onTap: _openUpgrade),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == _currentIndex) {
              // Tap current tab again => pop to root of that tab
              _navKeys[index].currentState?.popUntil((r) => r.isFirst);
            } else {
              setState(() => _currentIndex = index);
            }
          },
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
