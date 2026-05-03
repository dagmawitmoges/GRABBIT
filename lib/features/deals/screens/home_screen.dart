import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../features/auth/provider/auth_provider.dart';
import '../../../features/auth/model/location_model.dart';
import '../../../features/notifications/provider/notifications_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';
import '../provider/deals_provider.dart';
import '../widgets/discover_deal_card.dart';

/// Warm strip under the green header (reference UI — not on gradient).
const Color _creamStrip = Color(0xFFF5F0E8);
const Color _locationTeal = Color(0xFF0F766E);

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

  String _areaTitle(DealsState dealsState, AsyncValue<List<Location>> locAsync) {
    final id = dealsState.filterLocationId;
    if (id == null) return 'All areas';
    return locAsync.maybeWhen(
      data: (list) {
        for (final l in list) {
          if (l.id == id) return l.label;
        }
        return 'Selected area';
      },
      orElse: () => 'Selected area',
    );
  }

  String _locationSubtitle(DealsState dealsState) {
    if (dealsState.filterLocationId == null) {
      return 'Showing deals from every location';
    }
    return 'Deals in your selected area';
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Consumer(
            builder: (_, ref, __) {
              final locAsync = ref.watch(locationsProvider);
              return locAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load locations: $e'),
                ),
                data: (locations) {
                  final maxH = MediaQuery.sizeOf(sheetCtx).height * 0.5;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                        child: Text(
                          'Pick-up area',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxH),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.public_rounded,
                                  color: AppTheme.primary),
                              title: Text(
                                'All areas',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Show deals from every location',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppTheme.textMedium),
                              ),
                              onTap: () {
                                ref
                                    .read(dealsProvider.notifier)
                                    .setLocationFilter(null);
                                Navigator.pop(sheetCtx);
                              },
                            ),
                            const Divider(height: 1),
                            ...locations.map(
                              (loc) => ListTile(
                                leading: const Icon(Icons.place_outlined,
                                    color: _locationTeal),
                                title: Text(
                                  loc.label,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500),
                                ),
                                onTap: () {
                                  ref
                                      .read(dealsProvider.notifier)
                                      .setLocationFilter(loc.id);
                                  Navigator.pop(sheetCtx);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dealsState = ref.watch(dealsProvider);
    final authState = ref.watch(authProvider);
    final locAsync = ref.watch(locationsProvider);
    ref.watch(notificationsListProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final firstName =
        authState.user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(dealsProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Green header — greeting, search, actions only (no location).
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary,
                      AppTheme.primaryDark,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 24,
                  right: 24,
                  bottom: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $firstName 👋',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'What are you craving today?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Material(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () =>
                                      context.push('/notifications'),
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 16, minHeight: 16),
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                authState.user?.fullName.isNotEmpty == true
                                    ? authState.user!.fullName[0]
                                        .toUpperCase()
                                    : 'U',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search deals, restaurants…',
                          hintStyle: GoogleFonts.poppins(
                              color: AppTheme.textLight, fontSize: 15),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.primary, size: 24),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppTheme.textLight),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(dealsProvider.notifier)
                                        .search('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: (val) =>
                            ref.read(dealsProvider.notifier).search(val),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Location row on cream / off-white (reference layout).
            SliverToBoxAdapter(
              child: Material(
                color: _creamStrip,
                child: InkWell(
                  onTap: () => _showLocationPicker(context),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 20, color: _locationTeal),
                            const SizedBox(width: 6),
                            Text(
                              'Current location',
                              style: GoogleFonts.poppins(
                                color: _locationTeal,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: _locationTeal, size: 22),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _areaTitle(dealsState, locAsync),
                          style: GoogleFonts.poppins(
                            color: _locationTeal.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _locationSubtitle(dealsState),
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMedium,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommended for you',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${dealsState.deals.length} deals',
                        style: GoogleFonts.poppins(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (dealsState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 8),
                        Text(dealsState.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(dealsProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

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
                            size: 64, color: AppTheme.textLight),
                        SizedBox(height: 16),
                        Text(
                          'No deals available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back later for new deals',
                          style: TextStyle(color: AppTheme.textMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == dealsState.deals.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
                        ),
                      );
                    }
                    return DiscoverDealCard(deal: dealsState.deals[index]);
                  },
                  childCount: dealsState.deals.length +
                      (dealsState.isLoading && dealsState.deals.isNotEmpty
                          ? 1
                          : 0),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),

            if (dealsState.isLoading && dealsState.deals.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}
