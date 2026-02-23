import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/core/navigation_keys.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/group_chooser_screen.dart';
import 'package:instagram_flutter/screens/inbox_screen.dart';
import 'package:instagram_flutter/screens/story_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/post_card.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/widgets/story_card.dart';
import 'package:instagram_flutter/widgets/story_list_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => FeedScreenState();
}

class FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin {
  // QuerySnapshot? usersSnapshot;

  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? groupData;

  final List<DocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDoc;

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  static const int _limit = 5;

  final ScrollController _scrollController = ScrollController();

  bool get isAtTop =>
      !_scrollController.hasClients || _scrollController.offset <= 0;

  Future<void> scrollToTop() async {
    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ---------- FETCH USERS ----------
  // Future<void> _fetchUserData() async {
  //   final snap = await FirebaseFirestore.instance.collection('user').get();

  //   if (!mounted) return;

  //   setState(() {
  //     usersSnapshot = snap;
  //   });
  // }

  // ---------- FETCH GROUPS ----------
  Future<void> _fetchGroupData() async {
    final snap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(AppFirestore.currentGroupId)
        .get();

    if (!mounted) return;

    setState(() {
      groupData = snap.data();
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

    await _fetchGroupData();

    // await Future.delayed(const Duration(milliseconds: 300));
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
    // _fetchUserData();
    _fetchGroupData();
    _loadInitialPosts();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: RefreshIndicator(
          color: Colors.white70,
          onRefresh: _refreshPosts,
          child: CustomScrollView(
            controller: _scrollController,
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
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: GestureDetector(
                          child: PhosphorIcon(
                            PhosphorIcons.plus(PhosphorIconsStyle.bold),
                            color: Colors.white,
                            size: 22,
                          ),
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        AddPostScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = Offset(-1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInToLinear;

                                  var tween = Tween(begin: begin, end: end)
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
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SvgPicture.asset(
                          'assets/images/ic_instagram.svg',
                          color: primaryColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: GestureDetector(
                          child: PhosphorIcon(
                            PhosphorIcons.users(PhosphorIconsStyle.regular),
                            color: Colors.white,
                            size: 22,
                          ),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    const GroupChooserScreen()));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- ANNOUNCEMENTS ----------
              // SliverToBoxAdapter(
              //   child: TweenAnimationBuilder<double>(
              //     tween: Tween(begin: 0, end: 1),
              //     duration: const Duration(milliseconds: 600),
              //     curve: Curves.easeOutCubic,
              //     builder: (context, value, child) {
              //       return Opacity(
              //         opacity: value,
              //         child: Transform.translate(
              //           offset: Offset(0, 30 * (1 - value)),
              //           child: child,
              //         ),
              //       );
              //     },
              //     child: _buildAnnouncements(),
              //   ),
              // ),

              // ---------- STORIES ----------
              SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 25 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: const StoryListWidgets(),
                ),
              ),

              // ---------- POSTS ----------
              !_isLoading && _posts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        alignment: Alignment.center,
                        child: const Text(
                          "No posts yet",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // trigger pagination
                          if (index >= _posts.length - 2) {
                            _loadMorePosts();
                          }

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: PostCard(
                                // snap:
                                //     _posts[index].data() as Map<String, dynamic>,
                                post: Post.fromSnap(_posts[index])),
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
  // Widget _buildAnnouncements() {
  //   if (groupData == null) return const SizedBox.shrink();

  //   final announcements = <String>[];

  //   if (groupData!['announcement_text'] != null &&
  //       groupData!['announcement_text'].toString().trim().isNotEmpty) {
  //     announcements.add(groupData!['announcement_text']);
  //   }

  //   if (announcements.isEmpty) return const SizedBox.shrink();

  //   return Container(
  //     padding: const EdgeInsets.fromLTRB(16, 10, 10, 12),
  //     color: Colors.grey[900],
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: announcements
  //           .map((e) => Text(e, style: const TextStyle(fontSize: 14)))
  //           .toList(),
  //     ),
  //   );
  // }
}
