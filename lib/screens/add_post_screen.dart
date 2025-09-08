import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_app/providers/user_provider.dart';
import 'package:instagram_app/utils/colors.dart';
import 'package:instagram_app/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  Uint8List? _file;
  bool isLoading = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // Select image from gallery or camera
  _selectImage(BuildContext parentContext) async {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Create a Post'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Take a photo'),
              onPressed: () async {
                Navigator.pop(context);
                Uint8List file = await pickImage(ImageSource.camera);
                setState(() => _file = file);
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text('Choose from Gallery'),
              onPressed: () async {
                Navigator.pop(context);
                Uint8List file = await pickImage(ImageSource.gallery);
                setState(() => _file = file);
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(20),
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // Upload image to Cloudinary
  Future<String> uploadImageToCloudinary(Uint8List fileBytes) async {
    const cloudName = 'ds1kq9o0y'; // replace with your Cloudinary cloud name
    const uploadPreset = 'flutter_unsigned'; // replace with your unsigned upload preset

    var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: 'image.jpg'));

    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var result = json.decode(String.fromCharCodes(responseData));

    if (result['secure_url'] != null) {
      return result['secure_url']; // Cloudinary image URL
    } else {
      throw Exception("Failed to upload image");
    }
  }

  // Post to Firestore
  void postImage(String name, String id, String description) async {
    if (_file == null) {
      showSnackBar(context, "Please select an image");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Upload image to Cloudinary
      String photoUrl = await uploadImageToCloudinary(_file!);

      // Generate unique postId
      String postId = FirebaseFirestore.instance.collection('posts').doc().id;

      // Save post in Firestore
      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'name': name,
        'id': id,
        'description': description,
        'photoUrl': photoUrl,
        'postId': postId,
        'datePublished': Timestamp.now(),
        'likes': [],
      });

      setState(() {
        isLoading = false;
        _file = null;
        _descriptionController.clear();
      });

      showSnackBar(context, "Post uploaded!");
    } catch (err) {
      setState(() => isLoading = false);
      showSnackBar(context, err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.getUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Add Post'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => postImage(user.username, user.uid, _descriptionController.text),
            child: const Text(
              "Post",
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          isLoading ? const LinearProgressIndicator() : const SizedBox(height: 0),
          _file == null
              ? Center(
                  child: IconButton(
                    icon: const Icon(Icons.upload, size: 50),
                    onPressed: () => _selectImage(context),
                  ),
                )
              : SizedBox(
                  height: 300,
                  child: Image.memory(_file!),
                ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: "Write a caption...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}
