import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mse_market_connect/shared/models/notification_model.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<NotificationModel>> getMyNotifications({int limit = 50}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(int id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not logged in');

    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', user.id)
        .isFilter('read_at', null);
  }
}
