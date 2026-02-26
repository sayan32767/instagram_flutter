import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/route_observer.dart';
import 'package:instagram_flutter/firebase_options.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/group_member_provider.dart';
import 'package:instagram_flutter/providers/group_provider.dart';
import 'package:instagram_flutter/providers/player_provider.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/screens/group_gate_screen.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/presence_servoce.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.restart();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Key _appKey = UniqueKey();

  void restart() {
    setState(() {
      _appKey = UniqueKey(); // 🔥 full subtree destroy
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: _appKey, // 🔥 this forces full rebuild
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GroupMemberProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => PlayerStateProvider()),
        ChangeNotifierProvider(create: (_) => GlobalKeyProvier()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        Provider(create: (_) {
          final service = PresenceService();
          service.start();
          return service;
        }),
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: blueColor,
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: blueColor, // cursor
            selectionColor: blueColor.withOpacity(0.4), // highlight background
            selectionHandleColor: blueColor, // drag handles
          ),
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // 🔥 While waiting → show splash, not login
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: mobileBackgroundColor,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
              );
            }

            if (snapshot.hasData) {
              // AuthMethods()
              //     .signOut(context); // 🔥 force sign out to test presence
              return const GroupGateScreen();
            }

            return LoginScreen();
          },
        ),
      ),
    );
  }
}
