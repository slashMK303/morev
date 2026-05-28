import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<Response<dynamic>> register({
    required Map<String, dynamic> payload,
    XFile? profilePhoto,
  }) async {
    final formData = FormData.fromMap(payload);

    if (profilePhoto != null) {
      if (kIsWeb) {
        final bytes = await profilePhoto.readAsBytes();
        formData.files.add(
          MapEntry(
            'profile_photo',
            MultipartFile.fromBytes(bytes, filename: profilePhoto.name),
          ),
        );
      } else {
        formData.files.add(
          MapEntry(
            'profile_photo',
            await MultipartFile.fromFile(
              profilePhoto.path,
              filename: profilePhoto.name,
            ),
          ),
        );
      }
    }

    return _dio.post(
      '/auth/register',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<Response<dynamic>> login(Map<String, dynamic> payload) {
    return _dio.post('/auth/login', data: payload);
  }
}
