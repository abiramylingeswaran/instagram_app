import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String uid;
  final String photoUrl;
  final String username;
  final String bio;
  final List<String> followers;
  final List<String> following;

  const User({
    required this.username,
    required this.uid,
    required this.photoUrl,
    required this.email,
    required this.bio,
    required this.followers,
    required this.following,
  });

  // Convert Firestore document to User object
  static User fromSnap(DocumentSnapshot snap) {
    final snapshot = snap.data() as Map<String, dynamic>? ?? {};

    return User(
      username: snapshot["username"] ?? "",
      uid: snapshot["uid"] ?? "",
      email: snapshot["email"] ?? "",
      photoUrl: snapshot["photoUrl"] ?? "",
      bio: snapshot["bio"] ?? "",
      followers: List<String>.from(snapshot["followers"] ?? []),
      following: List<String>.from(snapshot["following"] ?? []),
    );
  }

  // Convert User object to JSON map for Firestore
  Map<String, dynamic> toJson() => {
        "username": username,
        "uid": uid,
        "email": email,
        "photoUrl": photoUrl,
        "bio": bio,
        "followers": followers,
        "following": following,
      };
}
