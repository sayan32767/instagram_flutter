import 'package:flutter/material.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/utils/presence_servoce.dart';
import 'package:instagram_flutter/widgets/connection_banner.dart';
import 'package:provider/provider.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget webScreenLayout;
  final Widget mobileScreenLayout;
  const ResponsiveLayout(
      {super.key,
      required this.webScreenLayout,
      required this.mobileScreenLayout});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().getUser;

    if (user == null) {
      return LoginScreen();
    }

    final presence = context.read<PresenceService>();

    return ValueListenableBuilder(
      valueListenable: presence.isOffline,
      builder: (context, offline, _) {
        return Stack(
          children: [
            widget.mobileScreenLayout,
            Align(
              alignment: Alignment.topCenter,
              child: ConnectionBanner(
                isOffline: offline,
              ),
            ),
          ],
        );
      },
    );
  }
}
