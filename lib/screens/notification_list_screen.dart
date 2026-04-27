import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: const Text(
          "Notifications",
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
      body: StreamBuilder(
        stream: AppFirestore.collection('members')
            .doc(uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            ));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications"));
          }

          final docs = snapshot.data!.docs;

          if (!snapshot.hasData || docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return NotificationTile(
                snap: docs[index].data(),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> snap;

  const NotificationTile({super.key, required this.snap});

  String timeAgo(Timestamp timestamp) {
    final diff = DateTime.now().difference(timestamp.toDate());

    if (diff.inSeconds < 60) return "${diff.inSeconds}s";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return "${(diff.inDays / 7).floor()}w";
  }

  @override
  Widget build(BuildContext context) {
    final type = snap['type'];
    final createdAt = snap['createdAt'];

    Widget avatarWidget() {
      /// COMMENTS → single actor
      if (type == 'comment') {
        final actor = snap['actorData'];

        return actor == null ||
                actor['photoUrl'] == null ||
                actor['photoUrl'].isEmpty
            ? CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                backgroundColor: const Color.fromARGB(255, 24, 24, 24),
              )
            : ProgressImageDots(
                url: actor['photoUrl'],
                radius: 20,
              );
      }

      /// LIKES → multiple actors
      final List actors = snap['actorPreview'] ?? [];

      if (actors.length == 1) {
        final actor = actors[0];
        return actor == null ||
                actor['photoUrl'] == null ||
                actor['photoUrl'].isEmpty
            ? CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                backgroundColor: const Color.fromARGB(255, 24, 24, 24),
              )
            : ProgressImageDots(
                url: actor['photoUrl'],
                radius: 20,
              );
      }

      /// stacked avatars
      return SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            Positioned(
                left: 0,
                child: actors[0] == null ||
                        actors[0]['photoUrl'] == null ||
                        actors[0]['photoUrl'].isEmpty
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            AssetImage('assets/images/placeholder.jpg'),
                        backgroundColor: const Color.fromARGB(255, 24, 24, 24),
                      )
                    : ProgressImageDots(
                        url: actors[0]['photoUrl'],
                        radius: 20,
                      )),
            if (actors.length > 1)
              Positioned(
                right: 0,
                child: actors[1] == null ||
                        actors[1]['photoUrl'] == null ||
                        actors[1]['photoUrl'].isEmpty
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage:
                            AssetImage('assets/images/placeholder.jpg'),
                        backgroundColor: const Color.fromARGB(255, 24, 24, 24),
                      )
                    : ProgressImageDots(
                        url: actors[1]['photoUrl'],
                        radius: 14,
                      ),
              ),
          ],
        ),
      );
    }

    String messageText() {
      final target = snap['targetType'];
      if (type == 'comment') {
        final username = snap['actorData']['username'];
        final text = snap['previewText'] ?? "";

        // STRIP OFF LAST LETTER
        return "$username commented on your ${(target as String).replaceRange(target.length - 1, target.length, '')}: $text";
      }

      final List actors = snap['actorPreview'] ?? [];
      final count = snap['count'] ?? 1;

      final username = actors.first['username'];

      if (count == 1) {
        return "$username liked your ${(target as String).replaceRange(target.length - 1, target.length, '')}";
      }

      return "$username and ${count - 1} others liked your ${(target as String).replaceRange(target.length - 1, target.length, '')}";
    }

    return InkWell(
      onTap: () {
        /// open post/reel
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            avatarWidget(),

            const SizedBox(width: 12),

            /// TEXT AREA
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    TextSpan(text: messageText()),
                    const TextSpan(text: "  "),
                    TextSpan(
                      text: createdAt != null ? timeAgo(createdAt) : "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            /// POST / REEL PREVIEW
            if (snap['targetPreviewUrl'] != null &&
                snap['targetPreviewUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: snap['targetPreviewUrl'],
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
