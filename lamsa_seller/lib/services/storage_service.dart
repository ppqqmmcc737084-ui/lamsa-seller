import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class StorageUploadException implements Exception {
  final String message;
  const StorageUploadException(this.message);

  @override
  String toString() => message;
}

/// رفع صور المنتجات إلى Cloudinary (خطة مجانية بدون بطاقة).
class StorageService {
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName.isEmpty ? 'product.jpg' : fileName,
      ));

    try {
      final response = await request.send().timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = json['secure_url'];
        if (url is String && url.isNotEmpty) return url;
        throw const StorageUploadException('رد غير متوقع من خدمة الصور');
      }
      throw StorageUploadException('تعذّر رفع الصورة (رمز ${response.statusCode})');
    } on StorageUploadException {
      rethrow;
    } catch (_) {
      throw const StorageUploadException('تعذّر رفع الصورة، تحقق من الاتصال بالإنترنت وحاول مرة ثانية');
    }
  }
}
