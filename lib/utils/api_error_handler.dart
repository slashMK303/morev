import 'package:dio/dio.dart';

Map<String, String> fieldErrorsFromApiError(Object error) {
  if (error is! DioException) return <String, String>{};

  final responseData = error.response?.data;
  final errors = <String, String>{};

  if (responseData is Map<String, dynamic>) {
    final detail = responseData['detail'];
    if (detail is List) {
      for (final item in detail) {
        if (item is Map<String, dynamic>) {
          final loc = item['loc'];
          final msg = item['msg']?.toString().trim();
          if (msg == null || msg.isEmpty) continue;

          String? fieldName;
          if (loc is List && loc.isNotEmpty) {
            fieldName = loc.last?.toString();
          } else if (loc != null) {
            fieldName = loc.toString();
          }

          if (fieldName != null && fieldName.isNotEmpty) {
            errors[fieldName] = msg;
          }
        }
      }
    }

    final message = responseData['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      final lower = message.toLowerCase();
      if (lower.contains('email') && lower.contains('password')) {
        errors['password'] = 'Email atau password salah.';
      } else if (lower.contains('email')) {
        errors['email'] = message;
      } else if (lower.contains('username')) {
        errors['username'] = message;
      } else if (lower.contains('password')) {
        errors['password'] = message;
      }
    }
  }

  final status = error.response?.statusCode;
  if (status == 401) {
    errors['password'] = 'Email atau password salah.';
  }

  return errors;
}

String friendlyApiError(Object error, {String fallback = 'Terjadi kesalahan. Coba lagi.'}) {
  if (error is DioException) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] ?? responseData['error'] ?? responseData['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server terlalu lama. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke server. Cek koneksi internet.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) return 'Email atau password salah.';
        if (status == 403) return 'Akses ditolak.';
        if (status == 404) return 'Data tidak ditemukan.';
        if (status != null) return 'Server merespons dengan kode $status.';
        return 'Server mengembalikan error.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.unknown:
        return fallback;
    }
  }

  final text = error.toString().trim();
  if (text.isEmpty) return fallback;
  if (text.length > 140) return fallback;
  return text;
}
