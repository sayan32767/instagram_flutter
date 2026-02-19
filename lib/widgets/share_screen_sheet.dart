import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.post, required this.type});

  final Map post;
  final String type;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _query = "";

  final List<DocumentSnapshot> _users = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 20;

  // 🔹 INITIAL LOAD + SEARCH
  Future<void> _loadUsers({bool isNewSearch = false}) async {
    if (isNewSearch) {
      _users.clear();
      _lastDoc = null;
      _hasMore = true;
      _isLoading = true;
      setState(() {});
    }

    Query query = FirebaseFirestore.instance
        .collection('user')
        .orderBy('username')
        .limit(_limit);

    if (_query.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collection('user')
          .orderBy('username')
          .startAt([_query]).endAt([_query + '\uf8ff']).limit(_limit);
    }

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

  // 🔹 FETCH MORE USERS (pagination)
  Future<void> _fetchMoreUsers() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    Query query = FirebaseFirestore.instance
        .collection('user')
        .orderBy('username')
        .startAfterDocument(_lastDoc!)
        .limit(_limit);

    if (_query.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collection('user')
          .orderBy('username')
          .startAt([_query])
          .endAt([_query + '\uf8ff'])
          .startAfterDocument(_lastDoc!)
          .limit(_limit);
    }

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

  @override
  void initState() {
    super.initState();

    _loadUsers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMoreUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          /// 🔘 Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          /// 🔍 Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search username...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                _query = val.toLowerCase();
                _loadUsers(isNewSearch: true);
              },
            ),
          ),

          const SizedBox(height: 12),

          /// 👥 PAGINATED USER LIST
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                    color: Colors.white70,
                  ))
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          "No users found",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final data =
                                  _users[index].data() as Map<String, dynamic>;

                              final username = data['username'] ?? '';
                              final photoUrl = data['photoUrl'] ?? '';
                              final userType = data['userType'] ?? '';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: photoUrl
                                          .toString()
                                          .isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          photoUrl,
                                          cacheManager: InstaCacheManager(),
                                        )
                                      : const AssetImage(
                                              'assets/images/placeholder.jpg')
                                          as ImageProvider,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      username,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(width: 5),
                                    if (userType == 'ADMIN')
                                      SizedBox(
                                        height: 20,
                                        child: Image.asset(
                                            'assets/images/verification_badge.png'),
                                      ),
                                  ],
                                ),
                                onTap: () async {
                                  final receiverId = data['uid'];

                                  await FirestoreMethods().sendMessage(
                                    mediaOwnerId: widget.post['uid'],
                                    mediaOwnerUsername: widget.post['username'],
                                    receiverId: receiverId,
                                    type: widget.type,
                                    postId: widget.type == 'post'
                                        ? widget.post['postId']
                                        : null,
                                    reelId: widget.type == 'reel'
                                        ? widget.post['reelId']
                                        : null,
                                  );

                                  if (!mounted) return;

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "${widget.type[0].toUpperCase() + widget.type.substring(1)} sent to $username"),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          /// 🔄 Bottom loader while fetching more
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
                      ),
          ),
        ],
      ),
    );
  }
}
