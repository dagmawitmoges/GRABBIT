import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../model/deal_model.dart';
import '../model/review_model.dart';

class DealsService {
  final Dio _dio = DioClient.instance;

  /// Normalizes a Supabase `deals` row (+ optional embeds) for [Deal.fromJson].
  static Map<String, dynamic> dealRowToJson(Map<String, dynamic> row) {
    final cat = row['categories'];
    final loc = row['locations'];
    String? locationLabel;
    if (loc is Map) {
      final sc = loc['sub_city']?.toString().trim() ?? '';
      final c = loc['city']?.toString().trim() ?? '';
      if (sc.isEmpty) {
        locationLabel = c.isEmpty ? null : c;
      } else {
        locationLabel = c.isEmpty ? sc : '$sc · $c';
      }
    }
    return {
      ...row,
      'id': '${row['id']}',
      'category_name': cat is Map ? cat['name']?.toString() : null,
      'subcity_name': locationLabel,
      // Stock triggers update `quantity_remaining`; prefer it over legacy `quantity_available`.
      'available_quantity':
          row['quantity_remaining'] ?? row['quantity_available'],
    };
  }

  Future<List<Deal>> getDeals({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    String? locationId,
    double? minPrice,
    double? maxPrice,
    bool? active,
    bool? urgentOnly,
  }) async {
    if (Env.hasSupabase) {
      try {
        final from = (page - 1) * limit;
        final to = from + limit - 1;
        final now = DateTime.now().toUtc().toIso8601String();

        var query = Supabase.instance.client
            .from('deals')
            .select(
              'id, title, description, original_price, discounted_price, '
              'quantity_remaining, expiry_time, images, is_active, removed_by_admin, '
              'average_rating, vendor_user_id, '
              'categories ( name ), locations!location_id ( sub_city, city, country )',
            )
            .eq('removed_by_admin', false)
            .gt('quantity_remaining', 0);

        if (search != null && search.trim().isNotEmpty) {
          final q = '%${search.trim()}%';
          query = query.or('title.ilike.$q,description.ilike.$q');
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          query = query.eq('category_id', categoryId);
        }
        if (locationId != null && locationId.isNotEmpty) {
          query = query.eq('location_id', locationId);
        }
        if (minPrice != null) {
          query = query.gte('discounted_price', minPrice);
        }
        if (maxPrice != null) {
          query = query.lte('discounted_price', maxPrice);
        }
        if (active == true) {
          query = query.eq('is_active', true).gt('expiry_time', now);
        }
        if (urgentOnly == true) {
          final week = DateTime.now()
              .toUtc()
              .add(const Duration(days: 7))
              .toIso8601String();
          query = query.gt('expiry_time', now).lte('expiry_time', week);
        }

        final rows = await query
            .order('created_at', ascending: false)
            .range(from, to);

        final list = rows as List<dynamic>;
        return list
            .map((e) => Deal.fromJson(
                  dealRowToJson(Map<String, dynamic>.from(e as Map)),
                ))
            .toList();
      } on PostgrestException catch (e) {
        throw e.message;
      } catch (e) {
        throw 'Could not load deals: $e';
      }
    }

    try {
      final response = await _dio.get(
        ApiConstants.deals,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'categoryId': categoryId,
          if (locationId != null) 'locationId': locationId,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          if (active != null) 'active': active,
          if (urgentOnly != null) 'urgentOnly': urgentOnly,
        },
      );

      final data = response.data;
      final List rawDeals = (data['deals'] ??
          data['data'] ??
          data['items'] ??
          []) as List;

      return rawDeals
          .map((e) => Deal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Deal> getDealById(String id) async {
    if (Env.hasSupabase) {
      try {
        final row = await Supabase.instance.client
            .from('deals')
            .select(
              'id, title, description, original_price, discounted_price, '
              'quantity_remaining, expiry_time, images, is_active, removed_by_admin, '
              'average_rating, vendor_user_id, '
              'categories ( name ), locations!location_id ( sub_city, city, country )',
            )
            .eq('id', id)
            .eq('removed_by_admin', false)
            .maybeSingle();

        if (row == null) {
          throw 'Deal not found.';
        }
        return Deal.fromJson(
          dealRowToJson(Map<String, dynamic>.from(row)),
        );
      } on PostgrestException catch (e) {
        throw e.message;
      }
    }

    try {
      final response = await _dio.get('${ApiConstants.deals}/$id');
      return Deal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Review>> getDealReviews(String dealId) async {
    if (Env.hasSupabase) {
      try {
        final rows = await Supabase.instance.client
            .from('reviews')
            .select()
            .eq('deal_id', dealId)
            .order('created_at', ascending: false);

        final list = rows as List<dynamic>;
        return list.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Review.fromJson({
            'id': '${m['id']}',
            'rating': m['rating'] is int
                ? m['rating'] as int
                : int.tryParse('${m['rating']}') ?? 0,
            'comment': m['comment'] as String?,
            'reviewer_name': m['reviewer_name'] as String?,
            'created_at': m['created_at']?.toString() ?? '',
          });
        }).toList();
      } on PostgrestException catch (e) {
        throw e.message;
      }
    }

    try {
      final response =
          await _dio.get('${ApiConstants.deals}/$dealId/reviews');
      final List data = response.data as List;
      return data
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    switch (e.response?.statusCode) {
      case 404:
        return 'Deal not found.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
