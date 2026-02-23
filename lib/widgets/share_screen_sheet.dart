import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

  Timer? _debounce;

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

    // await Future.delayed(const Duration(milliseconds: 300));
    // Query query = FirebaseFirestore.instance
    //     .collection('user')
    //     .orderBy('username')
    //     .limit(_limit);

    Query query = AppFirestore.collection('members')
        .orderBy('username')
        .startAt([_query]).endAt([_query + '\uf8ff']).limit(_limit);

    if (_query.isNotEmpty) {
      query = AppFirestore.collection('members')
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

    setState(() {
      _isFetchingMore = true;
    });

    Query query = AppFirestore.collection('members')
        .orderBy('username')
        .startAfterDocument(_lastDoc!)
        .limit(_limit);

    if (_query.isNotEmpty) {
      query = AppFirestore.collection('members')
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
    _debounce?.cancel();
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
                prefixIcon: PhosphorIcon(PhosphorIcons.magnifyingGlass(),
                    color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                _debounce?.cancel();

                _debounce = Timer(const Duration(milliseconds: 400), () {
                  final trimmed = val.trim().toLowerCase();

                  _query = trimmed;

                  if (_query.isNotEmpty) {
                    _loadUsers(isNewSearch: true);
                  } else {
                    _users.clear();
                    _loadUsers().then((_) {
                      if (mounted) setState(() {});
                    });
                  }
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _isLoading
                  ? Container(
                      key: const ValueKey("skeleton"),
                      // height: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(4, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFF181818),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF181818),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    )
                  : Container(
                      key: const ValueKey("content"),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _users.isEmpty
                            ? const Center(
                                key: ValueKey("empty"),
                                child: Text(
                                  "No users found",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : Stack(
                                key: const ValueKey("list"),
                                children: [
                                  ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _users.length,
                                    itemBuilder: (context, index) {
                                      final data = _users[index].data()
                                          as Map<String, dynamic>;

                                      final id = _users[index].id;
                                      final username = data['username'] ?? '';
                                      final photoUrl = data['photoUrl'] ?? '';

                                      return TweenAnimationBuilder<double>(
                                        key: ValueKey(_users[index].id),
                                        tween: Tween(begin: 0, end: 1),
                                        duration: Duration(
                                            milliseconds:
                                                250 + (index % 8) * 25),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset:
                                                  Offset(0, 15 * (1 - value)),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () async {
                                            final receiverId = id;

                                            await FirestoreMethods()
                                                .sendMessage(
                                              mediaOwnerId: widget.post['uid'],
                                              mediaOwnerUsername:
                                                  widget.post['username'],
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

                                            showSnackBar(context,
                                                "${widget.type[0].toUpperCase() + widget.type.substring(1)} sent to $username");
                                          },
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              radius: 18,
                                              backgroundColor:
                                                  Colors.grey.shade800,
                                              backgroundImage: photoUrl
                                                      .toString()
                                                      .isNotEmpty
                                                  ? CachedNetworkImageProvider(
                                                      photoUrl,
                                                      cacheManager:
                                                          InstaCacheManager(),
                                                    )
                                                  : const AssetImage(
                                                          'assets/images/placeholder.jpg')
                                                      as ImageProvider,
                                            ),
                                            title: Row(
                                              children: [
                                                Text(
                                                  username,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  /// 🔄 Bottom loader while fetching more
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
                                            color: const Color.fromARGB(
                                                    221, 63, 63, 63)
                                                .withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(25),
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
                    ),
            ),
          )

          // if (_isLoading)
          //   Container(
          //     key: const ValueKey("skeleton"),
          //     height: 200,
          //     padding: const EdgeInsets.symmetric(horizontal: 16),
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: List.generate(4, (index) {
          //         return Padding(
          //           padding: const EdgeInsets.symmetric(vertical: 8),
          //           child: Row(
          //             children: [
          //               const CircleAvatar(
          //                 radius: 18,
          //                 backgroundColor: Color(0xFF181818),
          //               ),
          //               const SizedBox(width: 12),
          //               Expanded(
          //                 child: Container(
          //                   height: 14,
          //                   decoration: BoxDecoration(
          //                     color: const Color(0xFF181818),
          //                     borderRadius: BorderRadius.circular(6),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         );
          //       }),
          //     ),
          //   )
          // else

          /// 👥 PAGINATED USER LIST
        ],
      ),
    );
  }
}
