import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/widgets/chat_bubble.dart';
import 'package:instagram_flutter/widgets/typing_bubble.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUid;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final uid = FirebaseAuth.instance.currentUser!.uid;

  final List<DocumentSnapshot> _messages = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 20;

  Timer? _typingTimer;
  bool _typingSent = false;

  StreamSubscription? _newMsgSub;

  bool _otherTyping = false;

  StreamSubscription? _typingSub;

  void _initTypingListener() {
    _typingSub =
        AppFirestore.chats().doc(widget.chatId).snapshots().listen((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;

      final typing = data['typing'] ?? {};
      final typingNow = typing[widget.otherUid] == true;

      if (_otherTyping != typingNow) {
        setState(() {
          _otherTyping = typingNow;
        });
      }
    });
  }

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _markAsRead();
    _loadLatestMessages().then((_) => _listenForNewMessages());
    // ⭐ ADD THIS

    _initTypingListener();

    _scrollController.addListener(_handleScroll);
  }

  // ================= NEW MESSAGES LISTENER =================
  void _listenForNewMessages() {
    _newMsgSub = AppFirestore.chats()
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1) // ⭐ only newest message
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final newDoc = snapshot.docs.first;

      // check if already exists
      final alreadyLoaded = _messages.any((doc) => doc.id == newDoc.id);

      if (!alreadyLoaded) {
        _markAsRead().then((_) {
          setState(() {
            _messages.insert(0, newDoc);
          });
        });

        _scrollToBottom();
      }
    });
  }

  // ================= MARK READ =================
  Future<void> _markAsRead() async {
    AppFirestore.chats().doc(widget.chatId).update({'unreadCount_$uid': 0});
  }

  // ================= LOAD LATEST =================
  Future<void> _loadLatestMessages() async {
    final snap = await AppFirestore.chats()
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true) // ⭐ IMPORTANT
        .limit(_limit)
        .get();

    _messages.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    setState(() => _isLoading = false);

    /// jump to bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // ================= PAGINATION (OLDER) =================
  Future<void> _fetchOlderMessages() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isFetchingMore = true);

    await Future.delayed(
        const Duration(milliseconds: 10)); // simulate loading time

    final snap = await AppFirestore.chats()
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _messages.addAll(snap.docs);
    }

    if (mounted) {
      setState(() => _isFetchingMore = false);
    }
  }

  // ================= SCROLL HANDLER =================
  void _handleScroll() {
    if (_scrollController.position.atEdge) {
      bool isTop = _scrollController.position.pixels != 0;

      if (isTop) {
        _fetchOlderMessages();
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  // ================= TYPING =================
  void _onTypingChanged(String text) {
    if (!_typingSent) {
      AppFirestore.chats().doc(widget.chatId).update({'typing.$uid': true});

      _typingSent = true;
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      AppFirestore.chats().doc(widget.chatId).update({'typing.$uid': false});

      _typingSent = false;
    });
  }

  // ================= SEND TEXT =================
  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact(); // subtle tap feel

    await FirestoreMethods().sendMessage(
      mediaOwnerId: null,
      mediaOwnerUsername: null,
      receiverId: widget.otherUid,
      type: 'text',
      text: text,
    );

    _controller.clear();
    await Future.delayed(const Duration(milliseconds: 50));
    _scrollToBottom();
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    AppFirestore.chats().doc(widget.chatId).update({'typing.$uid': false});

    _typingTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    _newMsgSub?.cancel(); // ⭐ IMPORTANT
    _typingSub?.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0, // 🔥 IMPORTANT
        surfaceTintColor: Colors.transparent, // 🔥 VERY IMPORTANT
        backgroundColor: Colors.black,
        title: _ChatHeader(
            otherUid: widget.otherUid,
            chatId: widget.chatId,
            isTyping: _otherTyping),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.white70,
            ))
          : Column(
              children: [
                // ================= MESSAGES =================
                Expanded(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg =
                              _messages[index].data() as Map<String, dynamic>;

                          final isMe = msg['senderId'] == uid;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: MessageBubble(msg: msg, isMe: isMe),
                          );
                        },
                      ),

                      /// 🔥 WHATSAPP STYLE TOP LOADER
                      if (_isFetchingMore)
                        Positioned(
                          top: 12,
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

                if (_otherTyping && widget.otherUid != currentUid)
                  TypingBubble(isMe: false),

                // ================= INPUT =================
                _ChatInput(
                  controller: _controller,
                  onTyping: _onTypingChanged,
                  onSend: _sendText,
                ),
              ],
            ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String otherUid;
  final String chatId;
  final bool isTyping;

  const _ChatHeader({
    required this.otherUid,
    required this.chatId,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProfileScreen(uid: otherUid))),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(otherUid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const SizedBox();

          final user = userSnap.data!.data() as Map<String, dynamic>? ?? {};

          final photoUrl = user['photoUrl'];
          final username = user['username'] ?? "User";
          final Timestamp? lastActive = user['lastActive'];

          bool online = false;
          if (lastActive != null) {
            final diff = DateTime.now().difference(lastActive.toDate());
            online = diff.inMinutes < 2;
          }

          final otherTyping = isTyping;

          String subtitle = "";

          if (otherTyping && otherUid != currentUid) {
            subtitle = "typing...";
          } else if (online) {
            subtitle = "Active Now";
          } else if (lastActive != null) {
            final diff = DateTime.now().difference(lastActive.toDate());

            if (diff.inMinutes < 60) {
              subtitle = "Last seen ${diff.inMinutes}m ago";
            } else if (diff.inHours < 24) {
              subtitle = "Last seen ${diff.inHours}h ago";
            } else {
              subtitle = "Last seen ${diff.inDays}d ago";
            }
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(
                        photoUrl,
                        cacheManager: InstaCacheManager(),
                      )
                    : const AssetImage('assets/images/placeholder.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: subtitle != 'typing...'
                              ? Colors.white70
                              : Colors.white),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onTyping;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.onTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          /// TEXT FIELD
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: controller,
                onChanged: onTyping,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          /// SEND BUTTON
          GestureDetector(
            onTap: () {
              onSend();
            },
            child: Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF833AB4),
                    Color(0xFFE1306C),
                    Color(0xFFF77737),
                  ],
                ),
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
