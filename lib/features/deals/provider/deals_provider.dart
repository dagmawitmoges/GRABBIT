import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/deal_model.dart';
import '../model/review_model.dart';
import '../service/deals_service.dart';

// Service
final dealsServiceProvider =
    Provider<DealsService>((ref) => DealsService());

// Deals list state
class DealsState {
  final List<Deal> deals;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  /// When set, only deals in this area are listed (matches `deals.location_id`).
  final String? filterLocationId;

  const DealsState({
    this.deals = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.searchQuery = '',
    this.filterLocationId,
  });

  DealsState copyWith({
    List<Deal>? deals,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    String? filterLocationId,
    bool clearError = false,
  }) {
    return DealsState(
      deals: deals ?? this.deals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterLocationId: filterLocationId ?? this.filterLocationId,
    );
  }
}

class DealsNotifier extends StateNotifier<DealsState> {
  final DealsService _service;

  DealsNotifier(this._service) : super(const DealsState()) {
    fetchDeals();
  }

  Future<void> fetchDeals({bool refresh = false}) async {
    // Don't skip refresh just because a pagination request is in flight.
    if (state.isLoading && !refresh) return;

    if (refresh) {
      state = DealsState(
        searchQuery: state.searchQuery,
        filterLocationId: state.filterLocationId,
      );
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final deals = await _service.getDeals(
        page: state.currentPage,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        locationId: state.filterLocationId,
      );

      state = state.copyWith(
        deals: refresh ? deals : [...state.deals, ...deals],
        isLoading: false,
        hasMore: deals.length == 10,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = DealsState(
      searchQuery: query,
      filterLocationId: state.filterLocationId,
    );
    await fetchDeals();
  }

  Future<void> setLocationFilter(String? locationId) {
    state = DealsState(
      searchQuery: state.searchQuery,
      filterLocationId: locationId,
    );
    return fetchDeals(refresh: true);
  }

  Future<void> refresh() async {
    await fetchDeals(refresh: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchDeals();
  }
}

final dealsProvider =
    StateNotifierProvider<DealsNotifier, DealsState>(
  (ref) => DealsNotifier(ref.watch(dealsServiceProvider)),
);

// Single deal provider
final dealDetailProvider =
    FutureProvider.family<Deal, String>((ref, id) async {
  return ref.read(dealsServiceProvider).getDealById(id);
});

// Reviews provider
final dealReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, dealId) async {
  return ref.read(dealsServiceProvider).getDealReviews(dealId);
});