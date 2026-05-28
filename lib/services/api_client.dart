import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = 'http://127.0.0.1:8000';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
