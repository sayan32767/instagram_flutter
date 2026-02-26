import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/chat_screen.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PeopleAddScreen extends StatefulWidget {
  const PeopleAddScreen({super.key});

  @override
  State<PeopleAddScreen> createState() => _PeopleAddScreenState();
}

class _PeopleAddScreenState extends State<PeopleAddScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  final List<DocumentSnapshot> _users = [];

  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 20;

  String _currentQuery = '';

  @override
  void initState() {
    super.initState();

    _fetchInitialUsers(); // 🔥 Load all users initially

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 300) {
        _fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ---------------- FETCH INITIAL ----------------
  Future<void> _fetchInitialUsers() async {
    setState(() {
      _isLoading = true;
      _users.clear();
      _lastDoc = null;
      _hasMore = true;
    });

    Query query =
        AppFirestore.collection('members').orderBy('username').limit(_limit);

    if (_currentQuery.isNotEmpty) {
      query = AppFirestore.collection('members').orderBy('username').startAt(
          [_currentQuery]).endAt([_currentQuery + '\uf8ff']).limit(_limit);
    }

    final snap = await query.get();

    if (!mounted) return;

    _users.addAll(snap.docs);
    _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    _hasMore = snap.docs.length == _limit;

    setState(() {
      _isLoading = false;
    });
  }

  // ---------------- FETCH MORE ----------------
  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isFetchingMore = true);

    Query query = AppFirestore.collection('members')
        .orderBy('username')
        .startAfterDocument(_lastDoc!)
        .limit(_limit);

    if (_currentQuery.isNotEmpty) {
      query = AppFirestore.collection('members')
          .orderBy('username')
          .startAt([_currentQuery])
          .endAt([_currentQuery + '\uf8ff'])
          .startAfterDocument(_lastDoc!)
          .limit(_limit);
    }

    final snap = await query.get();

    if (!mounted) return;

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _users.addAll(snap.docs);
    }

    setState(() => _isFetchingMore = false);
  }

  // ---------------- SEARCH ----------------
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      final newQuery = value.trim();

      if (newQuery == _currentQuery) return;

      _currentQuery = newQuery;
      _fetchInitialUsers();
    });
  }

  Widget _buildResults() {
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
              child: Text('Showing results for "${_controller.text}"'),
            ),
          _controller.text.isEmpty
              ? const SizedBox(height: 8)
              : const SizedBox.shrink(),
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
                            ? const CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor: Colors.grey,
                              )
                            : ProgressImageDots(url: data['photoUrl']),
                        title: Text(data['username']),
                        onTap: () async {
                          final receiverUid = id;

                          // 🔹 Get or create chatId
                          final chatId = await FirestoreMethods()
                              .getOrCreateChat(receiverUid);

                          // 🔹 Optionally send first message
                          // await FirestoreMethods().sendMessage(
                          //   receiverId: receiverUid,
                          //   mediaOwnerUsername: null,
                          //   mediaOwnerId: null,
                          //   type: 'text',
                          //   text: "Hi there! 👋",
                          // );

                          if (!mounted) return;

                          // 🔹 Navigate to chat screen
                          Navigator.of(context, rootNavigator: true).push(
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 200),
                              reverseTransitionDuration:
                                  const Duration(milliseconds: 200),
                              pageBuilder: (_, animation, secondaryAnimation) =>
                                  ChatScreen(
                                chatId: chatId,
                                otherUid: receiverUid,
                              ),
                              transitionsBuilder:
                                  (_, animation, secondaryAnimation, child) {
                                final tween = Tween(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).chain(
                                  CurveTween(curve: Curves.fastOutSlowIn),
                                );

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        });
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          title: MyTextformfield(
            leading: PhosphorIcon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
              size: 22,
              color: Colors.white70,
            ),
            controller: _controller,
            onChanged: _onSearchChanged,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
            ],
            hintText: "Search for a user...",
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : _users.isEmpty
                ? const Center(
                    child: Text("No users found"),
                  )
                : _buildResults(),
      ),
    );
  }
}
