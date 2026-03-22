import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../model/deal_model.dart';
import '../model/review_model.dart';

class DealsService {
  final Dio _dio = DioClient.instance;

  Future<List<Deal>> getDeals({
    int page = 1,
    int limit = 10,
    String? search,
    String? categoryId,
    String? subcityId,
    double? minPrice,
    double? maxPrice,
    bool? active,
    bool? urgentOnly,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.deals,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'categoryId': categoryId,
          if (subcityId != null) 'subcityId': subcityId,
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
    try {
      final response = await _dio.get('${ApiConstants.deals}/$id');
      return Deal.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Review>> getDealReviews(String dealId) async {
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