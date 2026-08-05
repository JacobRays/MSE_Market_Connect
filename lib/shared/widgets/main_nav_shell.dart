import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/services/fcm_service.dart';
import 'package:mse_market_connect/features/home/presentation/home_screen.dart';
import 'package:mse_market_connect/features/market/presentation/market_screen.dart';
import 'package:mse_market_connect/features/market/presentation/my_alerts_screen.dart';
import 'package:mse_market_connect/features/profile/presentation/profile_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _currentIndex = 0;

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      FCMService().initNotifications();
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _tabNavigator(key: _navKeys[0], root: const HomeScreen()),
            _tabNavigator(key: _navKeys[1], root: const MarketScreen()),
            _tabNavigator(key: _navKeys[2], root: const MyAlertsScreen()),
            _tabNavigator(key: _navKeys[3], root: const ProfileScreen()),
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
