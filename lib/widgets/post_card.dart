import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class PostCard extends StatefulWidget {
  final snap;
  const PostCard({super.key, required this.snap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  int commentLength = 0;
  String username = "";
  String photoUrl = "";

  @override
  void initState() {
    super.initState();
    getComments();
    fetchUsername(widget.snap['uid']);
    fetchUserProfilePic(widget.snap['uid']);
  }

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

  void getComments() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance.collection('posts').doc(widget.snap['postId']).collection('comments').get();
      commentLength = snap.docs.length;
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser;
    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // HEADER SECTION
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: widget.snap['uid']),
                  ),
                );
              },
              child: Row(
                children: [
                  photoUrl == "" ?

                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                    backgroundColor: Colors.grey[300],
                  ) : ProgressImageDots(url: widget.snap['profImage']),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  // IconButton(
                  //   onPressed: () {
                  //     showDialog(
                  //       context: context,
                  //       builder: (context) => Dialog(
                  //         child: ListView(
                  //           padding: EdgeInsets.symmetric(
                  //             vertical: 16,
                  //           ),
                  //           shrinkWrap: true,
                  //           children: ['Delete']
                  //               .map(
                  //                 (e) => InkWell(
                  //                   onTap: () async {
                  //                     await FirestoreMethods().deletePost(widget.snap['postId']);
                  //                     Navigator.of(context).pop();
                  //                   },
                  //                   child: Container(
                  //                     padding: const EdgeInsets.symmetric(
                  //                       vertical: 12,
                  //                       horizontal: 16,
                  //                     ),
                  //                     child: Text(e),
                  //                   ),
                  //                 ),
                  //               )
                  //               .toList(),
                  //         ),
                  //       ),
                  //     );
                  //   },
                  //   icon: const Icon(
                  //     Icons.more_vert,
                  //   ),
                  // )
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          // IMAGE SECTION
          GestureDetector(
            onDoubleTap: () async {
              await FirestoreMethods().likePost(
                  user.uid, widget.snap['postId'], widget.snap['likes']);
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  // height: MediaQuery.of(context).size.width * 9 / 16,
                  // width: MediaQuery.of(context).size.width,
                  child: Image.network(
                    widget.snap['postUrl'],
                    fit: BoxFit.cover,

                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return SkeletonLoader(
                          baseColor: const Color.fromARGB(255, 12, 12, 12),
                          builder: Container(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Container(
                                        width: double.infinity,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16.0),
                                          color: const Color.fromARGB(255, 48, 47, 47),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          items: 4,
                          period: Duration(seconds: 2),
                          highlightColor: const Color.fromARGB(255, 21, 21, 21),
                          direction: SkeletonDirection.ltr
                        );
                      }
                    },
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return Center(
                        child: Column(
                          children: [
                            Text('Could not load image'),
                            Icon(Icons.error),
                          ],
                        ), // Display an error icon if the image fails to load
                      );
                    }
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: 200,
                  ),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 120,
                    ),
                    isAnimating: isLikeAnimating,
                    duration: const Duration(
                      milliseconds: 400,
                    ),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                  ),
                )
              ],
            ),
          ),

          // LIKE, COMMENT SECTION
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user.uid),
                smallLike: true,
                child: IconButton(
                    onPressed: () async {
                      await FirestoreMethods().likePost(user.uid,
                          widget.snap['postId'], widget.snap['likes']);
                    },
                    icon: widget.snap['likes'].contains(user.uid)
                        ? const Icon(
                            Icons.favorite,
                            color: Colors.red,
                          )
                        : const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                          )),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return CommentsScreen(
                          snap: widget.snap,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(
                  Icons.comment_outlined,
                ),
              ),
              // IconButton(
              //   onPressed: () {},
              //   icon: const Icon(
              //     Icons.send,
              //   ),
              // ),
              // Expanded(
              //   child: Align(
              //     alignment: Alignment.bottomRight,
              //     child: IconButton(
              //       onPressed: () {},
              //       icon: const Icon(
              //         Icons.bookmark_border,
              //       ),
              //     ),
              //   ),
              // )
            ],
          ),

          // DESCRIPTION AND NUMBER OF COMMENTS
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  child: Text(
                    widget.snap['likes'].length == 0 ? 'No likes yet' : widget.snap['likes'].length == 1 ? '${widget.snap['likes'].length} like' : '${widget.snap['likes'].length} likes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                        style: const TextStyle(
                          color: primaryColor,
                        ),
                        children: [
                          TextSpan(
                              text: username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          TextSpan(
                            text: '  ${widget.snap['description']}',
                          )
                        ]),
                  ),
                ),
                InkWell(
                  onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return CommentsScreen(
                          snap: widget.snap,
                        );
                      },
                    ),
                  );
                },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      commentLength == 0 ? 'Write a comment' : 'View all $commentLength comments',
                      style: TextStyle(fontSize: 16, color: secondaryColor),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4).copyWith(top: 0),
                  child: Text(
                    DateFormat.yMMMd()
                        .format(widget.snap['datePublished'].toDate()),
                    style: TextStyle(fontSize: 16, color: secondaryColor),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
