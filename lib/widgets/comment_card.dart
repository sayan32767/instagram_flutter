import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CommentCard extends StatefulWidget {
  final snap;
  const CommentCard({super.key, required this.snap});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  String username = "";
  String photoUrl = "";

  void fetchUserProfilePic(String uid) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        
        // Retrieve the username from the document
        final DocumentSnapshot document = querySnapshot.docs.first;
        photoUrl = document['photoUrl'] ?? "";
      }
    } catch (_) {}
    setState(() {});
  }

  void fetchUsername(String uid) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        
        // Retrieve the username from the document
        final DocumentSnapshot document = querySnapshot.docs.first;
        username = document['username'] as String;
      } else {
        username = 'unknown user';
      }
    } catch (_) {}
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchUsername(widget.snap['uid']);
    fetchUserProfilePic(widget.snap['uid']);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      child: Row(
        children: [
          photoUrl == "" ?

          CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/images/placeholder.jpg'),
            backgroundColor: Colors.grey[300],
          ) : ProgressImageDots(url: widget.snap['profilePic']),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' ${widget.snap['text']}',
                      )
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.yMMMd().format(
                        widget.snap['datePublished'].toDate(),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.all(8),
          //   child: const Icon(Icons.favorite),
          // )
        ],
      ),
    );
  }
}
