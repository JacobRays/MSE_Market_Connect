import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final _db = Supabase.instance.client;
  final _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Request Permission (Required for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    }

    // 3. Listen for token refreshes
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    String deviceType = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');

    await _db.from('user_device_tokens').upsert({
      'fcm_token': token,
      'user_id': user.id,
      'device_type': deviceType,
    });
  }
}
