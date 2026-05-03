import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../features/favorites/provider/favorites_provider.dart';
import '../model/deal_model.dart';

const Color _locationTeal = Color(0xFF0F766E);

String dealCardImageUrl(Deal deal) {
  if (deal.images.isNotEmpty) return deal.images.first;
  switch (deal.title) {
    case 'Grilled Meat Platter':
      return 'lib/assets/grilled.jpg';
    case 'Vegan Pastry Box':
      return 'lib/assets/veganpastry.jpg';
    default:
      return 'lib/assets/juicecombo.jpg';
  }
}

String dealCardPickupLine(Deal deal) {
  if (deal.expiryTime == null || deal.expiryTime!.isEmpty) {
    return 'Pick up today — while stock lasts';
  }
  final dt = DateTime.tryParse(deal.expiryTime!);
  if (dt == null) return 'Pick up while supplies last';
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return 'Pick up before $h:$m';
}

String dealCardStoreInitial(Deal deal) {
  final t = deal.title.trim();
  if (t.isEmpty) return '?';
  return t[0].toUpperCase();
}

/// Home / Favorites list card with heart wired to Supabase `deal_favorites`.
class DiscoverDealCard extends ConsumerWidget {
  final Deal deal;

  const DiscoverDealCard({super.key, required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteDealIdsProvider);
    final isFavorite = favoriteIds.contains(deal.id);
    final img = dealCardImageUrl(deal);
    final rating = deal.averageRating ?? 5.0;
    final distanceLabel = deal.subcityName ?? 'Nearby';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/deals/${deal.id}'),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(
                color: AppTheme.divider.withValues(alpha: 0.55),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 172,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (img.startsWith('http'))
                        Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _cardImagePlaceholder(),
                        )
                      else
                        Image.asset(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _cardImagePlaceholder(),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () async {
                              try {
                                await ref
                                    .read(favoriteDealIdsProvider.notifier)
                                    .toggle(deal.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 22,
                                color: isFavorite
                                    ? Colors.redAccent
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                dealCardStoreInitial(deal),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                deal.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.categoryName ?? 'Deal',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dealCardPickupLine(deal),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textMedium,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 16, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              distanceLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ETB ${deal.originalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppTheme.textLight,
                                ),
                              ),
                              Text(
                                'ETB ${deal.discountedPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _locationTeal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _cardImagePlaceholder() {
  return Container(
    color: AppTheme.divider,
    alignment: Alignment.center,
    child: const Icon(Icons.restaurant_rounded,
        color: AppTheme.textLight, size: 48),
  );
}
