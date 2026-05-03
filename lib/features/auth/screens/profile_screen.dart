import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../model/auth_models.dart';
import '../provider/auth_provider.dart';
import '../provider/profile_screen_data_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

/// Reference-style profile: light surface, white cards, mint icon chips, centered title.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _avatarGreen = Color(0xFF1B4D3E);
  static const Color _pageBg = Color(0xFFF2F4F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final extrasAsync = ref.watch(profileScreenDataProvider);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'My profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        foregroundColor: AppTheme.textDark,
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                ref.invalidate(profileScreenDataProvider);
                await ref.read(profileScreenDataProvider.future);
              },
              child: extrasAsync.when(
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _ProfileOverviewCard(
                      user: user,
                      data: null,
                      avatarGreen: _avatarGreen,
                    ),
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _ProfileOverviewCard(
                      user: user,
                      data: null,
                      avatarGreen: _avatarGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$e',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                data: (data) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _ProfileOverviewCard(
                      user: user,
                      data: data,
                      avatarGreen: _avatarGreen,
                    ),
                    const SizedBox(height: 16),
                    _MemberSinceCard(memberSince: data?.memberSince),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Contact information',
                      children: [
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: data?.hasVendorProfile == true
                              ? (data!.vendorPhone?.isNotEmpty == true
                                  ? data.vendorPhone!
                                  : user.phone ?? '—')
                              : (user.phone ?? '—'),
                        ),
                        _DetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        _DetailRow(
                          icon: Icons.place_outlined,
                          label: 'Location',
                          value: _locationLine(data, user),
                        ),
                        if (data?.branchAddressDetail != null &&
                            data!.branchAddressDetail!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.home_outlined,
                            label: 'Address',
                            value: data.branchAddressDetail!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (data?.hasVendorProfile == true) ...[
                      _SectionCard(
                        title: 'Business details',
                        children: [
                          _DetailRow(
                            icon: Icons.numbers_outlined,
                            label: 'TIN',
                            value: data!.tin?.isNotEmpty == true
                                ? data.tin!
                                : '—',
                          ),
                          _DetailRow(
                            icon: Icons.storefront_outlined,
                            label: 'Business type',
                            value: user.role.toUpperCase(),
                          ),
                          _DetailRow(
                            icon: Icons.event_outlined,
                            label: 'Joined',
                            value: _formatMemberDate(
                              _parseVendorDate(data.vendorRow?['created_at']) ??
                                  data.memberSince,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _SectionCard(
                        title: 'Account',
                        children: [
                          _DetailRow(
                            icon: Icons.verified_outlined,
                            label: 'Status',
                            value: user.isVerified ? 'Verified' : 'Not verified',
                            valueColor: user.isVerified
                                ? AppTheme.primary
                                : Colors.orange,
                          ),
                          _DetailRow(
                            icon: Icons.badge_outlined,
                            label: 'Role',
                            value: user.role.toUpperCase(),
                          ),
                          _DetailRow(
                            icon: Icons.event_outlined,
                            label: 'Member since',
                            value: _formatMemberDate(data?.memberSince),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const _ShortcutsCard(),
                    const SizedBox(height: 24),
                    _SignOutBar(),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Grabbit v1.0.0',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  static String _locationLine(ProfileScreenData? data, AuthUser user) {
    if (data?.hasVendorProfile == true &&
        data!.vendorLocationText != null &&
        data.vendorLocationText!.trim().isNotEmpty) {
      final v = data.vendorLocationText!.trim();
      final p = data.locationCityLabel?.trim();
      if (p != null && p.isNotEmpty) return '$v · $p';
      return v;
    }
    if (data?.locationCityLabel != null &&
        data!.locationCityLabel!.isNotEmpty) {
      return data.locationCityLabel!;
    }
    return '—';
  }

  static DateTime? _parseVendorDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  static String _formatMemberDate(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final mo = months[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    return '$mo $day, ${local.year}';
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  final AuthUser user;
  final ProfileScreenData? data;
  final Color avatarGreen;

  const _ProfileOverviewCard({
    required this.user,
    required this.data,
    required this.avatarGreen,
  });

  String _initials() {
    final name = user.fullName.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = data?.hasVendorProfile == true;
    final business = data?.businessName?.trim();
    final title = (isVendor && business != null && business.isNotEmpty)
        ? business
        : user.fullName;
    final subtitle =
        (isVendor && business != null && business.isNotEmpty) ? user.fullName : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: avatarGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSinceCard extends StatelessWidget {
  final DateTime? memberSince;

  const _MemberSinceCard({required this.memberSince});

  @override
  Widget build(BuildContext context) {
    final dateStr = ProfileScreen._formatMemberDate(memberSince);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text(
            dateStr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: dateStr.length > 12 ? 15 : 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Member since',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryDark, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
            title: Text(
              'My orders',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
            onTap: () => context.go('/orders'),
          ),
          Divider(height: 1, indent: 56, color: AppTheme.divider),
          ListTile(
            leading: Icon(Icons.storefront_outlined, color: AppTheme.primary),
            title: Text(
              'Browse deals',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textLight),
            onTap: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _SignOutBar extends ConsumerWidget {
  const _SignOutBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Sign out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(authProvider.notifier).logout();
                    context.go('/welcome');
                  },
                  child: const Text(
                    'Sign out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Color(0xFFE57373)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 22),
        label: Text(
          'Sign out',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
