// Final FULL ReelsScreen with overlays, smooth fade/scale, caching, warmup, no jump

import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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

class ReelsScreen extends StatefulWidget {
  final String? initialReelId;

  const ReelsScreen({super.key, this.initialReelId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();

  final Map<int, VideoPlayerController> _controllers = {};
  bool _isMutedGlobal = false;
  final List<DocumentSnapshot> _reels = [];

  final Map<String, String> _videoUrlCache = {};
  final ValueNotifier<bool> _likeAnim = ValueNotifier(false);

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;
  int _currentIndex = 0;

  static const int _limit = 5;

  @override
  void initState() {
    super.initState();
    _warmUpServer();
    _loadInitialReels();
  }

  Future<void> _warmUpServer() async {
    try {
      final baseUrl = dotenv.get('BASE_URL', fallback: '');
      await http
          .get(Uri.parse("$baseUrl/health"))
          .timeout(const Duration(seconds: 25));
    } catch (_) {}
  }

  Future<String> fetchTelegramVideoUrl(String fileId) async {
    if (_videoUrlCache.containsKey(fileId)) return _videoUrlCache[fileId]!;

    final baseUrl = dotenv.get('BASE_URL', fallback: '');

    for (int i = 0; i < 3; i++) {
      try {
        final res = await http
            .get(Uri.parse("$baseUrl/video-url/$fileId"))
            .timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final url = json.decode(res.body)["url"];
          _videoUrlCache[fileId] = url;
          return url;
        }
      } on TimeoutException {
        if (i == 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception("Failed after retries");
  }

  Future<Map<String, dynamic>?> _fetchUser(String uid) async {
    final snap =
        await FirebaseFirestore.instance.collection('user').doc(uid).get();

    return snap.data(); // contains username, photoUrl, userType, etc.
  }

  final Map<String, Future<Map<String, dynamic>?>> _userFutureCache = {};
  Future<Map<String, dynamic>?> _getUserFuture(String uid) {
    return _userFutureCache.putIfAbsent(uid, () => _fetchUser(uid));
  }

  Future<void> _loadInitialReels() async {
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

    if (mounted) setState(() => _isLoading = false);
  }

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
      if (!mounted || index >= _reels.length) return;

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      if (!mounted || index >= _reels.length) {
        controller.dispose();
        return;
      }

      controller.setLooping(true);
      _controllers[index] = controller;
      controller.setVolume(_isMutedGlobal ? 0 : 1);

      if (index == _currentIndex && mounted) {
        setState(() {});
        controller.play();
      }
    } catch (_) {}
  }

  void _toggleMute() {
    _isMutedGlobal = !_isMutedGlobal;

    for (final controller in _controllers.values) {
      controller.setVolume(_isMutedGlobal ? 0 : 1);
    }

    setState(() {});
  }

  void _preloadNext(int index) {
    final nextIndex = index + 1;
    if (nextIndex < _reels.length) {
      final fileId = (_reels[nextIndex].data() as Map)['fileId'];
      _createController(nextIndex, fileId);
    }
  }

  void _disposeFarControllers(int index) {
    final keysToRemove =
        _controllers.keys.where((i) => (i - index).abs() > 2).toList();

    for (final k in keysToRemove) {
      final controller = _controllers[k];
      if (controller != null) {
        if (controller.value.isInitialized) {
          controller.pause();
        }
        controller.dispose();
      }
      _controllers.remove(k);
    }
  }

  Future<void> _onPageChanged(int index) async {
    _controllers[_currentIndex]?.pause();
    _currentIndex = index;

    final fileId = (_reels[index].data() as Map)['fileId'];

    await _createController(index, fileId); // ⭐ WAIT here
    _controllers[index]?.play();

    _preloadNext(index);
    _disposeFarControllers(index);

    if (index >= _reels.length - 2) _fetchMoreReels();
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

  Future<void> _openProfile(String uid) async {
    _controllers[_currentIndex]?.pause();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)),
    );

    _controllers[_currentIndex]?.play();
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
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white70))
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: _reels.length,
              itemBuilder: (context, index) {
                final data = _reels[index].data() as Map<String, dynamic>;
                final controller = _controllers[index];

                return StreamBuilder<DocumentSnapshot>(
                  stream: AppFirestore.reels().doc(data['reelId']).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final reel = snapshot.data!.data() as Map<String, dynamic>;
                    final uid =
                        Provider.of<UserProvider>(context, listen: false)
                            .getUser!
                            .uid;
                    final isLiked = (reel['likes'] as List).contains(uid);
                    final likeCount =
                        reel['likeCount'] ?? (reel['likes'] as List).length;
                    final commentCount = reel['commentCount'] ?? 0;

                    return GestureDetector(
                      onTap: _toggleMute,
                      onDoubleTap: () async {
                        _likeAnim.value = true;
                        await FirestoreMethods().likePost(
                            'reels', uid, data['reelId'], reel['likes']);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          /// Thumbnail
                          if (data['thumbnailUrl'] != null)
                            CachedNetworkImage(
                              imageUrl: data['thumbnailUrl'],
                              fit: BoxFit.cover,
                              cacheManager: InstaCacheManager(),
                            )
                          else
                            Container(color: Colors.black),

                          /// Video fade + scale
                          if (controller != null)
                            AnimatedOpacity(
                              opacity: controller.value.isInitialized ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: AnimatedScale(
                                scale:
                                    controller.value.isInitialized ? 1 : 1.04,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: controller.value.size.width,
                                    height: controller.value.size.height,
                                    child: VideoPlayer(controller),
                                  ),
                                ),
                              ),
                            ),

                          /// Loader
                          if ((controller == null ||
                                  !controller.value.isInitialized) &&
                              index == _currentIndex)
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white70)),

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
                          FutureBuilder(
                              future: _getUserFuture(data['uid']),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: const CircularProgressIndicator(
                                        color: Colors.white70),
                                  );
                                }

                                final user = snapshot.data!;

                                return Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 24,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _openProfile(user['uid']),
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundImage: user[
                                                          'photoUrl'] !=
                                                      null
                                                  ? CachedNetworkImageProvider(
                                                      user['photoUrl'])
                                                  : const AssetImage(
                                                          'assets/images/placeholder.jpg')
                                                      as ImageProvider,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                              onTap: () {
                                                // Navigate to user profile screen
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ProfileScreen(
                                                      uid: user['uid'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child:
                                                  Text(user['username'] ?? '')),
                                          SizedBox(width: 5),
                                          (user['userType'] != null &&
                                                  user['userType'] == 'ADMIN')
                                              ? SizedBox(
                                                  height: 20,
                                                  child: Image.asset(
                                                      'assets/images/verification_badge.png'),
                                                )
                                              : Container(),
                                          const Spacer(),
                                          Text(_timeAgo(data['datePublished']),
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(data['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                );
                              }),

                          /// Right actions
                          Positioned(
                            right: 12,
                            bottom: 120,
                            child: Column(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await FirestoreMethods().likePost('reels',
                                        uid, data['reelId'], reel['likes']);
                                  },
                                  icon: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          isLiked ? Colors.red : Colors.white),
                                ),
                                Text(likeCount.toString(),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 8),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            CommentsScreen(
                                          snap: data,
                                          collectionName: 'reels',
                                        ),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          const begin = Offset(0.0, 1.0);
                                          const end = Offset.zero;
                                          const curve = Curves.ease;

                                          var tween = Tween(
                                                  begin: begin, end: end)
                                              .chain(CurveTween(curve: curve));

                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.comment_outlined,
                                      color: Colors.white),
                                ),
                                Text(commentCount.toString(),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 8),
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback
                                        .lightImpact(); // subtle tap feel
                                    _openShareSheet(data);
                                  },
                                  icon: const Icon(Icons.send_outlined,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          /// Mute icon
                          AnimatedOpacity(
                            opacity: _isMutedGlobal ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Center(
                              child: Icon(
                                  _isMutedGlobal
                                      ? Icons.volume_off
                                      : Icons.volume_up,
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
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
