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
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10.0, 0, 6),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                ),
                GestureDetector(
                  onTap: () async {
                    await FirestoreMethods().likePost('posts', user.uid,
                        widget.post.postId, widget.post.likes);
                    setState(() {
                      widget.post.likes.contains(user.uid)
                          ? widget.post.likes.remove(user.uid)
                          : widget.post.likes.add(user.uid);
                    });
                  },
                  child: Row(
                    children: [
                      LikeAnimation(
                        isAnimating: widget.post.likes.contains(user.uid),
                        smallLike: true,
                        child: Container(
                            child: widget.post.likes.contains(user.uid)
                                ? PhosphorIcon(
                                    PhosphorIcons.heart(
                                        PhosphorIconsStyle.fill),
                                    color: Colors.redAccent,
                                  )
                                : PhosphorIcon(
                                    PhosphorIcons.heart(
                                        PhosphorIconsStyle.regular),
                                    color: Colors.white,
                                  )),
                      ),
                      if (widget.post.likes.length > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            widget.post.likes.length == 1
                                ? '1'
                                : '${widget.post.likes.length}',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        )
                    ],
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                GestureDetector(
                  onTap: () {
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
                        color: Colors.white,
                      ),
                      widget.post.commentCount != null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Text(
                                widget.post.commentCount == 0
                                    ? ''
                                    : widget.post.commentCount == 1
                                        ? '1'
                                        : '${widget.post.commentCount}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            )
                          : Container()
                    ],
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact(); // subtle tap feel
                    _openShareSheet(widget.post.toJson());
                  },
                  child: PhosphorIcon(
                    size: 22,
                    PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.regular),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
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
                // DefaultTextStyle(
                //   style: Theme.of(context).textTheme.bodySmall!.copyWith(
                //         fontWeight: FontWeight.w800,
                //       ),
                //   child: Text(
                //     widget.post.likes.length == 0
                //         ? 'No likes yet'
                //         : widget.post.likes.length == 1
                //             ? '${widget.post.likes.length} like'
                //             : '${widget.post.likes.length} likes',
                //     style: Theme.of(context).textTheme.bodyMedium,
                //   ),
                // ),
                // Container(
                //   width: double.infinity,
                //   padding: EdgeInsets.only(top: 4),
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       widget.post.description != ''
                //           ? Expanded(
                //               child: Text(
                //                 '${widget.post.description}' +
                //                     'whsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssbdjjjjjjjsanashc sahc shcj schs cjsh csjac shc sj                                  aausub',
                //                 maxLines: null,
                //                 overflow: TextOverflow.clip,
                //               ),
                //             )
                //           : Container()
                //     ],
                //   ),
                // ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  child: widget.post.description != null &&
                          widget.post.description != ""
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: ExpandableCaption(
                            uid: widget.post.uid,
                            username: widget.post.username ?? null,
                            text: widget.post.description!,
                            previewLimit: 140,
                            maxLimit: 500,
                          ),
                        )
                      : const SizedBox(),
                ),
                // InkWell(
                //   onTap: () {
                //     HapticFeedback.lightImpact(); // subtle tap feel
                //     Navigator.of(context, rootNavigator: true).push(
                //       PageRouteBuilder(
                //         pageBuilder: (context, animation, secondaryAnimation) =>
                //             CommentsScreen(snap: widget.post.toJson()),
                //         transitionsBuilder:
                //             (context, animation, secondaryAnimation, child) {
                //           const begin = Offset(0.0, 1.0);
                //           const end = Offset.zero;
                //           const curve = Curves.ease;

                //           var tween = Tween(begin: begin, end: end)
                //               .chain(CurveTween(curve: curve));

                //           return SlideTransition(
                //             position: animation.drive(tween),
                //             child: child,
                //           );
                //         },
                //       ),
                //     );
                //   },
                //   child: Container(
                //     padding: EdgeInsets.symmetric(vertical: 4),
                //     child: Text(
                //       widget.post.commentCount == null
                //           ? 'Add a comment'
                //           : widget.post.commentCount == 0
                //               ? 'No comments yet'
                //               : widget.post.commentCount == 1
                //                   ? 'View 1 comment'
                //                   : 'View all ${widget.post.commentCount} comments',
                //       style: TextStyle(fontSize: 16, color: secondaryColor),
                //     ),
                //   ),
                // ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4).copyWith(top: 0),
                  child: Text(
                    instagramTime(widget.post.datePublished.toDate()),
                    style: TextStyle(fontSize: 14, color: secondaryColor),
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

String instagramTime(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds}s';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d';
  } else {
    // 🔥 Show exact date after 6 days

    if (now.year == date.year) {
      // Same year → Jan 12
      return DateFormat('MMM d').format(date);
    } else {
      // Different year → Jan 12, 2023
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

String cleanCaption(String text) {
  text = text.trim();

  // Remove multiple spaces / line breaks
  text = text.replaceAll(RegExp(r'\s+'), ' ');

  // Limit extreme repeated characters (aaaaaaa → aaa)
  text = text.replaceAll(RegExp(r'(.)\1{5,}'), r'\1\1\1');

  return text;
}

class ExpandableCaption extends StatefulWidget {
  final String text;
  final String uid;
  final String? username; // TODO: pass username for bolding

  /// Characters shown before "See more"
  final int previewLimit;

  /// Absolute maximum characters allowed
  final int maxLimit;

  const ExpandableCaption({
    super.key,
    required this.uid,
    required this.text,
    this.username = '',
    this.previewLimit = 140,
    this.maxLimit = 500, // hard safety cap
  });

  @override
  State<ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<ExpandableCaption> {
  bool isExpanded = false;
  List<TextSpan> buildSpans(String text) {
    final RegExp hashtagRegExp = RegExp(r'(#\w+)');

    final matches = hashtagRegExp.allMatches(text);

    if (matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    int lastMatchEnd = 0;
    List<TextSpan> spans = [];

    for (final match in matches) {
      // Normal text before hashtag
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
          ),
        );
      }

      // Hashtag text
      final hashtag = match.group(0)!;

      spans.add(
        TextSpan(
          text: hashtag,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              print("Tapped $hashtag");
              // 🔥 Later navigate to hashtag page
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    // Remaining text after last hashtag
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    String cleaned = cleanCaption(widget.text);

    // 🔥 Hard truncate (even when expanded)
    if (cleaned.length > widget.maxLimit) {
      cleaned = cleaned.substring(0, widget.maxLimit);
    }

    final shouldTrim = cleaned.length > widget.previewLimit;

    final displayText = (!isExpanded && shouldTrim)
        ? cleaned.substring(0, widget.previewLimit)
        : cleaned;

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '${widget.username} ',
            style: TextStyle(fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: widget.uid),
                  ),
                );
              },
          ),

          // TextSpan(text: displayText),
          ...buildSpans(displayText),
          if (shouldTrim && !isExpanded)
            TextSpan(
              text: '... See more',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    isExpanded = true;
                  });
                },
            ),
          if (shouldTrim && isExpanded)
            TextSpan(
              text: '  See less',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    isExpanded = false;
                  });
                },
            ),
        ],
      ),
    );
  }
}
