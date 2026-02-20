import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/group_chooser_screen.dart';
import 'package:instagram_flutter/utils/group_storage.dart';

class GroupGateScreen extends StatefulWidget {
  const GroupGateScreen({super.key});

  @override
  State<GroupGateScreen> createState() => _GroupGateScreenState();
}

class _GroupGateScreenState extends State<GroupGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkGroup();
  }

  Future<void> _checkGroup() async {
    final groupId = await GroupStorage.load();
    debugPrint("Loaded groupId from storage: $groupId");
    if (groupId != null) {
      AppFirestore.setGroup(groupId); // ⭐ IMPORTANT
      _goToApp();
    } else {
      _goToChooser();
    }
  }

  void _goToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ResponsiveLayout(
          webScreenLayout: WebScreenLayout(),
          mobileScreenLayout: MobileScreenLayout(),
        ),
      ),
    );
  }

  void _goToChooser() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const GroupChooserScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
