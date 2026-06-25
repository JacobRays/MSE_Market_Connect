import 'package:flutter/material.dart';
import 'package:mse_market_connect/core/theme/app_theme.dart';
import 'package:mse_market_connect/core/theme/theme_mode_controller.dart';
import 'package:mse_market_connect/features/auth/presentation/auth_gate.dart';

class MseMarketConnectApp extends StatelessWidget {
  const MseMarketConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'MSE Market Connect',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}
