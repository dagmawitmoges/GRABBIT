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

  const DealsState({
    this.deals = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.searchQuery = '',
  });

  DealsState copyWith({
    List<Deal>? deals,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    bool clearError = false,
  }) {
    return DealsState(
      deals: deals ?? this.deals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class DealsNotifier extends StateNotifier<DealsState> {
  final DealsService _service;

  DealsNotifier(this._service) : super(const DealsState()) {
    fetchDeals();
  }

  Future<void> fetchDeals({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = const DealsState();
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final deals = await _service.getDeals(
        page: state.currentPage,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
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
    state = DealsState(searchQuery: query);
    await fetchDeals();
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