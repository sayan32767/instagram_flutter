import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/widgets/comment_card.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:provider/provider.dart';

class CommentsScreen extends StatefulWidget {
  final snap;
  final String collectionName;

  const CommentsScreen({
    super.key,
    required this.snap,
    this.collectionName = 'posts',
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<DocumentSnapshot> _comments = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 20;

  String get _docId => widget.collectionName == 'posts'
      ? widget.snap['postId']
      : widget.snap['reelId'];

  // 🔹 Initial load
  Future<void> _loadInitialComments() async {
    final snap = await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(_docId)
        .collection('comments')
        .orderBy('datePublished', descending: true)
        .limit(_limit)
        .get();

    _comments.clear();
    _comments.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    _isLoading = false;
    if (mounted) setState(() {});
  }

  // 🔹 Fetch more
  Future<void> _fetchMoreComments() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    final snap = await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(_docId)
        .collection('comments')
        .orderBy('datePublished', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _comments.addAll(snap.docs);
    }

    _isFetchingMore = false;
    if (mounted) setState(() {});
  }

  // 🔹 Post comment
  Future<void> _postComment(User user) async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text.trim();
    controller.clear();

    await FirestoreMethods().postComment(
      widget.collectionName,
      _docId,
      text,
      user.uid,
      user.username,
      user.photoUrl ?? "",
    );

    // 🔥 Add instantly to UI (Instagram behavior)
    final newCommentSnap = await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(_docId)
        .collection('comments')
        .orderBy('datePublished', descending: true)
        .limit(1)
        .get();

    if (newCommentSnap.docs.isNotEmpty) {
      _comments.insert(0, newCommentSnap.docs.first);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _loadInitialComments();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 250) {
        _fetchMoreComments();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Comments",
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

      // 🔹 COMMENTS LIST
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.white70,
            ))
          : _comments.isEmpty
              ? const Center(child: Text("No comments yet"))
              : Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        return CommentCard(
                          snap: _comments[index].data(),
                        );
                      },
                    ),
                    if (_isFetchingMore)
                      const Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Colors.white70,
                        )),
                      ),
                  ],
                ),

      // 🔹 INPUT BAR
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              user.photoUrl == null
                  ? CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          const AssetImage('assets/images/placeholder.jpg'),
                      backgroundColor: Colors.grey[300],
                    )
                  : ProgressImageDots(url: user.photoUrl!),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Comment as ${user.username}',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _postComment(user),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Post',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
