import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  getPosts() {
    posts = FirebaseFirestore.instance.collection('posts').get();
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
                    if (s.isEmpty) {
                      setState(() {
                        isShowUsers = false;
                        _query = '';
                      });
                    } else {
                      setState(() {
                        isShowUsers = true;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(width: 8), // ⭐ spacing

              /// BUTTON — natural width (NO Expanded)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
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
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  // 🔹 Load first posts
  Future<void> _loadInitial() async {
    final snap = await FirebaseFirestore.instance
        .collection('posts')
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

    final snap = await FirebaseFirestore.instance
        .collection('posts')
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
    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _posts.addAll(snap.docs);

      if (mounted) setState(() {});
    } else {
      _hasMore = false;
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
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white70,
      ));
    }

    return Stack(
      children: [
        MasonryGridView.builder(
          controller: _scrollController,
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

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreenPosts(uid: uid, postId: _posts[index].id),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomImageLoader(imageUrl: url),
              ),
            );
          },
        ),

        // 🔹 Smooth floating loader
        if (_isFetchingMore)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            )),
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

    Query query = FirebaseFirestore.instance
        .collection('user')
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

    _isFetchingMore = true;

    Query query = FirebaseFirestore.instance
        .collection('user')
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12, 0, 12),
          child: Text("Recent Searches"),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .doc(currentUid)
                .collection('search_history')
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white70));
              }

              final historyDocs = snapshot.data!.docs;

              if (historyDocs.isEmpty) {
                return const Center(child: Text("No recent searches"));
              }

              return ListView.builder(
                itemCount: historyDocs.length,
                itemBuilder: (context, index) {
                  final searchedUid = historyDocs[index]['uid'];
                  return _buildHistoryUserTile(currentUid, searchedUid);
                },
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
      future:
          FirebaseFirestore.instance.collection('user').doc(searchedUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            backgroundImage: userData['photoUrl'] != null &&
                    userData['photoUrl'].toString().isNotEmpty
                ? CachedNetworkImageProvider(
                    userData['photoUrl'],
                    cacheManager: InstaCacheManager(),
                  )
                : const AssetImage('assets/images/placeholder.jpg')
                    as ImageProvider,
          ),
          title: Text(userData['username']),
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
    await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUid)
        .collection('search_history')
        .doc(searchedUid)
        .delete();
  }

  Future<void> _addToSearchHistory(String searchedUid) async {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;

    await FirebaseFirestore.instance
        .collection('user')
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
                  final data = _users[index].data() as Map<String, dynamic>;

                  return ListTile(
                    leading: data['photoUrl'] == null
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
                        const SizedBox(width: 5),
                        if (data['userType'] == 'ADMIN')
                          SizedBox(
                            height: 20,
                            child: Image.asset(
                                'assets/images/verification_badge.png'),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await _addToSearchHistory(data['uid']);
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: data['uid']),
                        ),
                      );
                    },
                  );
                },
              ),
              if (_isFetchingMore)
                const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
