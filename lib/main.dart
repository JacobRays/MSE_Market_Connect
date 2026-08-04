import 'package:flutter/material.dart';
import 'package:mse_market_connect/shared/utils/error_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/constants/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorOverlay();

  // Minimal Init
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    print("Supabase Init Error: $e");
  }

  runApp(const MseMarketConnectApp());
}
