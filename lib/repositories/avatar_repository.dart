import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/cloudinary_config.dart';

// Repository chọn ảnh và upload avatar lên Cloudinary, không dùng Firebase Storage.
final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  final repository = AvatarRepository(
    imagePicker: ImagePicker(),
    httpClient: http.Client(),
  );

  ref.onDispose(repository.dispose);

  return repository;
});

class AvatarRepository {
  AvatarRepository({
    required ImagePicker imagePicker,
    required http.Client httpClient,
  }) : _imagePicker = imagePicker,
       _httpClient = httpClient;

  final ImagePicker _imagePicker;
  final http.Client _httpClient;

  Future<XFile?> pickAvatarFromGallery() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
  }

  Future<String> uploadAvatar({
    required String uid,
    required XFile image,
  }) async {
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'hsk_dict_avatars/$uid';

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể tải ảnh đại diện lên Cloudinary.');
    }

    final body = jsonDecode(response.body);
    final secureUrl = body is Map<String, dynamic>
        ? body['secure_url']?.toString()
        : null;

    if (secureUrl == null || secureUrl.trim().isEmpty) {
      throw Exception('Cloudinary không trả về đường dẫn ảnh.');
    }

    return secureUrl;
  }

  void dispose() {
    _httpClient.close();
  }
}
