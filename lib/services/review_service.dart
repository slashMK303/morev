import 'package:dio/dio.dart';
import 'api_client.dart';

class ReviewService {
  final Dio _dio = ApiClient.dio;

  Future<Response<dynamic>> createReview({
    required String token,
    required int movieId,
    required int rating,
    required String comment,
  }) {
    return _dio.post(
      '/reviews/$movieId',
      data: {'rating': rating, 'comment': comment},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
