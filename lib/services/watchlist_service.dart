import 'package:dio/dio.dart';
import 'api_client.dart';

class WatchlistService {
  final Dio _dio = ApiClient.dio;

  Future<Response<dynamic>> getWatchlists({required String token}) {
    return _dio.get(
      '/watchlists',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> addWatchlist({
    required String token,
    required int movieId,
  }) {
    return _dio.post(
      '/watchlists/$movieId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> removeWatchlist({
    required String token,
    required int movieId,
  }) {
    return _dio.delete(
      '/watchlists/$movieId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
