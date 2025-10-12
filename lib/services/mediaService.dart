import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';


class MediaService {
  Future<String?> uploadImageToCloudinary(File file) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload');


    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));


    final response = await request.send();


    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);
      return data['secure_url'];
    } else {
      print('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }
}