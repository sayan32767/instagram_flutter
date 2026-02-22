import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/screens/full_screen_post_page.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:instagram_flutter/widgets/share_screen_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLikeAnimating = false;
  @override
  void initState() {
    super.initState();
  }

  void _openShareSheet(Map<String, dynamic> postData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.75,
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
    final user = context.watch<UserProvider>().getUser;

    if (user == null) {
      return const SizedBox.shrink();
    }
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
                    builder: (context) => ProfileScreen(uid: widget.post.uid),
                  ),
                );
              },
              child: Row(
                children: [
                  widget.post.profImage == ""
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              AssetImage('assets/images/placeholder.jpg'),
                          backgroundColor:
                              const Color.fromARGB(255, 24, 24, 24),
                        )
                      : ProgressImageDots(url: widget.post.profImage),
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
                              Text(
                                widget.post.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // CUSTOM EMOJI SECTION
                              SizedBox(width: 5),

                              widget.post.userEmoji != ""
                                  ? SizedBox(
                                      height: 25,
                                      child: CachedNetworkImage(
                                        imageUrl: widget.post.userEmoji,
                                        fit: BoxFit.cover,
                                        cacheManager:
                                            InstaCacheManager(), // ⭐ long-term disk cache

                                        placeholder: (context, url) => Center(
                                          child: SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 24, 24, 24),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),

                                        errorWidget: (context, url, error) =>
                                            const Center(),
                                      ))
                                  : SizedBox.shrink()
                            ],
                          ),
                          widget.post.tagline != ""
                              ? Text(
                                  widget.post.tagline,
                                  style: TextStyle(
                                      // fontWeight: FontWeight.bold,
                                      ),
                                )
                              : Container()
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          // IMAGE SECTION
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 250),
                  pageBuilder: (_, __, ___) => FullscreenImageViewer(
                    uid: widget.post.uid,
                    imageUrl: widget.post.postUrl,
                    username: widget.post.username,
                    profilePic: widget.post.profImage,
                  ),
                ),
              );
            },
            onDoubleTap: () async {
              await FirestoreMethods().likePost(
                  'posts', user.uid, widget.post.postId, widget.post.likes);
              setState(() {
                isLikeAnimating = true;
                widget.post.likes.contains(user.uid)
                    ? widget.post.likes.remove(user.uid)
                    : widget.post.likes.add(user.uid);
              });
            },
            child: SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.width * 3 / 4,
                        child: CachedNetworkImage(
                          imageUrl: widget.post.postUrl,
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
            ),
          ),

          // LIKE, COMMENT SECTION
          Row(
            children: [
              LikeAnimation(
                isAnimating: widget.post.likes.contains(user.uid),
                smallLike: true,
                child: IconButton(
                    onPressed: () async {
                      await FirestoreMethods().likePost('posts', user.uid,
                          widget.post.postId, widget.post.likes);
                      setState(() {
                        widget.post.likes.contains(user.uid)
                            ? widget.post.likes.remove(user.uid)
                            : widget.post.likes.add(user.uid);
                      });
                    },
                    icon: widget.post.likes.contains(user.uid)
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
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          CommentsScreen(snap: widget.post.toJson()),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
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
                onPressed: () {
                  HapticFeedback.lightImpact(); // subtle tap feel
                  _openShareSheet(widget.post.toJson());
                },
                icon: const Icon(
                  Icons.send,
                ),
              ),
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
                    widget.post.likes.length == 0
                        ? 'No likes yet'
                        : widget.post.likes.length == 1
                            ? '${widget.post.likes.length} like'
                            : '${widget.post.likes.length} likes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.post.description != ''
                          ? Expanded(
                              child: Text(
                                '${widget.post.description}',
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
                    HapticFeedback.lightImpact(); // subtle tap feel
                    Navigator.of(context, rootNavigator: true).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CommentsScreen(snap: widget.post.toJson()),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
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
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      widget.post.commentCount == null
                          ? 'Add a comment'
                          : widget.post.commentCount == 0
                              ? 'No comments yet'
                              : widget.post.commentCount == 1
                                  ? 'View 1 comment'
                                  : 'View all ${widget.post.commentCount} comments',
                      style: TextStyle(fontSize: 16, color: secondaryColor),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4).copyWith(top: 0),
                  child: Text(
                    DateFormat.yMMMd()
                        .add_jm()
                        .format(widget.post.datePublished.toDate()),
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
