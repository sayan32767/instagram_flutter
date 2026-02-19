import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/screens/full_screen_post_page.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/instagram_searchbar.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:instagram_flutter/widgets/share_screen_sheet.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
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
  String photoUrl = "_";
  String userType = "";
  String tagline = "";
  String userEmojiUrl = "";

  QuerySnapshot? querySnapshot;
  QuerySnapshot? snap;

  @override
  void initState() {
    super.initState();
    fetchAllDetails();
  }

  void fetchAllDetails() async {
    await fetchUserSnapshot(widget.snap['uid']);
    await fetchPostSnapshot(widget.snap['uid']);
    await fetchUsername();
    await fetchUserProfilePic();
    await fetchUserType();
    await fetchUserTagline();
    await fetchUserEmoji();
    await getComments();
  }

  Future fetchUserEmoji() async {
    try {
      if (querySnapshot!.docs.isNotEmpty) {
        final DocumentSnapshot document = querySnapshot!.docs.first;
        userEmojiUrl = document['userEmoji'] ?? "";
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future fetchUserSnapshot(String uid) async {
    querySnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
  }

  Future fetchPostSnapshot(String uid) async {
    snap = await AppFirestore.posts()
        .doc(widget.snap['postId'])
        .collection('comments')
        .get();
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

  Future fetchUserTagline() async {
    try {
      if (querySnapshot!.docs.isNotEmpty) {
        final DocumentSnapshot document = querySnapshot!.docs.first;
        tagline = document['tagline'] ?? "";
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

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

  Future getComments() async {
    try {
      commentLength = snap!.docs.length;
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    if (mounted) setState(() {});
  }

  void _openShareSheet(Map<String, dynamic> postData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.75, // 👈 stops before top (75% screen)
          child: ShareSheet(
            post: postData,
            type: 'post',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser!;
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
                    builder: (context) =>
                        ProfileScreen(uid: widget.snap['uid']),
                  ),
                );
              },
              child: Row(
                children: [
                  photoUrl == "_"
                      ? CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              const Color.fromARGB(255, 24, 24, 24),
                        )
                      : photoUrl == ""
                          ? CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  AssetImage('assets/images/placeholder.jpg'),
                              backgroundColor:
                                  const Color.fromARGB(255, 24, 24, 24),
                            )
                          : ProgressImageDots(url: photoUrl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              username == ""
                                  ? Container(
                                      padding: const EdgeInsets.only(left: 15),
                                      color:
                                          const Color.fromARGB(255, 24, 24, 24),
                                      width: 70,
                                      height: 12)
                                  : Text(
                                      username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                              SizedBox(width: 5),
                              userType == 'ADMIN'
                                  ? SizedBox(
                                      height: 20,
                                      child: Image.asset(
                                          'assets/images/verification_badge.png'),
                                    )
                                  : Container(),

                              // CUSTOM EMOJI SECTION
                              SizedBox(width: 5),

                              userEmojiUrl.isNotEmpty
                                  ? SizedBox(
                                      height: 25,
                                      child: CachedNetworkImage(
                                        imageUrl: userEmojiUrl,
                                        fit: BoxFit.cover,
                                        cacheManager:
                                            InstaCacheManager(), // ⭐ long-term disk cache

                                        placeholder: (context, url) => Center(
                                          child: SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: Container(
                                              color: const Color.fromARGB(
                                                  255, 24, 24, 24),
                                            ),
                                          ),
                                        ),

                                        errorWidget: (context, url, error) =>
                                            const Center(),
                                      ))
                                  : SizedBox.shrink()
                            ],
                          ),
                          tagline != ''
                              ? Text(
                                  tagline,
                                  style: TextStyle(
                                      // fontWeight: FontWeight.bold,
                                      ),
                                )
                              : Container()
                        ],
                      ),
                    ),
                  ),
                  username == ""
                      ? Container()
                      : user.userType == 'ADMIN'
                          ? IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: ListView(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      shrinkWrap: true,
                                      children: [
                                        user.userType == 'ADMIN'
                                            ? 'Delete'
                                            : null
                                      ].map((e) {
                                        return InkWell(
                                            onTap: () async {
                                              if (e == 'Delete') {
                                                await FirestoreMethods()
                                                    .deletePost(
                                                        widget.snap['postId']);
                                              } else if (e ==
                                                  'Something Else') {}

                                              final key =
                                                  Provider.of<GlobalKeyProvier>(
                                                          context,
                                                          listen: false)
                                                      .globalKey;

                                              if (key?.currentState
                                                  is FeedScreenState) {
                                                (key?.currentState
                                                        as FeedScreenState)
                                                    .refresh();
                                              }

                                              Navigator.pop(context);
                                            },
                                            child: e != null
                                                ? Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      vertical: 12,
                                                      horizontal: 16,
                                                    ),
                                                    child: Text(e),
                                                  )
                                                : Container());
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.more_vert,
                              ),
                            )
                          : Container()
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          // IMAGE SECTION
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 250),
                  pageBuilder: (_, __, ___) => FullscreenImageViewer(
                    imageUrl: widget.snap['postUrl'],
                    username: username,
                    profilePic: photoUrl,
                    userType: userType,
                  ),
                ),
              );
            },
            onDoubleTap: () async {
              await FirestoreMethods().likePost('posts', user.uid,
                  widget.snap['postId'], widget.snap['likes']);
              setState(() {
                isLikeAnimating = true;
                widget.snap['likes'].contains(user.uid)
                    ? widget.snap['likes'].remove(user.uid)
                    : widget.snap['likes'].add(user.uid);
              });
            },
            child: username == ""
                ? Container(
                    color: const Color.fromARGB(255, 24, 24, 24),
                    height: MediaQuery.of(context).size.width * 3 / 4,
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.width * 3 / 4,
                          child: CachedNetworkImage(
                            imageUrl: widget.snap['postUrl'],
                            fit: BoxFit.cover,
                            cacheManager:
                                InstaCacheManager(), // ⭐ long-term cache

                            placeholder: (context, url) => Container(
                              color: const Color.fromARGB(255, 24, 24, 24),
                            ),

                            errorWidget: (context, url, error) => const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Could not load image'),
                                  Icon(Icons.error),
                                ],
                              ),
                            ),
                          )),
                      AnimatedOpacity(
                        duration: const Duration(
                          milliseconds: 200,
                        ),
                        opacity: isLikeAnimating ? 1 : 0,
                        child: LikeAnimation(
                          isAnimating: isLikeAnimating,
                          duration: const Duration(milliseconds: 400),
                          onEnd: () {
                            setState(() {
                              isLikeAnimating = false;
                            });
                          },
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFF833AB4),
                                  Color(0xFFE1306C),
                                  Color(0xFFF77737),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white, // important for ShaderMask
                              size: 120,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
          ),

          // LIKE, COMMENT SECTION
          username == ""
              ? Container(height: 10)
              : Row(
                  children: [
                    LikeAnimation(
                      isAnimating: widget.snap['likes'].contains(user.uid),
                      smallLike: true,
                      child: IconButton(
                          onPressed: () async {
                            await FirestoreMethods().likePost('posts', user.uid,
                                widget.snap['postId'], widget.snap['likes']);
                            setState(() {
                              widget.snap['likes'].contains(user.uid)
                                  ? widget.snap['likes'].remove(user.uid)
                                  : widget.snap['likes'].add(user.uid);
                            });
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
                        Navigator.of(context, rootNavigator: true).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    CommentsScreen(snap: widget.snap),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(0.0, 1.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.comment_outlined,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openShareSheet(widget.snap),
                      icon: const Icon(
                        Icons.send,
                      ),
                    ),
                    // Expanded(
                    //   child: Align(
                    //     alignment: Alignment.bottomRight,
                    //     child: IconButton(
                    //       onPressed: () => _openShareSheet(widget.snap),
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
                  child: username == ""
                      ? Container(
                          color: const Color.fromARGB(255, 24, 24, 24),
                          width: 70,
                          height: 12)
                      : Text(
                          widget.snap['likes'].length == 0
                              ? 'No likes yet'
                              : widget.snap['likes'].length == 1
                                  ? '${widget.snap['likes'].length} like'
                                  : '${widget.snap['likes'].length} likes',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      username == ""
                          ? Container(
                              color: const Color.fromARGB(255, 24, 24, 24),
                              width: 140,
                              height: 12)
                          : widget.snap['description'] != ''
                              ? Expanded(
                                  child: Text(
                                    '${widget.snap['description']}',
                                    maxLines: null,
                                    overflow: TextOverflow.clip,
                                  ),
                                )
                              : Container()
                    ],
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
                    child: username == ""
                        ? Container(
                            padding: const EdgeInsets.only(left: 15),
                            color: const Color.fromARGB(255, 24, 24, 24),
                            width: 70,
                            height: 12)
                        : Text(
                            commentLength == 0
                                ? 'Write a comment'
                                : 'View all $commentLength comments',
                            style:
                                TextStyle(fontSize: 16, color: secondaryColor),
                          ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4).copyWith(top: 0),
                  child: username == ""
                      ? Container(
                          padding: const EdgeInsets.only(left: 15),
                          color: const Color.fromARGB(255, 24, 24, 24),
                          width: 70,
                          height: 12)
                      : Text(
                          DateFormat.yMMMd()
                              .add_jm()
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
