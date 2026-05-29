import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = 'https://morev-api.ars-projects.my.id';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}
