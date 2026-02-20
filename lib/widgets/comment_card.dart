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
    await Future.delayed(const Duration(milliseconds: 300));
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
    final bool isLoading = username == "" || photoUrl == "_";

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: isLoading
          ? Container(
              key: const ValueKey("skeleton"),
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color.fromARGB(255, 24, 24, 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 24, 24, 24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        height: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 24, 24, 24),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          : Container(
              key: const ValueKey("comment"),
              padding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              child: Row(
                children: [
                  photoUrl == ""
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              const AssetImage('assets/images/placeholder.jpg'),
                          backgroundColor: Colors.grey[300],
                        )
                      : ProgressImageDots(url: photoUrl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                          const SizedBox(height: 2),
                          Text(
                            widget.snap['text'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat.yMMMd().add_jm().format(
                                  widget.snap['datePublished'].toDate()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
