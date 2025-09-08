import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:instagram_app/models/post.dart';
import 'package:instagram_app/resources/storage_methods.dart';
import 'package:uuid/uuid.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload Post
  Future<String> uploadPost(
      String description, Uint8List file, String uid, String username, String profImage) async {
    String res = "Some error occurred";
    try {
      // Upload image to Cloudinary
      String photoUrl = await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1();

      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
      );

      await _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Like Post
  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Post Comment
  Future<String> postComment(String postId, String text, String uid, String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': FieldValue.serverTimestamp(),
        });
        res = "success";
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Delete Post
  Future<String> deletePost(String postId) async {
    String res = "Some error occurred";
    try {
      await _firestore.collection('posts').doc(postId).delete();
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Follow / Unfollow User
  Future<String> followUser(String uid, String followId) async {
    String res = "Some error occurred";
    try {
      DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
      List following = List.from((snap.data()! as dynamic)['following']);

      if (following.contains(followId)) {
        // Unfollow
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        // Follow
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });
        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
      res = "success";
    } catch (err) {
      if (kDebugMode) print(err.toString());
      res = err.toString();
    }
    return res;
  }
}
