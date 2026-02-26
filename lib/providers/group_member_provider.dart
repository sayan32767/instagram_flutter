import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/group_member.dart';

class GroupMemberProvider with ChangeNotifier {
  GroupMember? _user;

  GroupMember? get getUser {
    return _user;
  }

  Future<void> refreshUser() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snap = await AppFirestore.collection('group_members')
        .doc(currentUser.uid)
        .get();

    if (!snap.exists) return;

    _user = GroupMember.fromSnap(snap);

    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
