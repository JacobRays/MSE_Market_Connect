import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FCMService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> initNotifications() async {
    // Codespaces preview is Web: do not run FCM there.
    if (kIsWeb) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null) {
          await _saveTokenToSupabase(token);
        }
      }

      messaging.onTokenRefresh.listen((token) async {
        await _saveTokenToSupabase(token);
      });
    } catch (e, st) {
      debugPrint('FCM init failed: $e');
      debugPrint('$st');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    final deviceType = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };

    await _db.from('user_device_tokens').upsert({
      'fcm_token': token,
      'user_id': user.id,
      'device_type': deviceType,
    });
  }
}
