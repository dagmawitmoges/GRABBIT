import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../deals/model/deal_model.dart';
import '../service/favorites_service.dart';

final favoritesServiceProvider =
    Provider<FavoritesService>((ref) => FavoritesService());

/// Set of deal IDs the current user has favorited.
final favoriteDealIdsProvider =
    StateNotifierProvider<FavoriteIdsNotifier, Set<String>>((ref) {
  return FavoriteIdsNotifier(ref);
});

/// Full [Deal] list for the Favorites tab (refetch after toggles).
final favoriteDealsProvider =
    FutureProvider.autoDispose<List<Deal>>((ref) async {
  final svc = ref.watch(favoritesServiceProvider);
  if (!Env.hasSupabase) return [];
  return svc.fetchFavoriteDeals();
});

class FavoriteIdsNotifier extends StateNotifier<Set<String>> {
  FavoriteIdsNotifier(this._ref) : super({}) {
    Future.microtask(refresh);
  }

  final Ref _ref;

  Future<void> refresh() async {
    if (!Env.hasSupabase) {
      state = {};
      return;
    }
    try {
      final ids =
          await _ref.read(favoritesServiceProvider).fetchFavoriteDealIds();
      state = ids.toSet();
    } catch (_) {
      state = {};
    }
  }

  bool isFavorite(String dealId) => state.contains(dealId);

  Future<void> toggle(String dealId) async {
    if (!Env.hasSupabase) return;

    final add = !state.contains(dealId);
    final svc = _ref.read(favoritesServiceProvider);
    if (add) {
      await svc.addFavorite(dealId);
      state = {...state, dealId};
    } else {
      await svc.removeFavorite(dealId);
      state = {...state}..remove(dealId);
    }
    _ref.invalidate(favoriteDealsProvider);
  }
}
