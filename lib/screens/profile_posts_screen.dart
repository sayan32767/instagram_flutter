import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/widgets/post_card.dart';
import 'package:instagram_flutter/utils/colors.dart';

class ProfileScreenPosts extends StatefulWidget {
  final String uid;
  final String postId;

  const ProfileScreenPosts({
    super.key,
    required this.uid,
    required this.postId,
  });

  @override
  State<ProfileScreenPosts> createState() => _ProfileScreenPostsState();
}

class _ProfileScreenPostsState extends State<ProfileScreenPosts> {
  final PageController _pageController = PageController();

  final List<DocumentSnapshot> _posts = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;
  int _currentIndex = 0;

  static const int _limit = 10;

  // ---------------- INITIAL LOAD ----------------
  Future<void> _loadInitialPosts() async {
    /// 1️⃣ get the selected post
    final selectedDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();

    if (!selectedDoc.exists) {
      _isLoading = false;
      setState(() {});
      return;
    }

    _posts.add(selectedDoc);

    /// 2️⃣ load next posts of same user
    final snap = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .startAfter([selectedDoc['datePublished']])
        .limit(_limit)
        .get();

    _posts.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  // ---------------- PAGINATION ----------------
  Future<void> _fetchMorePosts() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    final snap = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
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
    if (mounted) setState(() {});
  }

  // ---------------- PAGE CHANGE ----------------
  void _onPageChanged(int index) {
    _currentIndex = index;

    /// when near end → fetch more
    if (index >= _posts.length - 2) {
      _fetchMorePosts();
    }
  }

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
  }

  // ---------------- DISPOSE ----------------
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.white70,
              ))
            : _posts.isEmpty
                ? const Center(child: Text("Post not found"))
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          return PostCard(
                            snap: _posts[index].data() as Map<String, dynamic>,
                          );
                        },
                      ),

                      /// bottom loader while fetching more
                      if (_isFetchingMore)
                        const Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
