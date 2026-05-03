import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../deals/model/deal_model.dart';
import '../../deals/service/deals_service.dart';

class FavoritesService {
  Future<List<String>> fetchFavoriteDealIds() async {
    if (!Env.hasSupabase) return [];

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final rows = await Supabase.instance.client
          .from('deal_favorites')
          .select('deal_id')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = rows as List<dynamic>;
      return list
          .map((e) => '${(e as Map)['deal_id']}')
          .where((id) => id.isNotEmpty)
          .toList();
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }

  /// Full deal rows for the favorites list (newest saves first).
  Future<List<Deal>> fetchFavoriteDeals() async {
    if (!Env.hasSupabase) return [];

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return [];

    try {
      final rows = await Supabase.instance.client
          .from('deal_favorites')
          .select(
            'created_at, deals ( '
            'id, title, description, original_price, discounted_price, '
            'quantity_remaining, expiry_time, images, is_active, removed_by_admin, '
            'categories ( name ), locations!location_id ( sub_city, city, country ) '
            ')',
          )
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final list = rows as List<dynamic>;
      final out = <Deal>[];
      for (final raw in list) {
        final m = Map<String, dynamic>.from(raw as Map);
        final embed = m['deals'];
        if (embed is! Map) continue;
        final dealMap = Map<String, dynamic>.from(embed);
        if (dealMap['removed_by_admin'] == true) continue;
        out.add(Deal.fromJson(DealsService.dealRowToJson(dealMap)));
      }
      return out;
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }

  Future<void> addFavorite(String dealId) async {
    if (!Env.hasSupabase) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw 'Sign in to use favorites.';

    try {
      await Supabase.instance.client.from('deal_favorites').insert({
        'user_id': uid,
        'deal_id': dealId,
      });
    } on PostgrestException catch (e) {
      final code = e.code?.toString();
      if (code == '23505') return;
      final msg = e.message.toLowerCase();
      if (msg.contains('duplicate') || msg.contains('unique')) return;
      throw e.message;
    }
  }

  Future<void> removeFavorite(String dealId) async {
    if (!Env.hasSupabase) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) throw 'Sign in to manage favorites.';

    try {
      await Supabase.instance.client
          .from('deal_favorites')
          .delete()
          .eq('user_id', uid)
          .eq('deal_id', dealId);
    } on PostgrestException catch (e) {
      throw e.message;
    }
  }
}
