import 'package:dio/dio.dart';
import 'api_client.dart';

class HistoryService {
  final Dio _dio = ApiClient.dio;

  Future<Response<dynamic>> getHistories({required String token}) {
    return _dio.get(
      '/histories',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> addHistory({
    required String token,
    required int movieId,
  }) {
    return _dio.post(
      '/histories/$movieId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
