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

class _ReelPreview extends StatelessWidget {
  final String reelId;

  const _ReelPreview({required this.reelId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: AppFirestore.reels().doc(reelId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 150,
            height: 220,
            child: Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            )),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) return const Text("Reel not found");

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
            height: 220, // ⭐ keeps full card height stable
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                /// 👤 USER HEADER
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
                        if (data['thumbnailUrl'] != null)
                          CachedNetworkImage(
                            imageUrl: data['thumbnailUrl'],
                            fit: BoxFit.cover,
                            cacheManager: InstaCacheManager(),
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
      },
    );
  }
}

class _PostPreview extends StatelessWidget {
  final String postId;

  const _PostPreview({required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: AppFirestore.posts().doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 150,
            height: 180,
            child: Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            )),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null)
          return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: const Text("Post not found"));

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreenPosts(
                  postId: postId,
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
                /// 👤 LIVE USER HEADER
                _UserHeader(uid: data['uid']),

                /// 🖼 POST IMAGE
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: data['postUrl'],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    cacheManager: InstaCacheManager(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
