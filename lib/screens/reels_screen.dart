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
import 'package:instagram_flutter/core/route_observer.dart';
import 'package:instagram_flutter/models/group_member.dart';
import 'package:instagram_flutter/providers/group_member_provider.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/comments_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/like_animation.dart';
import 'package:instagram_flutter/widgets/share_screen_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  final String? initialReelId;

  const ReelsScreen({super.key, this.initialReelId});

  @override
  State<ReelsScreen> createState() => ReelsScreenState();
}

class ReelsScreenState extends State<ReelsScreen>
    with AutomaticKeepAliveClientMixin, RouteAware, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;
  final PageController _pageController = PageController();

  int _playSessionId = 0;

  final Map<int, VideoPlayerController> _controllers = {};
  bool _isMutedGlobal = false;
  final List<DocumentSnapshot> _reels = [];

  final Map<String, String> _videoUrlCache = {};
  final ValueNotifier<bool> _likeAnim = ValueNotifier(false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // Another screen pushed on top
    pauseCurrentVideo();
  }

  @override
  void didPopNext() {
    // Returned back to Reels
    if (_isActiveTab) {
      resumeCurrentVideo();
    }
  }

  bool _isLoading = true;
  bool _isInitiallyLoading = true;
  bool _isTappedRefresh = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;
  int _currentIndex = 0;

  static const int _limit = 5;

  bool _isActiveTab = false;

  void setActive(bool active) {
    _isActiveTab = active;

    if (!_isActiveTab) {
      pauseCurrentVideo();
    } else {
      resumeCurrentVideo();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    if (mounted)
      setState(() {
        _isInitiallyLoading = false;
        _isLoading = false;
      });
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
        if (_isActiveTab) {
          controller.play();
        }
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
    _playSessionId++; // 🔥 invalidate old sessions
    final currentSession = _playSessionId;

    // HARD STOP EVERYTHING
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
        controller.setVolume(0);
      }
    }

    _currentIndex = index;

    final fileId = (_reels[index].data() as Map)['fileId'];

    await _createController(index, fileId);

    // 🔥 If user scrolled again during await → cancel
    if (currentSession != _playSessionId) return;

    final controller = _controllers[index];

    if (controller != null && controller.value.isInitialized && _isActiveTab) {
      controller.setVolume(_isMutedGlobal ? 0 : 1);
      controller.play();
    }

    _preloadNext(index);
    _disposeFarControllers(index);

    if (index >= _reels.length - 2) {
      _fetchMoreReels();
    }
  }

  void pauseCurrentVideo() {
    final controller = _controllers[_currentIndex];
    if (controller != null && controller.value.isInitialized) {
      controller.pause();
      controller.setVolume(0);
    }
  }

  void resumeCurrentVideo() {
    final controller = _controllers[_currentIndex];
    if (controller != null && controller.value.isInitialized) {
      controller.setVolume(_isMutedGlobal ? 0 : 1);
      if (_isActiveTab) {
        controller.play();
      }
    }
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
    // setState(() {
    //   setActive(false);
    // });

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(uid: uid)),
    );

    // setState(() {
    //   setActive(true);
    // });
  }

  String _timeAgo(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());

    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${(diff.inDays / 7).floor()}w ago";
  }

  Future<void> refreshReels(String source) async {
    setState(() {
      if (source == "tab") {
        _isTappedRefresh = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final snap = await AppFirestore.reels()
          .orderBy('datePublished', descending: true)
          .limit(_limit)
          .get();

      if (!mounted) return;

      // Dispose old controllers
      for (final c in _controllers.values) {
        c.dispose();
      }

      _controllers.clear();
      _videoUrlCache.clear();

      _reels
        ..clear()
        ..addAll(snap.docs);

      _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
      _hasMore = snap.docs.isNotEmpty;
      _currentIndex = 0;

      if (_reels.isNotEmpty) {
        await _createController(0, (_reels[0].data() as Map)['fileId']);
        _preloadNext(0);
      }

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isTappedRefresh = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseCurrentVideo();
    }

    if (state == AppLifecycleState.resumed) {
      if (_isActiveTab) {
        resumeCurrentVideo();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
        controller.setVolume(0);
      }
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // IMPORTANT
    return SafeArea(
      top: false,
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

        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is OverscrollNotification &&
                notification.overscroll < 0 &&
                _currentIndex == 0 &&
                !_isLoading &&
                !_isTappedRefresh) {
              refreshReels("tab");
            }
            return false;
          },
          child: Stack(
            children: [
              PageView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemCount: _reels.length,
                itemBuilder: (context, index) {
                  final data = _reels[index].data() as Map<String, dynamic>;
                  final controller = _controllers[index];

                  return StreamBuilder<DocumentSnapshot>(
                    stream:
                        AppFirestore.reels().doc(data['reelId']).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final reel =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final uid = Provider.of<GroupMemberProvider>(context,
                              listen: false)
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
                            // if ((controller == null ||
                            //         !controller.value.isInitialized) &&
                            //     index == _currentIndex)
                            //   const Center(
                            //       child: CircularProgressIndicator(
                            //           color: Colors.white70)),

                            /// Bottom gradient
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
                                        onTap: () => _openProfile(data['uid']),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color.fromARGB(
                                              255, 71, 71, 71), // 👈 white base
                                          child: ClipOval(
                                            child: (data['profImage'] != null &&
                                                    data['profImage']
                                                        .toString()
                                                        .isNotEmpty)
                                                ? CachedNetworkImage(
                                                    imageUrl: data['profImage'],
                                                    fit: BoxFit.cover,
                                                    width: 32,
                                                    height: 32,
                                                    placeholder:
                                                        (context, url) =>
                                                            Container(
                                                      color: const Color
                                                          .fromARGB(255, 54, 54,
                                                          54), // 👈 white while loading
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
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
                                        onTap: () => _openProfile(data['uid']),
                                        child: Text(data['username'] ?? ''),
                                      ),
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
                                          duration:
                                              const Duration(milliseconds: 400),
                                          onEnd: () => _likeAnim.value = false,
                                          child: IconButton(
                                            onPressed: () async {
                                              await FirestoreMethods().likePost(
                                                  'reels',
                                                  uid,
                                                  data['reelId'],
                                                  data['likes']);
                                            },
                                            icon: PhosphorIcon(
                                                isLiked
                                                    ? PhosphorIcons.heart(
                                                        PhosphorIconsStyle.fill)
                                                    : PhosphorIcons.heart(
                                                        PhosphorIconsStyle
                                                            .regular),
                                                color: isLiked
                                                    ? Colors.red
                                                    : Colors.white),
                                          ),
                                        );
                                      }),
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
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            const begin = Offset(0.0, 1.0);
                                            const end = Offset.zero;
                                            const curve = Curves.ease;

                                            var tween = Tween(
                                                    begin: begin, end: end)
                                                .chain(
                                                    CurveTween(curve: curve));

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
                              opacity: _isMutedGlobal ? 1 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: Center(
                                child: PhosphorIcon(
                                    _isMutedGlobal
                                        ? PhosphorIcons.speakerSimpleSlash(
                                            PhosphorIconsStyle.regular)
                                        : PhosphorIcons.speakerHigh(
                                            PhosphorIconsStyle.regular),
                                    size: 28,
                                    color: Colors.white),
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
                                        PhosphorIcons.heart(
                                            PhosphorIconsStyle.fill),
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

              //  else if (_isTappedRefresh)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  offset: _isTappedRefresh ? Offset.zero : const Offset(0, -1),
                  curve: const Cubic(0.175, 0.885, 0.32, 1.7),
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedOpacity(
                    opacity: _isTappedRefresh ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(221, 19, 19, 19)
                                .withOpacity(1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_isInitiallyLoading)
                const Center(
                    child: CircularProgressIndicator(color: Colors.white70))
              else if (_isLoading)
                SizedBox()
              else if (_reels.isEmpty)
                const Center(
                    child: Text("No reels found",
                        style: TextStyle(color: Colors.white)))

              // const Center(
              //     child: CircularProgressIndicator(color: Colors.white70))
              // : _reels.isEmpty
              //     ? const Center(
              //         child: Text("No reels found",
              //             style: TextStyle(color: Colors.white)))
            ],
          ),
        ),
      ),
    );
  }
}
