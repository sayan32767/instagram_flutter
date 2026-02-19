import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
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
  String photoUrl = "_";
  String userType = "";

  QuerySnapshot? querySnapshot;

  Future fetchUserProfilePic() async {
    try {
      if (querySnapshot!.docs.isNotEmpty) {
        final DocumentSnapshot document = querySnapshot!.docs.first;
        photoUrl = document['photoUrl'] ?? "";
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future fetchUsername() async {
    try {
      if (querySnapshot!.docs.isNotEmpty) {
        final DocumentSnapshot document = querySnapshot!.docs.first;
        username = document['username'] as String;
      } else {
        username = 'unknown user';
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future fetchUserType() async {
    try {
      if (querySnapshot!.docs.isNotEmpty) {
        final DocumentSnapshot document = querySnapshot!.docs.first;
        userType = document['userType'] ?? "";
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void fetchUserDetails() async {
    querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('uid', isEqualTo: widget.snap['uid'])
        .limit(1)
        .get();

    await fetchUsername();
    await fetchUserProfilePic();
    await fetchUserType();
  }

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
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
          photoUrl == "_"
              ? CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color.fromARGB(255, 24, 24, 24),
                )
              : photoUrl == ""
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(uid: widget.snap['uid']),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            AssetImage('assets/images/placeholder.jpg'),
                        backgroundColor: Colors.grey[300],
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileScreen(uid: widget.snap['uid']),
                          ),
                        );
                      },
                      child: ProgressImageDots(url: photoUrl)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  username == ""
                      ? Container(
                          color: const Color.fromARGB(255, 24, 24, 24),
                          width: 140,
                          height: 12)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileScreen(uid: widget.snap['uid']),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    username,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 5),
                                  if (userType == 'ADMIN')
                                    SizedBox(
                                      height: 18,
                                      child: Image.asset(
                                          'assets/images/verification_badge.png'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.snap['text'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              softWrap: true,
                            ),
                          ],
                        ),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: username == ""
                        ? Container(
                            color: const Color.fromARGB(255, 24, 24, 24),
                            width: 70,
                            height: 12)
                        : Text(
                            DateFormat.yMMMd()
                                .add_jm()
                                .format(widget.snap['datePublished'].toDate()),
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
