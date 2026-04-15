import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/app_notification_model.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AppNotificationModel>> getMyNotifications({int limit = 50}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List)
        .map((e) => AppNotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
