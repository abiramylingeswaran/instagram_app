import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_app/models/user.dart' as model;
import 'package:instagram_app/providers/user_provider.dart';
import 'package:instagram_app/resources/firestore_methods.dart';
import 'package:instagram_app/screens/comments_screen.dart';
import 'package:instagram_app/utils/colors.dart';
import 'package:instagram_app/utils/global_variable.dart';
import 'package:instagram_app/utils/utils.dart';
import 'package:instagram_app/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;

  deletePost(String postId) async {
    try {
      await FireStoreMethods().deletePost(postId);
      showSnackBar(context, 'Post deleted successfully!');
    } catch (err) {
      showSnackBar(context, err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final width = MediaQuery.of(context).size.width;
    final likes = List<String>.from(widget.snap['likes'] ?? []);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: width > webScreenSize ? secondaryColor : mobileBackgroundColor,
        ),
        color: mobileBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16).copyWith(right: 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(widget.snap['profImage'] ?? ''),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      widget.snap['username'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                widget.snap['uid'] == user.uid
                    ? IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shrinkWrap: true,
                                children: [
                                  InkWell(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: const Text('Delete'),
                                    ),
                                    onTap: () {
                                      deletePost(widget.snap['postId']);
                                      Navigator.of(context).pop();
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.more_vert),
                      )
                    : Container(),
              ],
            ),
          ),

          // IMAGE
          GestureDetector(
            onDoubleTap: () {
              FireStoreMethods().likePost(
                widget.snap['postId'],
                user.uid,
                likes,
              );
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: Image.network(
                    widget.snap['postUrl'] ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(milliseconds: 400),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                  ),
                ),
              ],
            ),
          ),

          // LIKE, COMMENT, SHARE
          Row(
            children: [
              LikeAnimation(
                isAnimating: likes.contains(user.uid),
                smallLike: true,
                child: IconButton(
                  icon: likes.contains(user.uid)
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : const Icon(Icons.favorite_border),
                  onPressed: () => FireStoreMethods().likePost(
                    widget.snap['postId'],
                    user.uid,
                    likes,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(
                      postId: widget.snap['postId'],
                    ),
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: () {}),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
                ),
              ),
            ],
          ),

          // DESCRIPTION & COMMENTS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${likes.length} likes', style: const TextStyle(fontWeight: FontWeight.bold)),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 4),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: primaryColor),
                      children: [
                        TextSpan(
                          text: widget.snap['username'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${widget.snap['description'] ?? ''}'),
                      ],
                    ),
                  ),
                ),

                // LIVE COMMENT COUNT
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.snap['postId'])
                      .collection('comments')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    int commentLen = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(
                            postId: widget.snap['postId'],
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'View all $commentLen comments',
                          style: const TextStyle(fontSize: 16, color: secondaryColor),
                        ),
                      ),
                    );
                  },
                ),

                // DATE
                Text(
                  DateFormat.yMMMd().format((widget.snap['datePublished'] as Timestamp).toDate()),
                  style: const TextStyle(color: secondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
