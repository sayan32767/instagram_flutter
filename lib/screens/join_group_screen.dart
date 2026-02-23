import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/main.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/create_group_screen.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
import 'package:instagram_flutter/services/group_services.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/group_storage.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _groupController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;

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

      MyApp.restart(context);

      // if (!mounted) return;

      // Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      //   MaterialPageRoute(
      //     builder: (_) => const ResponsiveLayout(
      //       webScreenLayout: WebScreenLayout(),
      //       mobileScreenLayout: MobileScreenLayout(),
      //     ),
      //   ),
      //   (route) => false,
      // );
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
        automaticallyImplyLeading: false,
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
        // title: const Text(
        //   "Back to Groups",
        //   style: TextStyle(
        //       color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        // ),
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

              GestureDetector(
                onTap: _loading ? null : _joinGroup,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(40)),
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
                  // setState(() {
                  //   _showCreateGroup = true;
                  // });
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen(),
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
                    'Create New Group',
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
