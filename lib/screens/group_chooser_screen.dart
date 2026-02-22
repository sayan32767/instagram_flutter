import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/create_group_screen.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
import 'package:instagram_flutter/screens/join_group_screen.dart';
import 'package:instagram_flutter/services/group_services.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/group_storage.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/v1.dart';

class GroupChooserScreen extends StatefulWidget {
  const GroupChooserScreen({super.key});

  @override
  State<GroupChooserScreen> createState() => _GroupChooserScreenState();
}

class _GroupChooserScreenState extends State<GroupChooserScreen> {
  Future<QuerySnapshot<Map<String, dynamic>>> _fetchUserGroups() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('groups')
        .orderBy('joinedAt', descending: true)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: mobileBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Your Groups",
          style: TextStyle(
              color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: mobileBackgroundColor,
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: _fetchUserGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
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

                    const SizedBox(height: 24),

                    /// 🔥 CREATE GROUP BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blueColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () {
                          // setState(() {
                          //   _showingGroupLists = false;
                          //   _showCreateGroup = true;
                          // });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateGroupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Create Group",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 🔥 JOIN GROUP BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () {
                          // setState(() {
                          //   _showingGroupLists = false;
                          //   _showCreateGroup = false;
                          // });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JoinGroupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Join Group",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final groups = snapshot.data!.docs;

          return Column(
            children: [
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final doc = groups[index];
                    final groupId = doc.id;
                    final data = doc.data();
                    final groupName = data['name'] ?? "Unnamed Group";

                    final currentGroupId = AppFirestore.currentGroupId;

                    return ListTile(
                      selected: groupId == currentGroupId,
                      onTap: () async {
                        // Switch group
                        await GroupStorage.save(groupId);
                        AppFirestore.setGroup(groupId);

                        if (!context.mounted) return;

                        Navigator.of(context, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const ResponsiveLayout(
                              webScreenLayout: WebScreenLayout(),
                              mobileScreenLayout: MobileScreenLayout(),
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white12,
                        child: Icon(
                          Icons.group,
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
                      subtitle: Text(
                        "Tap to enter this group",
                        style: const TextStyle(color: Colors.white38),
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                title: const Text(
                  "Join Existing Group",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // subtitle: const Text(
                //   "Already a member? Join an existing one.",
                //   style: TextStyle(color: Colors.white38),
                // ),
                onTap: () {
                  // setState(() {
                  //   _showingGroupLists = false;
                  //   _showCreateGroup = false;
                  // });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinGroupScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text(
                  "Create New Group",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // subtitle: const Text(
                //   "Don't see your group? Create a new one.",
                //   style: TextStyle(color: Colors.white38),
                // ),
                onTap: () {
                  // setState(() {
                  //   _showingGroupLists = false;
                  //   _showCreateGroup = true;
                  // });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
                    ),
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }
}
