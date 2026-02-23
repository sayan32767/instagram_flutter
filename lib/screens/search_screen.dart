import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/profile_posts_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/screens/search_users_list.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/loading_builder_images.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Future? posts;

  getPosts() {
    posts = AppFirestore.posts().get();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: null,
          toolbarHeight: 60,
          backgroundColor: mobileBackgroundColor,
          title: Row(
            children: [
              /// TEXT FIELD — takes remaining space
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchUsersList(),
                    ),
                  );
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800], // default dark bg
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.magnifyingGlass(
                            PhosphorIconsStyle.regular),
                        size: 22,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Search for a user...",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
        body: const SearchScreenGrid(),
      ),
    );
  }
}

class SearchScreenGrid extends StatefulWidget {
  const SearchScreenGrid({super.key});

  @override
  State<SearchScreenGrid> createState() => _SearchScreenGridState();
}

class _SearchScreenGridState extends State<SearchScreenGrid> {
  final ScrollController _scrollController = ScrollController();

  final List<DocumentSnapshot> _posts = [];

  bool _isLoading = true;
  bool _showPaginationLoader = false;
  bool _isFetchingMore = false;
  Timer? _paginationTimer;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  // Refresh
  Future<void> _refresh() async {
    _posts.clear();
    _lastDoc = null;
    _hasMore = true;
    _isLoading = true;

    setState(() {}); // simulate network delay

    final snap = await AppFirestore.posts()
        .orderBy('datePublished', descending: true)
        .limit(_limit)
        .get();

    _posts.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔹 Load first posts
  Future<void> _loadInitial() async {
    final snap = await AppFirestore.posts()
        .orderBy('datePublished', descending: true)
        .limit(_limit)
        .get();

    _posts.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // 🔹 Fetch more on scroll
  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    // 🔥 Start delayed loader timer
    _paginationTimer?.cancel();
    _paginationTimer = Timer(const Duration(milliseconds: 250), () {
      if (_isFetchingMore && mounted) {
        setState(() {
          _showPaginationLoader = true;
        });
      }
    });

    final snap = await AppFirestore.posts()
        .orderBy('datePublished', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _posts.addAll(snap.docs);
    }

    _isFetchingMore = false;

    _paginationTimer?.cancel();

    if (mounted) {
      setState(() {
        _showPaginationLoader = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _loadInitial();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 400) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Initial loader
    if (_isLoading) {
      return const _MasonryGridSkeleton();
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.grey.shade900,
          onRefresh: _refresh,
          child: MasonryGridView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final data = _posts[index].data() as Map<String, dynamic>;
              final url = data['postUrl'];
              final uid = data['uid'];

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 350 + (index % 10) * 40),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Transform.scale(
                        scale: 0.95 + (0.05 * value),
                        child: child,
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreenPosts(
                          postId: _posts[index].id,
                          uid: uid,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomImageLoader(imageUrl: url),
                      )),
                ),
              );
            },
          ),
        ),

        if (_posts.isEmpty)
          Center(
            child: Text(
              "No posts found",
              style: TextStyle(color: Colors.white),
            ),
          ),

        // 🔹 Smooth floating loader
        /// 🔥 WHATSAPP STYLE TOP LOADER
        if (_showPaginationLoader)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(221, 63, 63, 63).withOpacity(0.6),
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
      ],
    );
  }
}

class _MasonryGridSkeleton extends StatelessWidget {
  const _MasonryGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1, // 🔥 Perfect square
      ),
      itemCount: 18,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(0),
          ),
        );
      },
    );
  }
}
