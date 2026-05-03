import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../model/customer_notification.dart';

class NotificationsService {
  Future<List<CustomerNotification>> listMine() async {
    if (!Env.hasSupabase) return [];
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(100);

    final list = rows as List<dynamic>;
    return list
        .map((e) => CustomerNotification.fromRow(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    if (!Env.hasSupabase) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  Future<void> markAllRead() async {
    if (!Env.hasSupabase) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }

  /// Call after placing an order so the user sees it in the notification center.
  Future<void> insertOrderPlaced({
    required String title,
    required String message,
  }) async {
    if (!Env.hasSupabase) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await Supabase.instance.client.from('notifications').insert({
      'user_id': uid,
      'title': title,
      'message': message,
      'is_read': false,
    });
  }
}
