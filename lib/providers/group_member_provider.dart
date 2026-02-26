import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/group_member.dart';

class GroupMemberProvider with ChangeNotifier {
  GroupMember? _user;

  GroupMember? get getUser {
    return _user;
  }

  Future<String?> refreshUser() async {
    String? res;
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    final snap =
        await AppFirestore.collection('members').doc(currentUser.uid).get();

    if (!snap.exists) return null;

    res = "success";

    _user = GroupMember.fromSnap(snap);

    print("GroupMemberProvider: User refreshed: ${snap.data()}");

    notifyListeners();
    return res;
  }

  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
