import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get getUser {
    return _user;
  }

  Future<void> refreshUser() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('user')
        .doc(currentUser.uid)
        .get();

    if (!snap.exists) return;

    _user = User.fromSnap(snap);

    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
