import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:nyumbasearch/core/errors/app_failure.dart';
import 'package:nyumbasearch/core/network/mobile_api_repository.dart';

/// Pick gallery photos and upload via BFF signed URLs, then attach to the listing.
class PropertyMediaUploader {
  PropertyMediaUploader(this._api);

  final MobileApiRepository _api;
  final _picker = ImagePicker();
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 120),
    ),
  );

  Future<List<String>> pickAndUpload({
    required String propertyId,
    int maxImages = 6,
  }) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (files.isEmpty) return const [];

    final selected = files.take(maxImages).toList();
    final meta = selected
        .map(
          (f) => {
            'filename': f.name.isNotEmpty ? f.name : 'photo.jpg',
            'contentType': _guessContentType(f.path),
          },
        )
        .toList();

    final urlsJson = await _api.mediaUploadUrls(propertyId, files: meta);
    final uploads = urlsJson['uploads'];
    if (uploads is! List || uploads.length != selected.length) {
      throw const ServerFailure('Upload URLs mismatch', code: 'MEDIA_ERROR');
    }

    final paths = <String>[];
    for (var i = 0; i < selected.length; i++) {
      final slot = Map<String, dynamic>.from(uploads[i] as Map);
      final signedUrl = slot['signedUrl'] as String?;
      final token = slot['token'] as String?;
      final path = slot['path'] as String?;
      final contentType = (slot['contentType'] as String?) ?? 'image/jpeg';
      if (signedUrl == null || token == null || path == null) {
        throw const ServerFailure('Invalid upload slot', code: 'MEDIA_ERROR');
      }

      final bytes = await File(selected[i].path).readAsBytes();
      final res = await _dio.put<List<int>>(
        signedUrl,
        data: bytes,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': contentType,
            'x-upsert': 'false',
          },
          contentType: contentType,
          validateStatus: (_) => true,
        ),
      );
      if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
        throw ServerFailure(
          'Photo upload failed (${res.statusCode ?? 0})',
          code: 'MEDIA_UPLOAD',
        );
      }
      paths.add(path);
    }

    final attached = await _api.attachPropertyMedia(
      propertyId,
      appendPaths: paths,
    );
    final prop = attached['property'];
    if (prop is Map && prop['images'] is List) {
      return (prop['images'] as List).whereType<String>().toList();
    }
    return const [];
  }

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }
}
