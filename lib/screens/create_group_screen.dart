import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
import 'package:instagram_flutter/screens/join_group_screen.dart';
import 'package:instagram_flutter/services/group_services.dart';
import 'package:instagram_flutter/utils/auth_button.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/group_storage.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _loading = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // setState(() {
            //   _showingGroupLists = true;
            //   _showCreateGroup = false;
            // });
            Navigator.pop(context);
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

              AuthButton(
                color: blueColor,
                onTap: _createGroup,
                isLoading: _loading,
                text: "Create Group",
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinGroupScreen(),
                    ),
                  );
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
