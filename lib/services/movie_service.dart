import 'package:dio/dio.dart';
import 'api_client.dart';

class MovieService {
  final Dio _dio = ApiClient.dio;

  Future<Response<dynamic>> getMovies({required String token}) {
    return _dio.get(
      '/movies',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> getMovieDetail({
    required String token,
    required int movieId,
  }) {
    return _dio.get(
      '/movies/$movieId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> watchMovie({
    required String token,
    required int movieId,
  }) {
    return _dio.get(
      '/movies/watch/$movieId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> getGenres({required String token}) {
    return _dio.get(
      '/genres',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
