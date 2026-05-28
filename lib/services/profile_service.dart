import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import '../utils/profile_photo_url.dart';

class ProfileService {
  final Dio _dio = ApiClient.dio;

  Future<Response<dynamic>> getProfile({required String token}) {
    return _dio.get(
      '/users/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> getStatistics({required String token}) {
    return _dio.get(
      '/users/statistics',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<String> uploadPhoto({
    required String token,
    required XFile photo,
  }) async {
    final formData = FormData();

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      formData.files.add(
        MapEntry('photo', MultipartFile.fromBytes(bytes, filename: photo.name)),
      );
    } else {
      formData.files.add(
        MapEntry(
          'photo',
          await MultipartFile.fromFile(photo.path, filename: photo.name),
        ),
      );
    }

    final response = await _dio.post(
      '/users/upload-photo',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        contentType: 'multipart/form-data',
      ),
    );

    String uploadedPhoto = photo.name;
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final responseData = data['data'];
      if (responseData is Map<String, dynamic>) {
        uploadedPhoto = responseData['profile_photo']?.toString() ?? photo.name;
      } else {
        uploadedPhoto = data['profile_photo']?.toString() ?? photo.name;
      }
    }

    return normalizeUploadedProfilePhotoPath(uploadedPhoto);
  }

  Future<Response<dynamic>> updateProfile({
    required String token,
    Map<String, dynamic> payload = const {},
  }) {
    return _dio.patch(
      '/users/profile',
      data: payload,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
