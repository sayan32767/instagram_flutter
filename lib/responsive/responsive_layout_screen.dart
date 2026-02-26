import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/services/notification_service.dart';
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
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();

    _notificationService = NotificationService();
    _notificationService.init();

    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    final user = context.read<UserProvider>().getUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users_private')
          .doc(user.uid)
          .set({
        'fcmTokens': FieldValue.arrayUnion([token])
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('users_private')
          .doc(user.uid)
          .set({
        'fcmTokens': FieldValue.arrayUnion([newToken])
      }, SetOptions(merge: true));
    });
  }

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
            ConnectionBanner(
              isOffline: offline,
            ),
          ],
        );
      },
    );
  }
}
