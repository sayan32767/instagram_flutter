import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:instagram_flutter/widgets/share_screen_sheet.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReelsScreen extends StatefulWidget {
  final String? initialReelId;

  const ReelsScreen({super.key, this.initialReelId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> _isMuted = {};
  final List<DocumentSnapshot> _reels = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;
  int _currentIndex = 0;

  static const int _limit = 5;

  bool isLikeAnimating = false;

  final ValueNotifier<bool> _likeAnim = ValueNotifier(false);

  final Map<String, String> _videoUrlCache = {};

  Future<void> _warmUpServer() async {
    try {
      final String baseUrl = dotenv.get('BASE_URL', fallback: '');
      await http.get(Uri.parse("$baseUrl/ping")).timeout(
            const Duration(seconds: 25),
          );
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _warmUpServer(); // ⭐ wakes Render
    _loadInitialReels();
  }

  Future<String> fetchTelegramVideoUrl(String fileId) async {
    if (_videoUrlCache.containsKey(fileId)) {
      return _videoUrlCache[fileId]!;
    }

    final String baseUrl = dotenv.get('BASE_URL', fallback: '');

    for (int i = 0; i < 3; i++) {
      try {
        final res = await http
            .get(Uri.parse("$baseUrl/video-url/$fileId"))
            .timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final url = data["url"];

          _videoUrlCache[fileId] = url; // ⭐ cache it
          return url;
        }
      } on TimeoutException {
        if (i == 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception("Failed after retries");
  }

  void _openShareSheet(Map<String, dynamic> reelData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return FractionallySizedBox(
            heightFactor: 0.75, // 👈 stops before top (75% screen)
            child: ShareSheet(post: reelData, type: 'reel'));
      },
    );
  }

  Future<void> _openProfile(String uid) async {
    /// ⏸ Pause current reel before navigation
    _controllers[_currentIndex]?.pause();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(uid: uid),
      ),
    );

    /// ▶️ Resume when coming back
    _controllers[_currentIndex]?.play();
  }

  /// ⏱ time-ago helper
  String _timeAgo(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());

    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${(diff.inDays / 7).floor()}w ago";
  }

  /// 🔥 INITIAL LOAD
  Future<void> _loadInitialReels() async {
    /// 🔹 CASE 1 — Open specific reel
    if (widget.initialReelId != null) {
      final doc = await AppFirestore.reels().doc(widget.initialReelId).get();

      if (doc.exists) {
        _reels.add(doc);
        _lastDoc = doc;

        await _createController(0, (doc.data() as Map)['fileId']);
      }

      _hasMore = false; // single reel mode
    }

    /// 🔹 CASE 2 — Normal feed
    else {
      final snap = await AppFirestore.reels()
          .orderBy('datePublished', descending: true)
          .limit(_limit)
          .get();

      _reels.addAll(snap.docs);

      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;

        await _createController(0, (_reels[0].data() as Map)['fileId']);
        _preloadNext(0);
      } else {
        _hasMore = false;
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// 📦 PAGINATION
  Future<void> _fetchMoreReels() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    final snap = await AppFirestore.reels()
        .orderBy('datePublished', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;

      final oldLength = _reels.length;
      _reels.addAll(snap.docs);

      /// preload first newly added reel
      final firstNewIndex = oldLength;
      final fileId = (_reels[firstNewIndex].data() as Map)['fileId'];
      _createController(firstNewIndex, fileId);
    }

    _isFetchingMore = false;
    if (mounted) setState(() {});
  }

  Future<void> _createController(int index, String fileId) async {
    if (_controllers.containsKey(index)) return;

    try {
      final url = await fetchTelegramVideoUrl(fileId);

      /// ❗ index may be invalid now
      if (!mounted || index >= _reels.length) return;

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      if (!mounted || index >= _reels.length) {
        controller.dispose();
        return;
      }

      controller.setLooping(true);

      _controllers[index] = controller;
      _isMuted[index] = false;

      if (index == _currentIndex && mounted) {
        setState(() {});
        controller.play();
      }
    } catch (e) {
      debugPrint("❌ Reel failed at index $index → $e");

      /// 🔥 remove any half-created controller
      _controllers[index]?.dispose();
      _controllers.remove(index);
      _isMuted.remove(index);

      /// ❗ index safety
      if (!mounted || _reels.isEmpty || index >= _reels.length) return;

      if (e is! TimeoutException) {
        _reels.removeAt(index);
      }

      /// move safely
      final nextIndex = index >= _reels.length ? _reels.length - 1 : index;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(nextIndex);
        }
      });

      setState(() {});
    }
  }

  /// 🔊 TOGGLE MUTE
  void _toggleMute(int index) {
    final controller = _controllers[index];
    if (controller == null) return;

    final muted = _isMuted[index] ?? false;

    controller.setVolume(muted ? 1 : 0);

    setState(() {
      _isMuted[index] = !muted;
    });
  }

  /// ⚡ PRELOAD NEXT
  void _preloadNext(int index) {
    final nextIndex = index + 1;

    if (nextIndex < _reels.length) {
      final fileId = (_reels[nextIndex].data() as Map)['fileId'];
      _createController(nextIndex, fileId);
    }
  }

  /// 🧹 DISPOSE FAR CONTROLLERS
  void _disposeFarControllers(int index) {
    final keysToRemove =
        _controllers.keys.where((i) => (i - index).abs() > 2).toList();

    for (final key in keysToRemove) {
      _controllers[key]?.pause();
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _isMuted.remove(key);
    }
  }

  /// ▶️ PAGE CHANGE
  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pause();
    _currentIndex = index;

    final fileId = (_reels[index].data() as Map)['fileId'];

    _createController(index, fileId);
    _controllers[index]?.play();

    _preloadNext(index);
    _disposeFarControllers(index);

    if (index >= _reels.length - 2) {
      _fetchMoreReels();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.white70,
              ))
            : _reels.isEmpty
                ? const Center(child: Text("No reels yet"))
                : PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: _onPageChanged,
                    itemCount: _reels.length,
                    itemBuilder: (context, index) {
                      final data = _reels[index].data() as Map<String, dynamic>;
                      final controller = _controllers[index];

                      if (controller == null ||
                          !controller.value.isInitialized) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            /// optional thumbnail if you have one
                            if (data["thumbnailUrl"] != null)
                              CachedNetworkImage(
                                imageUrl: data["thumbnailUrl"],
                                fit: BoxFit.cover,
                                cacheManager: InstaCacheManager(),
                              )
                            else
                              Container(color: Colors.black),

                            /// loader ONLY for current reel
                            if (index == _currentIndex)
                              const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white70),
                              ),
                          ],
                        );
                      }

                      return StreamBuilder<DocumentSnapshot>(
                        stream: AppFirestore.reels()
                            .doc(data['reelId'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }

                          final reel =
                              snapshot.data!.data() as Map<String, dynamic>;

                          final uid =
                              Provider.of<UserProvider>(context, listen: false)
                                  .getUser!
                                  .uid;

                          final isLiked = (reel['likes'] as List).contains(uid);
                          final likeCount = reel['likeCount'] ??
                              (reel['likes'] as List).length;
                          final commentCount = reel['commentCount'] ?? 0;

                          return GestureDetector(
                            onTap: () => _toggleMute(index),

                            /// ❤️ DOUBLE TAP LIKE (correct place)
                            onDoubleTap: () async {
                              setState(() {
                                isLikeAnimating = true;
                              });
                              await FirestoreMethods().likePost(
                                'reels',
                                uid,
                                data['reelId'],
                                reel['likes'] as List,
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                /// 1️⃣ VIDEO (base layer)
                                FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: controller.value.size.width,
                                    height: controller.value.size.height,
                                    child: AnimatedScale(
                                      scale: controller.value.isInitialized
                                          ? 1
                                          : 1.05,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: VideoPlayer(controller),
                                      ),
                                    ),
                                  ),
                                ),

                                /// 3️⃣ BOTTOM DARK GRADIENT
                                IgnorePointer(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black87
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ),

                                /// 4️⃣ BOTTOM TEXT (username, time, description)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 24,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('user')
                                            .doc(data['uid'])
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const SizedBox.shrink();
                                          }

                                          final user = snapshot.data!.data()
                                              as Map<String, dynamic>;

                                          return Row(
                                            children: [
                                              /// 👤 Avatar (tappable)
                                              GestureDetector(
                                                onTap: () =>
                                                    _openProfile(data['uid']),
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Colors.grey.shade800,
                                                  backgroundImage: (user[
                                                                  'photoUrl'] !=
                                                              null &&
                                                          user['photoUrl']
                                                              .toString()
                                                              .isNotEmpty)
                                                      ? CachedNetworkImageProvider(
                                                          user['photoUrl'],
                                                          cacheManager:
                                                              InstaCacheManager())
                                                      : const AssetImage(
                                                              'assets/images/placeholder.jpg')
                                                          as ImageProvider,
                                                ),
                                              ),

                                              const SizedBox(width: 10),

                                              /// 🧑 Username (tappable)
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .translucent,
                                                      onTap: () => _openProfile(
                                                          data['uid']),
                                                      child: Text(
                                                          user['username']),
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    user['userType'] == 'ADMIN'
                                                        ? SizedBox(
                                                            height: 20,
                                                            child: Image.asset(
                                                                'assets/images/verification_badge.png'),
                                                          )
                                                        : Container()
                                                  ],
                                                ),
                                              ),

                                              /// ⏱ Time ago (non-interactive)
                                              IgnorePointer(
                                                child: Text(
                                                  _timeAgo(
                                                      data['datePublished']),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 6),

                                      /// Description (non-interactive)
                                      IgnorePointer(
                                        child: Text(
                                          data['description'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// RIGHT SIDE ACTION BUTTONS (Instagram style)
                                Positioned(
                                  right: 12,
                                  bottom: 120,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      /// ❤️ LIKE
                                      IconButton(
                                        onPressed: () async {
                                          await FirestoreMethods().likePost(
                                            'reels',
                                            uid,
                                            data['reelId'],
                                            reel['likes'] as List,
                                          );
                                        },
                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.white,
                                          size: 30,
                                        ),
                                      ),

                                      Text(
                                        likeCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),

                                      const SizedBox(height: 8),

                                      /// 💬 COMMENT
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CommentsScreen(
                                                snap: data,
                                                collectionName: 'reels',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.comment_outlined,
                                            color: Colors.white, size: 28),
                                      ),

                                      Text(
                                        commentCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),

                                      const SizedBox(height: 8),

                                      /// 📤 SHARE
                                      IconButton(
                                        onPressed: () {
                                          HapticFeedback
                                              .lightImpact(); // subtle tap feel
                                          _openShareSheet(data);
                                        },
                                        icon: const Icon(Icons.send_outlined,
                                            color: Colors.white, size: 28),
                                      ),
                                    ],
                                  ),
                                ),

                                /// 5️⃣ CENTER MUTE ICON
                                AnimatedOpacity(
                                  opacity: (_isMuted[index] ?? true) ? 1 : 0,
                                  duration: const Duration(milliseconds: 250),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        (_isMuted[index] ?? true)
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),

                                // 6️⃣ DOUBLE TAP HEART
                                ValueListenableBuilder(
                                  valueListenable: _likeAnim,
                                  builder: (_, value, __) {
                                    return AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: isLikeAnimating ? 1 : 0,
                                      child: LikeAnimation(
                                        isAnimating: isLikeAnimating,
                                        duration:
                                            const Duration(milliseconds: 400),
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
                                            color: Colors
                                                .white, // important for ShaderMask
                                            size: 120,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
