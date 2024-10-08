import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/screens/search_screen.dart';

const webScreenSize = 600;

// List<Widget> homeScreenItems = [
//   const FeedScreen(),
//   const SearchScreen(),
//   const AddPostScreen(),
//   // const Scaffold(
//   //   body: Center(
//   //     child: Text('Notifications'),
//   //   ),
//   // ),
//   ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)
// ];


class NavigationProvider with ChangeNotifier {
  List<Widget> _homeScreenItems = [
    const FeedScreen(),
    const SearchScreen(),
    const AddPostScreen(),
    // const Scaffold(
    //   body: Center(
    //     child: Text('Notifications'),
    //   ),
    // ),
    ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)
  ];

  List<Widget> get homeScreenItems => _homeScreenItems;
}