import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/screens/profile_posts_screen.dart';
import 'package:instagram_flutter/screens/reels_screen.dart';
import 'package:instagram_flutter/screens/single_reel_screen.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
  });

  String _formatTime({
    Timestamp? createdAt,
    int? localCreatedAt,
  }) {
    DateTime dt;

    // 1️⃣ Prefer server timestamp
    if (createdAt != null) {
      dt = createdAt.toDate();
    }
    // 2️⃣ Fallback → local timestamp (instant send)
    else if (localCreatedAt != null) {
      dt = DateTime.fromMillisecondsSinceEpoch(localCreatedAt);
    }
    // 3️⃣ Last fallback (very rare)
    else {
      return "";
    }

    final now = DateTime.now();
    final diff = now.difference(dt);

    // ---------- TODAY → show time ----------
    if (diff.inDays == 0) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? "PM" : "AM";
      return "$hour:$min $ampm";
    }

    // ---------- YESTERDAY ----------
    if (diff.inDays == 1) return "Yesterday";

    // ---------- OLDER ----------
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final type = msg['type'] ?? 'text';

    Widget content;

    /// ================= TEXT =================
    if (type == 'text') {
      content = Text(
        msg['text'] ?? "",
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      );
    }

    /// ================= REEL =================
    else if (type == 'reel') {
      content = _ReelPreview(reelId: msg['reelId']);
    }

    /// ================= POST =================
    else if (type == 'post') {
      content = _PostPreview(postId: msg['postId']);
    }

    /// ================= FALLBACK =================
    else {
      content = const Text("Unsupported message");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Container(
                padding: type == 'text'
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFE1306C),
                            Color(0xFFF77737),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: content,
              ),
            ),
          ),

          /// 🕒 subtle timestamp
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(
              _formatTime(
                  createdAt: msg['createdAt'],
                  localCreatedAt: msg['localCreatedAt']),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final Map<String, ImageProvider> reelImageMemoryCache = {};
final Map<String, Map<String, dynamic>> reelDataMemoryCache = {};

class _ReelPreview extends StatefulWidget {
  final String reelId;

  const _ReelPreview({required this.reelId, super.key});

  @override
  State<_ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends State<_ReelPreview> {
  Map<String, dynamic>? _reelData;
  ImageProvider? _thumbnailProvider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    // 🔥 Already cached → use instantly
    if (reelDataMemoryCache.containsKey(widget.reelId)) {
      _reelData = reelDataMemoryCache[widget.reelId];
      _thumbnailProvider = reelImageMemoryCache[widget.reelId];
      _loading = false;
      setState(() {});
      return;
    }

    // 🔥 First time fetch
    final snap = await AppFirestore.reels().doc(widget.reelId).get();

    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;

    ImageProvider? provider;

    if (data['thumbnailUrl'] != null &&
        data['thumbnailUrl'].toString().isNotEmpty) {
      provider = CachedNetworkImageProvider(
        data['thumbnailUrl'],
        cacheManager: InstaCacheManager(),
      );

      // ⭐ Preload image into memory
      await precacheImage(provider, context);
    }

    // ⭐ Store in memory
    reelDataMemoryCache[widget.reelId] = data;
    if (provider != null) {
      reelImageMemoryCache[widget.reelId] = provider;
    }

    if (!mounted) return;

    setState(() {
      _reelData = data;
      _thumbnailProvider = provider;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _reelData == null) {
      return const SizedBox(
        width: 150,
        height: 220,
      );
    }

    final data = _reelData!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SingleReelScreen(snap: data),
          ),
        );
      },
      child: Container(
        width: 150,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _UserHeader(uid: data['uid']),

            /// 🎬 THUMBNAIL
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    if (_thumbnailProvider != null)
                      Image(
                        image: _thumbnailProvider!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: Colors.black12,
                        child: const Icon(Icons.play_arrow, size: 40),
                      ),
                    const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 40,
                    ),
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

final Map<String, ImageProvider> postImageMemoryCache = {};
final Map<String, Map<String, dynamic>> postDataMemoryCache = {};

class _PostPreview extends StatefulWidget {
  final String postId;

  const _PostPreview({required this.postId, super.key});

  @override
  State<_PostPreview> createState() => _PostPreviewState();
}

class _PostPreviewState extends State<_PostPreview> {
  Map<String, dynamic>? _postData;
  ImageProvider? _imageProvider;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  Future<void> _loadIfNeeded() async {
    // 🔥 If already cached → use instantly
    if (postDataMemoryCache.containsKey(widget.postId)) {
      _postData = postDataMemoryCache[widget.postId];
      _imageProvider = postImageMemoryCache[widget.postId];
      _loading = false;
      setState(() {});
      return;
    }

    // 🔥 First time fetch
    final snap = await AppFirestore.posts().doc(widget.postId).get();

    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;

    final provider = CachedNetworkImageProvider(
      data['postUrl'],
      cacheManager: InstaCacheManager(),
    );

    // ⭐ PRELOAD IMAGE INTO MEMORY
    await precacheImage(provider, context);

    // ⭐ STORE IN MEMORY
    postDataMemoryCache[widget.postId] = data;
    postImageMemoryCache[widget.postId] = provider;

    if (!mounted) return;

    setState(() {
      _postData = data;
      _imageProvider = provider;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _postData == null || _imageProvider == null) {
      return const SizedBox(
        width: 150,
        height: 180,
      );
    }

    final data = _postData!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreenPosts(
              postId: widget.postId,
              uid: data['uid'],
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserHeader(uid: data['uid']),
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image(
                image: _imageProvider!, // 🔥 memory image
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String uid;

  const _UserHeader({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('user').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 24);
        }

        final user = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              /// Avatar
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: (user['photoUrl'] != null &&
                        user['photoUrl'].toString().isNotEmpty)
                    ? CachedNetworkImageProvider(user['photoUrl'],
                        cacheManager: InstaCacheManager())
                    : const AssetImage('assets/images/placeholder.jpg')
                        as ImageProvider,
              ),

              const SizedBox(width: 6),

              /// Username + verified
              Expanded(
                child: Row(
                  children: [
                    Text(
                      user['username'] ?? "User",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if ((user['userType'] ?? '') == 'ADMIN')
                      SizedBox(
                        height: 14,
                        child: Image.asset(
                          'assets/images/verification_badge.png',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
