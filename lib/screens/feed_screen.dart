import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/inbox_screen.dart';
import 'package:instagram_flutter/screens/story_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/post_card.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/widgets/story_card.dart';
import 'package:instagram_flutter/widgets/story_list_widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen> {
  QuerySnapshot? usersSnapshot;

  final List<DocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDoc;

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  static const int _limit = 5;

  // ---------- FETCH USERS ----------
  Future<void> _fetchUserData() async {
    final snap = await FirebaseFirestore.instance.collection('user').get();

    if (!mounted) return;

    setState(() {
      usersSnapshot = snap;
    });
  }

  Future<void> refresh() async {
    // whatever you use to reload posts
    await _refreshPosts();
  }

  // REFRESH FEED
  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _lastDoc = null;
      _hasMore = true;
      _isLoading = true;
    });

    await _loadInitialPosts();

    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ---------- INITIAL POSTS ----------
  Future<void> _loadInitialPosts() async {
    final snap = await AppFirestore.posts()
        .orderBy('datePublished', descending: true)
        .limit(_limit)
        .get();

    _posts.addAll(snap.docs);

    if (_posts.isNotEmpty) {
      _lastDoc = _posts.last;
    } else {
      _hasMore = false;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ---------- PAGINATION ----------
  Future<void> _loadMorePosts() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

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
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadInitialPosts();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.white70,
              ))
            : _posts.isEmpty
                ? const Center(child: Text("No posts available"))
                : RefreshIndicator(
                    color: Colors.white70,
                    onRefresh: _refreshPosts,
                    child: CustomScrollView(
                      slivers: [
                        // ---------- APP BAR ----------
                        SliverAppBar(
                          automaticallyImplyLeading: false,
                          floating: true,
                          backgroundColor: mobileBackgroundColor,
                          toolbarHeight: 70,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: SvgPicture.asset(
                                    'assets/images/ic_instagram.svg',
                                    color: primaryColor,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 28, color: primaryColor),
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true)
                                        .push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            AddPostScreen(),
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
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ---------- ANNOUNCEMENTS ----------
                        SliverToBoxAdapter(
                          child: _buildAnnouncements(),
                        ),

                        // ---------- STORIES ----------
                        SliverToBoxAdapter(child: const StoryListWidgets()),

                        // ---------- POSTS ----------
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // trigger pagination
                              if (index >= _posts.length - 2) {
                                _loadMorePosts();
                              }

                              return PostCard(
                                snap: _posts[index].data()
                                    as Map<String, dynamic>,
                              );
                            },
                            childCount: _posts.length,
                          ),
                        ),

                        // ---------- BOTTOM LOADER ----------
                        SliverToBoxAdapter(
                          child: _isFetchingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                    color: Colors.white70,
                                  )),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ---------- ANNOUNCEMENT WIDGET ----------
  Widget _buildAnnouncements() {
    if (usersSnapshot == null) return const SizedBox.shrink();

    final announcements = <String>[];

    for (var doc in usersSnapshot!.docs) {
      if ((doc.data() as Map).containsKey('announcement_text')) {
        announcements.add(doc['announcement_text']);
      }
    }

    if (announcements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 12),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: announcements
            .map((e) => Text(e, style: const TextStyle(fontSize: 14)))
            .toList(),
      ),
    );
  }
}
