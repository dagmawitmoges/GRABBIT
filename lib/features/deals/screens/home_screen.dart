import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/provider/auth_provider.dart';
import '../model/deal_model.dart';
import '../provider/deals_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(dealsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealsState = ref.watch(dealsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Grabbit',
          style: TextStyle(
            color: Color(0xFF1DB954),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1DB954),
        onRefresh: () => ref.read(dealsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search deals...',
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(dealsProvider.notifier).search('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (val) =>
                      ref.read(dealsProvider.notifier).search(val),
                ),
              ),
            ),

            // Greeting
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Hello, ${authState.user?.fullName.split(' ').first ?? 'there'} 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Deals near you',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Error state
            if (dealsState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          dealsState.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(dealsProvider.notifier).refresh(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                          ),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Empty state
            if (!dealsState.isLoading &&
                dealsState.deals.isEmpty &&
                dealsState.error == null)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No deals available',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back later for new deals',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Deals grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == dealsState.deals.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        ),
                      );
                    }
                    return _DealCard(deal: dealsState.deals[index]);
                  },
                  childCount: dealsState.deals.length +
                      (dealsState.isLoading && dealsState.deals.isNotEmpty
                          ? 1
                          : 0),
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),

            // Initial loading
            if (dealsState.isLoading && dealsState.deals.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      color: Color(0xFF1DB954),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Orders FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/orders'),
        backgroundColor: const Color(0xFF1DB954),
        icon: const Icon(Icons.receipt_long, color: Colors.white),
        label: const Text('My Orders',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/deals/${deal.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              child: deal.images.isNotEmpty
                  ? Image.network(
                      deal.images.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    deal.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Discount badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${deal.discountPercentage.toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Prices
                  Text(
                    'ETB ${deal.discountedPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1DB954),
                    ),
                  ),
                  Text(
                    'ETB ${deal.originalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Quantity left
                  Text(
                    '${deal.availableQuantity} left',
                    style: TextStyle(
                      fontSize: 11,
                      color: deal.availableQuantity < 5
                          ? Colors.orange
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.storefront_outlined,
          color: Colors.grey, size: 40),
    );
  }
}