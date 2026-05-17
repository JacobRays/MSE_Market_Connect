import 'package:supabase_flutter/supabase_flutter.dart';

class SupportService {
  final _db = Supabase.instance.client;

  Future<void> submitTicket(String subject, String message) async {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Not logged in');

    await _db.from('support_tickets').insert({
      'user_id': user.id,
      'subject': subject,
      'message': message,
    });
  }

  Future<List<Map<String, dynamic>>> getMyTickets() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final response = await _db
        .from('support_tickets')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    return (response as List).cast<Map<String, dynamic>>();
  }
}
