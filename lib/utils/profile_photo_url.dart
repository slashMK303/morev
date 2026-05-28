import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

String? resolveProfilePhotoUrl(String? profilePhoto) {
  if (profilePhoto == null) return null;

  final value = profilePhoto.trim();
  if (value.isEmpty) return null;

  if (value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('blob:') ||
      value.startsWith('data:')) {
    return value;
  }

  if (!kIsWeb) {
    final file = File(value);
    if (file.existsSync()) {
      return value;
    }
  }

  if (value.startsWith('/')) {
    return '${ApiClient.baseUrl}$value';
  }

  return '${ApiClient.baseUrl}/uploads/profile/$value';
}

String normalizeUploadedProfilePhotoPath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;

  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('/')) {
    return trimmed;
  }

  return '/uploads/profile/$trimmed';
}
