import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/widgets/post_card.dart';
import 'package:instagram_flutter/utils/colors.dart';

class ProfileScreenPosts extends StatefulWidget {
  final String postId;
  final String uid;
  const ProfileScreenPosts({
    super.key,
    required this.postId,
    required this.uid,
  });

  @override
  State<ProfileScreenPosts> createState() => ProfileScreenPostsState();
}

class ProfileScreenPostsState extends State<ProfileScreenPosts> {
  Post? post;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Posts",
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
        body: FutureBuilder<DocumentSnapshot>(
          future: AppFirestore.posts().doc(widget.postId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SinglePostSkeleton();
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  "Post not found",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final post = Post.fromSnap(snapshot.data!);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: PostCard(
                key: ValueKey(post.postId),
                post: post,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SinglePostSkeleton extends StatelessWidget {
  const _SinglePostSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF181818),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // 🔹 Image Placeholder
          Container(
            height: 350,
            width: double.infinity,
            color: const Color(0xFF181818),
          ),

          const SizedBox(height: 12),

          // 🔹 Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 Caption Lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
