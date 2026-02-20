import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/screens/inbox_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/screens/reels_screen.dart';
// import 'package:instagram_flutter/screens/reels_screen.dart';
import 'package:instagram_flutter/screens/search_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/presence_servoce.dart';
import 'package:provider/provider.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;

  late GlobalKey globalKey;
  late PageController pageController;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late PresenceService _presence;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    _presence = PresenceService()..start();
    globalKey = GlobalKey();

    /// ⭐ FIX: sync provider with initial page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationProvider>(context, listen: false).setPage(0);
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    _presence.dispose();
    super.dispose();
  }

  void navigationTapped(int page) {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    pageController.jumpToPage(page);

    // refresh feed when home icon is tapped
    if (page == 0) {
      if (globalKey.currentState is FeedScreenState) {
        final state = globalKey.currentState as FeedScreenState;
        if (!state.isAtTop) {
          state.scrollToTop();
        }

        /// 2️⃣ Already at top → refresh
        else {
          state.scrollToTop();
          state.refresh();
        }
      }
    }
  }

  void onPageChanged(int page) {
    Provider.of<NavigationProvider>(context, listen: false).setPage(page);
  }

  Future<bool> _onWillPop() async {
    if (_navigatorKey.currentState?.canPop() ?? false) {
      _navigatorKey.currentState?.pop();
      return false;
    }

    if (_page != 0) {
      pageController.jumpToPage(0);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<GlobalKeyProvier>(context, listen: false)
        .setGlobalKey(globalKey);
    Provider.of<NavigationProvider>(context).setController(pageController);

    _page = Provider.of<NavigationProvider>(context).page ?? 0;

    final homeScreenItems = [
      FeedScreen(key: globalKey),
      const ReelsScreen(),
      const InboxScreen(),
      const SearchScreen(),
      ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: mobileBackgroundColor,
        body: Navigator(
          key: _navigatorKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Stack(fit: StackFit.expand, children: [
                PageView(
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  children: homeScreenItems,
                  physics: const BouncingScrollPhysics(),
                ),
              ]),
            );
          },
        ),
        bottomNavigationBar: CupertinoTabBar(
          height: 75,
          backgroundColor: mobileBackgroundColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                color: _page == 0 ? primaryColor : secondaryColor,
              ),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.play_circle_outline,
                color: _page == 1 ? primaryColor : secondaryColor,
              ),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.messenger_outline,
                color: _page == 2 ? primaryColor : secondaryColor,
              ),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.search,
                color: _page == 3 ? primaryColor : secondaryColor,
              ),
              label: '',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              // icon: Icon(
              //   Icons.person,
              //   color: _page == 4 ? primaryColor : secondaryColor,
              // ),
              icon: CircleAvatar(
                backgroundColor: secondaryColor,
                radius: _page == 4 ? 16 : 14,
                backgroundImage: Provider.of<UserProvider>(context)
                            .getUser
                            ?.photoUrl !=
                        null
                    ? CachedNetworkImageProvider(
                        Provider.of<UserProvider>(context).getUser!.photoUrl!,
                        cacheManager: InstaCacheManager())
                    : AssetImage('assets/images/placeholder.jpg')
                        as ImageProvider,
              ),
              label: '',
              backgroundColor: primaryColor,
            ),
          ],
          currentIndex: _page,
          onTap: navigationTapped,
        ),
      ),
    );
  }
}
