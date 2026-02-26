import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class SearchUsersList extends StatefulWidget {
  const SearchUsersList({super.key});

  @override
  State<SearchUsersList> createState() => _SearchUsersListState();
}

class _SearchUsersListState extends State<SearchUsersList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  final List<DocumentSnapshot> _users = [];

  Timer? _debounce;

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 20;

  @override
  void initState() {
    super.initState();

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

  // 🔥 SEARCH USERS
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users.clear();
        _lastDoc = null;
        _hasMore = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _users.clear();
      _lastDoc = null;
      _hasMore = true;
    });

    final snap = await AppFirestore.collection('members')
        .orderBy('username')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .limit(_limit)
        .get();

    _users.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 🔥 PAGINATION
  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    setState(() {
      _isFetchingMore = true;
    });

    final snap = await AppFirestore.collection('members')
        .orderBy('username')
        .startAt([_controller.text])
        .endAt([_controller.text + '\uf8ff'])
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _users.addAll(snap.docs);
    }

    setState(() {
      _isFetchingMore = false;
    });
  }

  // 🔥 SEARCH HISTORY
  Widget _buildSearchHistory() {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;

    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
            child: Text('Recent Searches'),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AppFirestore.collection('search_histories')
                  .doc(currentUid)
                  .collection('search_history')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text("No recent searches"));
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No recent searches"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final searchedUid = docs[index]['uid'];
                    return _buildHistoryTile(currentUid, searchedUid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(String currentUid, String searchedUid) {
    return FutureBuilder<DocumentSnapshot>(
      future: AppFirestore.collection('members').doc(searchedUid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final user = snapshot.data!.data() as Map<String, dynamic>;

        return ListTile(
          leading:
              user['photoUrl'] == null || user['photoUrl'].toString().isEmpty
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          const AssetImage('assets/images/placeholder.jpg'),
                      backgroundColor: Colors.grey[300],
                    )
                  : ProgressImageDots(url: user['photoUrl']),
          title: Text(user['username']),
          trailing: GestureDetector(
            child: PhosphorIcon(
              PhosphorIcons.x(PhosphorIconsStyle.regular),
              size: 18,
              color: Colors.white54,
            ),
            onTap: () async {
              await AppFirestore.collection('search_histories')
                  .doc(currentUid)
                  .collection('search_history')
                  .doc(searchedUid)
                  .delete();
            },
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

  Future<void> _addToSearchHistory(String searchedUid) async {
    final currentUid =
        Provider.of<UserProvider>(context, listen: false).getUser!.uid;

    await AppFirestore.collection('search_histories')
        .doc(currentUid)
        .collection('search_history')
        .doc(searchedUid)
        .set({
      'uid': searchedUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
          child: Text('Showing results for "${_controller.text}"'),
        ),
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
                      await _addToSearchHistory(id);
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: id),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
            // autofocus: true,
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              _debounce = Timer(const Duration(milliseconds: 350), () {
                _searchUsers(value.trim());
              });
            },
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
            : _controller.text.isEmpty
                ? _buildSearchHistory()
                : _users.isEmpty
                    ? const Center(child: Text("No users found"))
                    : _buildResults(),
      ),
    );
  }
}
