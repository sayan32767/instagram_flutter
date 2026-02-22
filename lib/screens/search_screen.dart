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
import 'package:instagram_flutter/utils/colors.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/loading_builder_images.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:provider/provider.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isShowUsers = false;
  Future? posts;

  String _previousQuery = '';

  getPosts() {
    posts = AppFirestore.posts().get();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _query = '';

  @override
  void initState() {
    super.initState();
    getPosts();
    // _controller.addListener(() {
    //   setState(() {
    //     _query = _controller.text.toLowerCase();
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 60,
          backgroundColor: mobileBackgroundColor,
          title: Row(
            children: [
              /// TEXT FIELD — takes remaining space
              Expanded(
                child: MyTextformfield(
                  onFieldSubmitted: (s) {
                    if (s.trim().isNotEmpty) {
                      setState(() {
                        _query = s.toLowerCase();
                        isShowUsers = true;
                      });
                    }
                  },
                  controller: _controller,
                  hintText: 'Search for a user...',
                  onChanged: (s) {
                    if (s == _previousQuery) return;
                    if (s.isEmpty) {
                      setState(() {
                        isShowUsers = false;
                        _query = '';
                      });
                    } else if (s.length == 1 &&
                        s.trim().isNotEmpty &&
                        _previousQuery.isEmpty) {
                      setState(() {
                        isShowUsers = true;
                      });
                    }
                    _previousQuery = s;
                  },
                ),
              ),

              const SizedBox(width: 8), // ⭐ spacing

              /// BUTTON — natural width (NO Expanded)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    setState(() {
                      _query = _controller.text.toLowerCase();
                      isShowUsers = true;
                    });
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        body: isShowUsers
            ? SearchUsersList(query: _query)
            : const SearchScreenGrid(),
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
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
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
                      borderRadius: BorderRadius.circular(3),
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

class SearchUsersList extends StatefulWidget {
  final String query;

  const SearchUsersList({super.key, required this.query});

  @override
  State<SearchUsersList> createState() => _SearchUsersListState();
}

class _SearchUsersListState extends State<SearchUsersList> {
  final ScrollController _scrollController = ScrollController();

  final List<DocumentSnapshot> _users = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 20;

  /// 🔹 Load first users
  Future<void> _loadInitial() async {
    _users.clear();
    _lastDoc = null;
    _hasMore = true;

    /// 🔥 If query empty → stop loading users
    if (widget.query.isEmpty) {
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    // Query query = FirebaseFirestore.instance
    //     .collection('user')
    //     .orderBy('username')
    //     .startAt([widget.query]).endAt([widget.query + '\uf8ff']).limit(_limit);
    Query query = AppFirestore.collection('members')
        .orderBy('username')
        .startAt([widget.query]).endAt([widget.query + '\uf8ff']).limit(_limit);

    final snap = await query.get();

    _users.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  /// 🔹 Fetch more users
  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    setState(() {
      _isFetchingMore = true;
    });

    Query query = AppFirestore.collection('members')
        .orderBy('username')
        .startAt([widget.query])
        .endAt([widget.query + '\uf8ff'])
        .startAfterDocument(_lastDoc!)
        .limit(_limit);

    final snap = await query.get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _users.addAll(snap.docs);
    }

    _isFetchingMore = false;
    if (mounted) setState(() {});
  }

  /// 🔹 SEARCH HISTORY STREAM
  Widget _buildSearchHistory() {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AppFirestore.collection('search_histories')
                .doc(currentUid)
                .collection('search_history')
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Text("No recent searches"));
              }

              final historyDocs = snapshot.data!.docs;

              if (historyDocs.isEmpty) {
                return const Center(child: Text("No recent searches"));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 12, 0, 12),
                    child: Text("Recent searches"),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: historyDocs.length,
                      itemBuilder: (context, index) {
                        final searchedUid = historyDocs[index]['uid'];
                        return _buildHistoryUserTile(currentUid, searchedUid);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 🔹 HISTORY TILE
  Widget _buildHistoryUserTile(String currentUid, String searchedUid) {
    return FutureBuilder<DocumentSnapshot>(
      future: AppFirestore.collection('members').doc(searchedUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor:
                const Color.fromARGB(255, 71, 71, 71), // 👈 white base
            child: ClipOval(
              child: (userData['photoUrl'] != null &&
                      userData['photoUrl'].toString().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: userData['photoUrl'],
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                      placeholder: (context, url) => Container(
                        color: const Color.fromARGB(
                            255, 54, 54, 54), // 👈 white while loading
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/placeholder.jpg',
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : Image.asset(
                      'assets/images/placeholder.jpg',
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                    ),
            ),
          ),
          title: Row(
            children: [
              Flexible(
                  child: Text(userData['username'],
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _removeFromHistory(currentUid, searchedUid),
          ),
          onTap: () async {
            await _addToSearchHistory(searchedUid);
            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(uid: searchedUid),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeFromHistory(String currentUid, String searchedUid) async {
    await AppFirestore.collection('search_histories')
        .doc(currentUid)
        .collection('search_history')
        .doc(searchedUid)
        .delete();
  }

  Future<void> _addToSearchHistory(String searchedUid) async {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;

    await AppFirestore.collection('search_histories')
        .doc(currentUid)
        .collection('search_history')
        .doc(searchedUid)
        .set({
      'uid': searchedUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void initState() {
    super.initState();

    _loadInitial();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMore();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchUsersList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.query != widget.query) {
      _isLoading = true;
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔥 FINAL BUILD
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    /// 🔥 HISTORY FIRST
    if (widget.query.isEmpty) {
      return _buildSearchHistory();
    }

    /// 🔥 NO USERS FOUND
    if (_users.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12, 0, 12),
          child: Text("Showing results for \"${widget.query}\""),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final id = _users[index].id;
                  final data = _users[index].data() as Map<String, dynamic>;

                  return ListTile(
                    leading: data['photoUrl'] == null ||
                            data['photoUrl'].toString().isEmpty
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: const AssetImage(
                                'assets/images/placeholder.jpg'),
                            backgroundColor: Colors.grey[300],
                          )
                        : ProgressImageDots(url: data['photoUrl']),
                    title: Row(
                      children: [
                        Text(data['username']),
                      ],
                    ),
                    onTap: () async {
                      await _addToSearchHistory(id);
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: id),
                        ),
                      );
                    },
                  );
                },
              ),
              if (_isFetchingMore)
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
                        color: const Color.fromARGB(221, 63, 63, 63)
                            .withOpacity(0.6),
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
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1, // 🔥 Perfect square
      ),
      itemCount: 18,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }
}
