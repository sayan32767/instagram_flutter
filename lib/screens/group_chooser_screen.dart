import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
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

String _hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

class GroupChooserScreen extends StatefulWidget {
  const GroupChooserScreen({super.key});

  @override
  State<GroupChooserScreen> createState() => _GroupChooserScreenState();
}

class _GroupChooserScreenState extends State<GroupChooserScreen> {
  final _groupController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _showCreateGroup = false;
  bool _showingGroupLists = true;

  bool _loading = false;
  String? _error;

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchUserGroups() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('groups')
        .orderBy('joinedAt', descending: true)
        .get();
  }

  Future<void> _createGroup() async {
    final name = _groupController.text;
    final password = _passController.text;
    final confirmPassword = _confirmPassController.text;

    if (name.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showSnackBar(context, "Enter all fields");
      return;
    }

    if (password.length < 8) {
      showSnackBar(context, "Password must be at least 8 characters");
      return;
    }

    if (password != confirmPassword) {
      showSnackBar(context, "Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    try {
      final groupId = await GroupService.createGroup(
        name: name,
        password: password,
      );

      await GroupStorage.save(groupId);
      AppFirestore.setGroup(groupId);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const ResponsiveLayout(
            webScreenLayout: WebScreenLayout(),
            mobileScreenLayout: MobileScreenLayout(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinGroup() async {
    final name = _groupController.text;
    final password = _passController.text;

    if (name.isEmpty || password.isEmpty) {
      showSnackBar(context, "Enter group name and password");
      return;
    }

    setState(() => _loading = true);

    try {
      final groupId = await GroupService.joinGroup(
        name: name,
        password: password,
      );

      await GroupStorage.save(groupId);
      AppFirestore.setGroup(groupId);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const ResponsiveLayout(
            webScreenLayout: WebScreenLayout(),
            mobileScreenLayout: MobileScreenLayout(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      showSnackBar(context, e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _groupController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingGroupLists) {
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
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w600),
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
                            setState(() {
                              _showingGroupLists = false;
                              _showCreateGroup = true;
                            });
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
                            setState(() {
                              _showingGroupLists = false;
                              _showCreateGroup = false;
                            });
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
                    setState(() {
                      _showingGroupLists = false;
                      _showCreateGroup = false;
                    });
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
                    setState(() {
                      _showingGroupLists = false;
                      _showCreateGroup = true;
                    });
                  },
                )
              ],
            );
          },
        ),
      );
    }

    return !_showCreateGroup
        ? Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showingGroupLists = true;
                    _showCreateGroup = false;
                  });
                },
              ),
              title: const Text(
                "Back to Groups",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
            ),
            backgroundColor: mobileBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Please enter your group details",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Group ID
                    TextFieldInput(
                      textInputFormatter: LowerCaseTextFormatter(),
                      hintText: "Group Name",
                      textInputType: TextInputType.text,
                      textEditingController: _groupController,
                    ),

                    const SizedBox(height: 12),

                    /// Password
                    TextFieldInput(
                      hintText: "Password",
                      textInputType: TextInputType.visiblePassword,
                      textEditingController: _passController,
                      isPass: true,
                    ),

                    const SizedBox(height: 20),

                    /// Error
                    // if (_error != null)
                    //   Text(
                    //     _error!,
                    //     style: const TextStyle(color: Colors.red),
                    //   ),

                    const SizedBox(height: 10),

                    InkWell(
                      onTap: _loading ? null : _joinGroup,
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                            color: blueColor),
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: Colors.white70,
                              ))
                            : const Text(
                                'Join Group',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),

                    // OR CREATE NEW GROUP
                    const SizedBox(height: 28),
                    const Text(
                      "OR",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showCreateGroup = true;
                        });
                      },
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          color: Colors.transparent,
                        ),
                        child: const Text(
                          'Create New Group',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showingGroupLists = true;
                    _showCreateGroup = false;
                  });
                },
              ),
              title: const Text(
                "Back to Groups",
                style: TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ),
            backgroundColor: mobileBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create a new group",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Group ID
                    TextFieldInput(
                      textInputFormatter: LowerCaseTextFormatter(),
                      hintText: "Group Name",
                      textInputType: TextInputType.text,
                      textEditingController: _groupController,
                    ),

                    const SizedBox(height: 12),

                    /// Password
                    TextFieldInput(
                      hintText: "Password",
                      textInputType: TextInputType.visiblePassword,
                      textEditingController: _passController,
                      isPass: true,
                    ),

                    // CONFIRM PASSWORD
                    const SizedBox(height: 12),

                    /// Password
                    TextFieldInput(
                      hintText: "Confirm Password",
                      textInputType: TextInputType.visiblePassword,
                      textEditingController: _confirmPassController,
                      isPass: true,
                    ),

                    const SizedBox(height: 20),

                    /// Error
                    // if (_error != null)
                    //   Text(
                    //     _error!,
                    //     style: const TextStyle(color: Colors.red),
                    //   ),

                    const SizedBox(height: 10),

                    InkWell(
                      onTap: _loading ? null : _createGroup,
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                            color: blueColor),
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: Colors.white70,
                              ))
                            : const Text(
                                'Create Group',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),

                    // OR JOIN AN EXISTING NEW GROUP
                    const SizedBox(height: 28),
                    const Text(
                      "OR",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showCreateGroup = false;
                        });
                      },
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          color: Colors.transparent,
                        ),
                        child: const Text(
                          'Join Existing Group',
                          style: TextStyle(color: Colors.white70),
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
