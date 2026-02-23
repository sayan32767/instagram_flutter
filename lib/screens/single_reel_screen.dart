import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/core/route_observer.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:instagram_flutter/widgets/share_screen_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

class SingleReelScreen extends StatefulWidget {
  final Map snap;

  const SingleReelScreen({super.key, required this.snap});

  @override
  State<SingleReelScreen> createState() => SingleReelScreenState();
}

class SingleReelScreenState extends State<SingleReelScreen>
    with RouteAware, WidgetsBindingObserver {
  final ValueNotifier<bool> _likeAnim = ValueNotifier(false);
  VideoPlayerController? _controller;
  bool _isMuted = false;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createController(widget.snap['fileId']);
  }

  Future<String> fetchTelegramVideoUrl(String fileId) async {
    final baseUrl = dotenv.get('BASE_URL', fallback: '');

    for (int i = 0; i < 3; i++) {
      try {
        final res = await http
            .get(Uri.parse("$baseUrl/video-url/$fileId"))
            .timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final url = json.decode(res.body)["url"];
          return url;
        }
      } on TimeoutException {
        if (i == 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception("Failed after retries");
  }

  Future<void> _createController(String fileId) async {
    _controller?.dispose();
    _controller = null;

    final url = await fetchTelegramVideoUrl(fileId);
    if (!mounted) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    controller.setLooping(true);
    controller.play();

    setState(() {
      _controller = controller;
    });
  }

  void _resume() {
    if (!mounted) return;
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.setVolume(_isMuted ? 0 : 1);
      _controller!.play();
    }
  }

  void _toggleMute() {
    if (_controller == null) return;

    _isMuted = !_isMuted;
    _controller!.setVolume(_isMuted ? 0 : 1);

    setState(() {});
  }

  Future<void> _openProfile(String uid) async {
    _controller?.pause();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)),
    );

    _resume();
  }

  void _openShareSheet(Map<String, dynamic> reelData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.75,
        child: ShareSheet(post: reelData, type: 'reel'),
      ),
    );
  }

  String _timeAgo(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());

    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${(diff.inDays / 7).floor()}w ago";
  }

  @override
  void didUpdateWidget(covariant SingleReelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.snap['fileId'] != widget.snap['fileId']) {
      _createController(widget.snap['fileId']);
    }
  }

  @override
  void didPushNext() {
    // Another screen pushed on top
    _controller?.pause();
  }

  @override
  void didPopNext() {
    // Returned from profile or another reel
    _resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.pause();
    }

    if (state == AppLifecycleState.resumed) {
      _resume();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ⭐ important
      appBar: AppBar(
        title: const Text(
          "Reels",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        /// ⭐ Dark gradient only in AppBar area
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black87,
                Colors.black54,
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      backgroundColor: mobileBackgroundColor,
      body: StreamBuilder(
        stream: AppFirestore.reels()
            .doc(widget.snap['reelId'])
            .snapshots(includeMetadataChanges: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Reel not found",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final reelData = snapshot.data!.data() as Map<String, dynamic>;

          return Hero(
            tag: widget.snap['reelId'],
            child: GestureDetector(
              onTap: _toggleMute,
              onDoubleTap: () async {
                _likeAnim.value = true;

                if (_isLiking) return;
                _isLiking = true;

                await FirestoreMethods().likePost(
                  'reels',
                  uid,
                  reelData['reelId'],
                  reelData['likes'] ?? [],
                );

                _isLiking = false;
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  /// Thumbnail
                  if (reelData['thumbnailUrl'] != null)
                    CachedNetworkImage(
                      imageUrl: reelData['thumbnailUrl'],
                      fit: BoxFit.cover,
                      cacheManager: InstaCacheManager(),
                    )
                  else
                    Container(color: Colors.black),

                  /// Video fade + scale
                  if (_controller != null)
                    AnimatedOpacity(
                      opacity: _controller!.value.isInitialized ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedScale(
                        scale: _controller!.value.isInitialized ? 1 : 1.04,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),
                    ),

                  /// Loader

                  /// Bottom gradient
                  IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  /// Bottom text + avatar
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _openProfile(reelData['uid']),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color.fromARGB(
                                    255, 71, 71, 71), // 👈 white base
                                child: ClipOval(
                                  child: (reelData['profImage'] != null &&
                                          reelData['profImage']
                                              .toString()
                                              .isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: reelData['profImage'],
                                          fit: BoxFit.cover,
                                          width: 32,
                                          height: 32,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: const Color.fromARGB(
                                                255,
                                                54,
                                                54,
                                                54), // 👈 white while loading
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                            'assets/images/placeholder.jpg',
                                            fit: BoxFit.cover,
                                            width: 32,
                                            height: 32,
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/placeholder.jpg',
                                          fit: BoxFit.cover,
                                          width: 32,
                                          height: 32,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                                onTap: () => _openProfile(reelData['uid']),
                                child: Text(reelData['username'] ?? '')),
                            const Spacer(),
                            Text(_timeAgo(reelData['datePublished']),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(reelData['description'] ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                  /// Right actions
                  Positioned(
                    right: 12,
                    bottom: 120,
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                            valueListenable: _likeAnim,
                            builder: (_, value, __) {
                              return LikeAnimation(
                                  isAnimating: value,
                                  duration: const Duration(milliseconds: 400),
                                  onEnd: () => _likeAnim.value = false,
                                  child: IconButton(
                                    onPressed: () async {
                                      if (_isLiking) return;
                                      _isLiking = true;
                                      await FirestoreMethods().likePost(
                                        'reels',
                                        uid,
                                        reelData['reelId'],
                                        reelData['likes'] ?? [],
                                      );
                                      _isLiking = false;
                                    },
                                    icon: PhosphorIcon(
                                      (reelData['likes'] ?? []).contains(uid)
                                          ? PhosphorIcons.heart(
                                              PhosphorIconsStyle.fill)
                                          : PhosphorIcons.heart(
                                              PhosphorIconsStyle.regular),
                                      color: (reelData['likes'] ?? [])
                                              .contains(uid)
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                  ));
                            }),
                        Text(reelData['likes'].length.toString(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        CommentsScreen(
                                  snap: reelData,
                                  collectionName: 'reels',
                                ),
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
                          icon: PhosphorIcon(
                              PhosphorIcons.chatCircle(
                                  PhosphorIconsStyle.regular),
                              color: Colors.white),
                        ),
                        Text((reelData['commentCount'] ?? 0).toString(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact(); // subtle tap feel
                            _openShareSheet(reelData as Map<String, dynamic>);
                          },
                          icon: PhosphorIcon(
                              PhosphorIcons.paperPlaneTilt(
                                  PhosphorIconsStyle.regular),
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  /// Mute icon
                  AnimatedOpacity(
                    opacity: _isMuted ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Center(
                      child: PhosphorIcon(
                          _isMuted
                              ? PhosphorIcons.speakerSimpleSlash()
                              : PhosphorIcons.speakerHigh(),
                          size: 28),
                    ),
                  ),

                  /// Double tap heart
                  ValueListenableBuilder<bool>(
                    valueListenable: _likeAnim,
                    builder: (_, value, __) {
                      return AnimatedOpacity(
                        opacity: value ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: LikeAnimation(
                          isAnimating: value,
                          duration: const Duration(milliseconds: 400),
                          onEnd: () => _likeAnim.value = false,
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
                            child: PhosphorIcon(
                              PhosphorIcons.heart(PhosphorIconsStyle.fill),
                              color: Colors.white, // important for ShaderMask
                              size: 120,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
