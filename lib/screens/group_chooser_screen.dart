// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:instagram_flutter/core/app_firestore.dart';
// import 'package:instagram_flutter/providers/user_provider.dart';
// import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
// import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
// import 'package:instagram_flutter/responsive/web_screen_layout.dart';
// import 'package:instagram_flutter/screens/create_group_screen.dart';
// import 'package:instagram_flutter/screens/edit_profile_screen.dart';
// import 'package:instagram_flutter/screens/join_group_screen.dart';
// import 'package:instagram_flutter/services/group_services.dart';
// import 'package:instagram_flutter/utils/colors.dart';
// import 'package:instagram_flutter/utils/group_storage.dart';
// import 'package:instagram_flutter/utils/utils.dart';
// import 'package:instagram_flutter/widgets/text_field_input.dart';
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
// import 'package:uuid/v1.dart';

// class GroupChooserScreen extends StatefulWidget {
//   const GroupChooserScreen({super.key});

//   @override
//   State<GroupChooserScreen> createState() => _GroupChooserScreenState();
// }

// class _GroupChooserScreenState extends State<GroupChooserScreen> {
//   Future<QuerySnapshot<Map<String, dynamic>>> _fetchUserGroups() async {
//     final uid = FirebaseAuth.instance.currentUser!.uid;

//     return FirebaseFirestore.instance
//         .collection('user')
//         .doc(uid)
//         .collection('groups')
//         .orderBy('joinedAt', descending: true)
//         .get();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         // automaticallyImplyLeading: false,
//         backgroundColor: mobileBackgroundColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         surfaceTintColor: Colors.transparent,
//         title: Padding(
//           padding: const EdgeInsets.only(left: 4),
//           child: const Text(
//             "Your Groups",
//             style: TextStyle(
//                 color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
//           ),
//         ),
//       ),
//       backgroundColor: mobileBackgroundColor,
//       body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         future: _fetchUserGroups(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: Colors.white70),
//             );
//           }

//           if (snapshot.hasError) {
//             return const Center(
//               child: Text(
//                 "Something went wrong",
//                 style: TextStyle(color: Colors.white),
//               ),
//             );
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.groups_outlined,
//                       size: 60,
//                       color: Colors.white24,
//                     ),
//                     const SizedBox(height: 16),

//                     const Text(
//                       "No groups joined yet",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     const Text(
//                       "Create a new group or join an existing one.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: Colors.white54,
//                         fontSize: 14,
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     /// 🔥 CREATE GROUP BUTTON
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: blueColor,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ),
//                         onPressed: () {
//                           // setState(() {
//                           //   _showingGroupLists = false;
//                           //   _showCreateGroup = true;
//                           // });
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const CreateGroupScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           "Create Group",
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 12),

//                     /// 🔥 JOIN GROUP BUTTON
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton(
//                         style: OutlinedButton.styleFrom(
//                           side: const BorderSide(color: Colors.white24),
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         ),
//                         onPressed: () {
//                           // setState(() {
//                           //   _showingGroupLists = false;
//                           //   _showCreateGroup = false;
//                           // });
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => const JoinGroupScreen(),
//                             ),
//                           );
//                         },
//                         child: const Text(
//                           "Join Group",
//                           style: TextStyle(color: Colors.white70),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           final groups = snapshot.data!.docs;

//           return Column(
//             children: [
//               Flexible(
//                 child: ListView.separated(
//                   shrinkWrap: true,
//                   itemCount: groups.length,
//                   separatorBuilder: (_, __) =>
//                       const Divider(color: Colors.white12),
//                   itemBuilder: (context, index) {
//                     final doc = groups[index];
//                     final groupId = doc.id;
//                     final data = doc.data();
//                     final groupName = data['name'] ?? "Unnamed Group";

//                     final currentGroupId = AppFirestore.currentGroupId;

//                     return ListTile(
//                       selected: groupId == currentGroupId,
//                       onTap: () async {
//                         // Switch group
//                         await GroupStorage.save(groupId);
//                         AppFirestore.setGroup(groupId);

//                         if (!context.mounted) return;

//                         Navigator.of(context, rootNavigator: true)
//                             .pushAndRemoveUntil(
//                           MaterialPageRoute(
//                             builder: (_) => const ResponsiveLayout(
//                               webScreenLayout: WebScreenLayout(),
//                               mobileScreenLayout: MobileScreenLayout(),
//                             ),
//                           ),
//                           (route) => false,
//                         );
//                       },
//                       leading: CircleAvatar(
//                           backgroundColor: Colors.white12,
//                           child: PhosphorIcon(PhosphorIcons.users(),
//                               color: Colors.white70)),
//                       title: Text(
//                         groupName,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       subtitle: Text(
//                         "Tap to enter this group",
//                         style: const TextStyle(color: Colors.white38),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               ListTile(
//                 title: const Text(
//                   "Join an Existing Group",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 // subtitle: const Text(
//                 //   "Already a member? Join an existing one.",
//                 //   style: TextStyle(color: Colors.white38),
//                 // ),
//                 onTap: () {
//                   // setState(() {
//                   //   _showingGroupLists = false;
//                   //   _showCreateGroup = false;
//                   // });
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const JoinGroupScreen(),
//                     ),
//                   );
//                 },
//               ),
//               ListTile(
//                 title: const Text(
//                   "Create New Group",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 // subtitle: const Text(
//                 //   "Don't see your group? Create a new one.",
//                 //   style: TextStyle(color: Colors.white38),
//                 // ),
//                 onTap: () {
//                   // setState(() {
//                   //   _showingGroupLists = false;
//                   //   _showCreateGroup = true;
//                   // });
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const CreateGroupScreen(),
//                     ),
//                   );
//                 },
//               )
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/main.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/create_group_screen.dart';
import 'package:instagram_flutter/screens/join_group_screen.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/utils/auth_button.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/group_storage.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class GroupChooserScreen extends StatefulWidget {
  const GroupChooserScreen({super.key});

  @override
  State<GroupChooserScreen> createState() => _GroupChooserScreenState();
}

class _GroupChooserScreenState extends State<GroupChooserScreen> {
  final ScrollController _scrollController = ScrollController();

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _groups = [];

  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  @override
  void initState() {
    super.initState();
    _loadInitialGroups();

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
    super.dispose();
  }

  Future<void> _loadInitialGroups() async {
    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('groups')
        .orderBy('joinedAt', descending: true)
        .limit(_limit)
        .get();

    _groups.clear();
    _groups.addAll(snap.docs);

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchMore() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    setState(() => _isFetchingMore = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('groups')
        .orderBy('joinedAt', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _groups.addAll(snap.docs);
    }

    setState(() => _isFetchingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, _) {
      final user = userProvider.getUser;

      if (user?.username == null) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        );
      }

      return SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: mobileBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 👤 Profile Image

                  Padding(
                    padding: const EdgeInsets.only(left: 2.5),
                    child: Row(
                      children: [
                        // CircleAvatar(
                        //   radius: 18,
                        //   backgroundColor: Colors.grey[800],
                        //   backgroundImage: user?.photoUrl != null &&
                        //           user!.photoUrl!.isNotEmpty
                        //       ? NetworkImage(user.photoUrl!)
                        //       : const AssetImage(
                        //               'assets/images/placeholder.jpg')
                        //           as ImageProvider,
                        // ),

                        // const SizedBox(width: 10),

                        // 🧑 Username
                        Text(
                          user?.username ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 🚪 Logout Button
                  IconButton(
                    icon: PhosphorIcon(PhosphorIcons.signOut(),
                        color: Colors.white),
                    onPressed: () async {
                      await AuthMethods().signOut(context);
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: mobileBackgroundColor,
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                )
              : _groups.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ListView.separated(
                                controller: _scrollController,
                                itemCount: _groups.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(color: Colors.white12),
                                itemBuilder: (context, index) {
                                  final doc = _groups[index];
                                  final groupId = doc.id;
                                  final data = doc.data();
                                  final groupName =
                                      data['name'] ?? "Unnamed Group";

                                  final currentGroupId =
                                      AppFirestore.currentGroupId;

                                  return ListTile(
                                    selected: groupId == currentGroupId,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.white12,
                                      child: PhosphorIcon(
                                        PhosphorIcons.users(),
                                        color: Colors.white70,
                                      ),
                                    ),
                                    title: Text(
                                      groupName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      "Tap to enter this group",
                                      style: TextStyle(color: Colors.white38),
                                    ),
                                    onTap: () async {
                                      // await GroupStorage.save(groupId);
                                      // AppFirestore.setGroup(groupId);

                                      // if (!mounted) return;

                                      // Navigator.of(context, rootNavigator: true)
                                      //     .pushAndRemoveUntil(
                                      //   MaterialPageRoute(
                                      //     builder: (_) => const ResponsiveLayout(
                                      //       webScreenLayout: WebScreenLayout(),
                                      //       mobileScreenLayout:
                                      //           MobileScreenLayout(),
                                      //     ),
                                      //   ),
                                      //   (route) => false,
                                      // );
                                      await GroupStorage.save(groupId);
                                      AppFirestore.setGroup(groupId);

                                      MyApp.restart(context);
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
                        _bottomActions(),
                      ],
                    ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    // return Center(
    //   child: Text(
    //     "No groups joined yet",
    //     style: TextStyle(color: Colors.white),
    //   ),
    // );
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 60,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No groups joined yet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Create a new group or join an existing one.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _bottomActions(),
      ],
    );
  }

  Widget _bottomActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AuthButton(
            isLoading: false,
            text: "Join an Existing Group",
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const JoinGroupScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          AuthButton(
            color: Colors.blue,
            isLoading: false,
            text: "Create New Group",
            // title: const Text(
            //   "Create New Group",
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateGroupScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
