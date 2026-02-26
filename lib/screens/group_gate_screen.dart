import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/group_chooser_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/group_storage.dart';
import 'package:provider/provider.dart';

class GroupGateScreen extends StatefulWidget {
  const GroupGateScreen({super.key});

  @override
  State<GroupGateScreen> createState() => _GroupGateScreenState();
}

class _GroupGateScreenState extends State<GroupGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await Future.delayed(Duration.zero);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    await userProvider.refreshUser();

    final groupId = await GroupStorage.load();

    if (!mounted) return;

    if (groupId != null) {
      AppFirestore.setGroup(groupId);
      _goToApp();
    } else {
      _goToChooser();
    }
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ResponsiveLayout(
          webScreenLayout: WebScreenLayout(),
          mobileScreenLayout: MobileScreenLayout(),
        ),
      ),
    );
  }

  void _goToChooser() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const GroupChooserScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: const Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white70),
        ),
      ),
    );
  }
}
