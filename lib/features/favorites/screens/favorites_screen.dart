import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../../deals/widgets/discover_deal_card.dart';
import '../provider/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDeals = ref.watch(favoriteDealsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Favorites',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await ref.read(favoriteDealIdsProvider.notifier).refresh();
          ref.invalidate(favoriteDealsProvider);
        },
        child: asyncDeals.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text('$e', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(favoriteDealsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (deals) {
            if (deals.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border_rounded,
                              size: 40,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart on a deal to add it here',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textMedium,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () => context.go('/home'),
                            child: const Text('Browse deals'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: deals.length,
              itemBuilder: (context, i) => DiscoverDealCard(deal: deals[i]),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
