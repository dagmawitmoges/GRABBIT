import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import 'auth_provider.dart';

/// Extra rows for the profile UI (member date, vendor business, optional address).
class ProfileScreenData {
  final DateTime? memberSince;
  final Map<String, dynamic>? vendorRow;
  final String? locationCityLabel;
  final String? branchAddressDetail;

  const ProfileScreenData({
    required this.memberSince,
    this.vendorRow,
    this.locationCityLabel,
    this.branchAddressDetail,
  });

  bool get hasVendorProfile => vendorRow != null;

  String? get businessName => vendorRow?['business_name'] as String?;
  String? get vendorPhone => vendorRow?['phone'] as String?;
  String? get vendorLocationText => vendorRow?['location'] as String?;
  String? get tin => vendorRow?['tin'] as String?;
}

final profileScreenDataProvider =
    FutureProvider.autoDispose<ProfileScreenData?>((ref) async {
  if (!Env.hasSupabase) {
    return const ProfileScreenData(memberSince: null);
  }
  final user = ref.watch(authProvider).user;
  if (user == null) return null;

  final pid = user.id;

  DateTime? memberSince;
  String? locLabel;

  try {
    final prof = await Supabase.instance.client
        .from('profiles')
        .select('created_at, location_id')
        .eq('id', pid)
        .maybeSingle();

    if (prof != null) {
      final ca = prof['created_at'];
      if (ca != null) {
        memberSince = DateTime.tryParse(ca.toString())?.toUtc();
      }
      final lid = prof['location_id']?.toString();
      if (lid != null && lid.isNotEmpty) {
        final loc = await Supabase.instance.client
            .from('locations')
            .select('sub_city, city, country')
            .eq('id', lid)
            .maybeSingle();
        if (loc != null) {
          final sc = loc['sub_city']?.toString().trim() ?? '';
          final c = loc['city']?.toString().trim() ?? '';
          final co = loc['country']?.toString().trim() ?? '';
          locLabel = [sc, c, co].where((e) => e.isNotEmpty).join(', ');
        }
      }
    }
  } catch (_) {}

  Map<String, dynamic>? vRow;
  try {
    final v = await Supabase.instance.client
        .from('vendor_profiles')
        .select()
        .eq('user_id', pid)
        .maybeSingle();
    if (v != null) vRow = Map<String, dynamic>.from(v);
  } catch (_) {}

  String? addressDetail;
  try {
    final row = await Supabase.instance.client
        .from('vendor_branches')
        .select('address_detail')
        .eq('vendor_user_id', pid)
        .limit(1)
        .maybeSingle();
    if (row != null) {
      final ad = row['address_detail']?.toString().trim();
      if (ad != null && ad.isNotEmpty) addressDetail = ad;
    }
  } catch (_) {}

  return ProfileScreenData(
    memberSince: memberSince,
    vendorRow: vRow,
    locationCityLabel: locLabel,
    branchAddressDetail: addressDetail,
  );
});
