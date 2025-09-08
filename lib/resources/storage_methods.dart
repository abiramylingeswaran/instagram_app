import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class StorageMethods {
  // Upload image to Cloudinary instead of Firebase
  Future<String> uploadImageToStorage(
      String childName, Uint8List file, bool isPost) async {
    const cloudName = "ds1kq9o0y"; 
    const uploadPreset = "flutter_unsigned"; 

    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/ds1kq9o0y/image/upload");

    // Give each post a unique name if it's a post
    String fileName = isPost ? const Uuid().v1() : "profile_pic";

    // Build request
    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        file,
        filename: "$childName-$fileName.jpg",
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      return data['secure_url']; // Cloudinary hosted image URL
    } else {
      throw Exception("Cloudinary upload failed: ${response.statusCode}");
    }
  }
}
