import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/screens/chat_screen.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  final ScrollController _scrollController = ScrollController();

  /// 🔥 chats data
  final List<DocumentSnapshot> _chats = [];

  /// 🔥 realtime user cache
  final Map<String, Map<String, dynamic>> _usersMap = {};

  /// 🔥 realtime subscription (TOP chats only)
  StreamSubscription<QuerySnapshot>? _topChatsSub;

  // TIMER TO REFRESH ONLINE STATUS EVERY 30 SECONDS
  Timer? _activeRefreshTimer;

  bool _isInitialLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _listenTopChatsRealtime();

    _activeRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMoreChats();
      }
    });
  }

  // ================= REALTIME TOP CHATS =================
  void _listenTopChatsRealtime() {
    _topChatsSub = AppFirestore.chats()
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .limit(_limit)
        .snapshots()
        .listen((snap) {
      _chats
        ..clear()
        ..addAll(snap.docs);

      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
      }

      _listenUsersRealtime();
      _isInitialLoading = false;

      if (mounted) setState(() {});
    });
  }

  // REFRESH (PULL TO REFRESH)
  Future<void> _refresh() async {
    _hasMore = true;
    _lastDoc = null;

    // Force rebuild loader briefly (optional)
    setState(() {
      _isInitialLoading = true;
    });

    // Listener will automatically reload
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isInitialLoading = false;
    });
  }

  // ================= PAGINATION (OLDER CHATS) =================
  Future<void> _fetchMoreChats() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;
    setState(() {});

    final snap = await AppFirestore.chats()
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _chats.addAll(snap.docs);
      _listenUsersRealtime();
    }

    _isFetchingMore = false;
    if (mounted) setState(() {});
  }

  // ================= BATCH REALTIME USER LISTENERS =================
  void _listenUsersRealtime() {
    final userIds = _chats
        .map((chat) {
          final data = chat.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);
          return participants.firstWhere((id) => id != uid, orElse: () => uid);
        })
        .toSet()
        .toList();

    /// Firestore whereIn limit = 10
    for (int i = 0; i < userIds.length; i += 10) {
      final chunk = userIds.sublist(
        i,
        i + 10 > userIds.length ? userIds.length : i + 10,
      );

      FirebaseFirestore.instance
          .collection('user')
          .where(FieldPath.documentId, whereIn: chunk)
          .snapshots()
          .listen((snap) {
        for (final doc in snap.docs) {
          _usersMap[doc.id] = doc.data();
        }
        if (mounted) setState(() {});
      });
    }
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _topChatsSub?.cancel();
    _activeRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    // if (_isInitialLoading) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    // if (_chats.isEmpty) {
    //   return const Scaffold(
    //     body: Center(child: Text("No chats yet")),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Chats", style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _isInitialLoading
          // ? const Center(
          //     child: CircularProgressIndicator(
          //     color: Colors.white70,
          //   ))

          ? const SizedBox.shrink()
          : _chats.isEmpty
              ? const Center(child: Text("No chats yet"))
              : Stack(
                  children: [
                    RefreshIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.grey.shade900,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          final data = chat.data() as Map<String, dynamic>;

                          final participants =
                              List<String>.from(data['participants'] ?? []);
                          final otherUid = participants
                              .firstWhere((id) => id != uid, orElse: () => uid);

                          final user = _usersMap[otherUid] ?? {};

                          final unread = (data['unreadCount_$uid'] ?? 0) > 0;
                          final isMe = data['lastSender'] == uid;

                          // ---------- ONLINE ----------
                          bool otherOnline = false;
                          final Timestamp? lastActive = user['lastActive'];

                          if (lastActive != null) {
                            final diff =
                                DateTime.now().difference(lastActive.toDate());
                            otherOnline = diff.inMinutes < 2;
                          }

                          // ---------- TYPING ----------
                          final typingMap = data['typing'] ?? {};
                          final otherTyping = typingMap[otherUid] == true;

                          // ---------- SUBTITLE ----------
                          String subtitle;

                          if (otherTyping) {
                            subtitle = "typing...";
                          } else if (unread &&
                              data['lastMessage'] != null &&
                              data['lastMessageType'] == 'text') {
                            subtitle = data['lastMessage'];
                          } else if (unread &&
                              data['lastMessageType'] != 'text') {
                            final type = data['lastMessageType'] ?? 'post';
                            final owner =
                                data['mediaOwnerUsername'] ?? "someone";
                            subtitle = "Sent a $type by $owner";
                          } else if (otherOnline) {
                            subtitle = "Active Now";
                          } else if (data['lastMessageType'] == 'text' &&
                              data['lastMessage'] != null) {
                            subtitle = data['lastMessage'];
                          } else {
                            final type = data['lastMessageType'] ?? 'post';
                            final owner =
                                data['mediaOwnerUsername'] ?? "someone";
                            subtitle = isMe
                                ? "You sent a $type by $owner"
                                : "Sent a $type by $owner";
                          }

                          return TweenAnimationBuilder<double>(
                            key: ValueKey(chat.id),
                            tween: Tween(begin: 0, end: 1),
                            duration:
                                Duration(milliseconds: 350 + (index % 10) * 40),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user['photoUrl'] != null
                                    ? CachedNetworkImageProvider(
                                        user['photoUrl'],
                                        cacheManager: InstaCacheManager(),
                                      )
                                    : const AssetImage(
                                            'assets/images/placeholder.jpg')
                                        as ImageProvider,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user['username'] ?? "User",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  if ((user['userType'] ?? '') == 'ADMIN')
                                    SizedBox(
                                      height: 14,
                                      child: Image.asset(
                                          'assets/images/verification_badge.png'),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: unread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: unread
                                      ? Colors.white
                                      : subtitle == 'typing...' ||
                                              subtitle == 'Active Now'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                  // fontStyle: subtitle == "typing..."
                                  //     ? FontStyle.italic
                                  //     : null,
                                ),
                              ),
                              trailing: unread
                                  ? CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        (data['unreadCount_$uid']).toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                        milliseconds: 200), // ⭐ Android default
                                    reverseTransitionDuration:
                                        const Duration(milliseconds: 200),
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        ChatScreen(
                                      chatId: chat.id,
                                      otherUid: otherUid,
                                    ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      final tween = Tween(
                                        begin: const Offset(
                                            1.0, 0.0), // from right
                                        end: Offset.zero,
                                      ).chain(
                                        CurveTween(
                                            curve: Curves
                                                .fastOutSlowIn), // ⭐ Material default curve
                                      );

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    /// bottom loader (pagination)
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
    );
  }
}
