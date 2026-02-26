import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/group_member.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/storage_methods.dart';
import 'package:instagram_flutter/models/user.dart' as model;
import 'package:instagram_flutter/utils/group_storage.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:provider/provider.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;

    DocumentSnapshot snap =
        await _firestore.collection('user').doc(currentUser.uid).get();

    return model.User.fromSnap(snap);
  }

  // TO CHECK USERNAME, WE HAVE ANOTHER FUNCTION, BUT HERE THAT IS NOT IN USE, TAHT IS FOR UPDATING
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    // required String bio,
    // Uint8List? file,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        return 'Please fill all required fields';
      }

      final normalizedUsername = username.trim().toLowerCase();

      final usernameRef =
          _firestore.collection('usernames').doc(normalizedUsername);

      // 🔍 1️⃣ Check username BEFORE creating auth user
      final usernameSnap = await usernameRef.get();
      if (usernameSnap.exists) {
        return "Username already taken";
      }

      // 🔐 2️⃣ Create Firebase Auth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      // 🖼 3️⃣ Upload profile image (optional)
      // String? photoUrl;
      // if (file != null) {
      //   photoUrl = await StorageMethods()
      //       .uploadImageToStorage('profilePics', file, false);
      // }

      final user = model.User(
        // userEmoji: "",
        username: normalizedUsername,
        uid: uid,
        email: email.trim(),
        // bio: bio.trim(),
        // photoUrl: photoUrl,
        // tagline: '',
      );

      // 🧾 4️⃣ Atomic transaction
      await _firestore.runTransaction((transaction) async {
        final freshUsernameSnap = await transaction.get(usernameRef);

        // Double-check to prevent race condition
        if (freshUsernameSnap.exists) {
          throw Exception("Username already taken");
        }

        transaction.set(
          _firestore.collection('user').doc(uid),
          user.toJson(),
        );

        transaction.set(usernameRef, {'uid': uid});
      });

      return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email already in use';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email format';
      } else if (e.code == 'weak-password') {
        return 'Password should be at least 6 characters';
      }
      return "Authentication error";
    } catch (e) {
      // 🧹 Rollback auth user if transaction failed
      if (_auth.currentUser != null) {
        await _auth.currentUser!.delete();
      }
      return "Failed to signup";
    }
  }

  Future<String> loginUser(
      {required String email, required String password}) async {
    String res = 'Random error occurred.';
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = 'success';
      } else {
        res = 'Please enter all the fields.';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> updateUser({
    required String username,
    required String bio,
    required Uint8List? file,
    required bool clickFlag,
  }) async {
    try {
      if (username.trim().isEmpty) {
        return "Please enter all the fields.";
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) return "User not authenticated";

      final uid = currentUser.uid;
      final normalizedUsername = username.trim().toLowerCase();

      // final userRef = _firestore.collection('user').doc(uid);
      final userRef = AppFirestore.collection('members').doc(uid);
      final userSnap = await userRef.get();
      final oldUsername =
          (userSnap.data() as Map<String, dynamic>?)?['username'];

      String? photoUrl;

      // 🔥 Upload only if user changed image
      if (clickFlag && file != null) {
        photoUrl = await StorageMethods()
            .uploadImageToStorage('profilePics', file, false);
      } else if (clickFlag && file == null) {
        photoUrl = null; // User removed their profile picture
      }

      // ===============================
      // 🔹 CASE 1: Username NOT changed
      // ===============================
      if (oldUsername == normalizedUsername) {
        await userRef.update({
          'bio': bio.trim(),
          if (clickFlag && photoUrl != null) 'photoUrl': photoUrl,
          if (clickFlag && photoUrl == null) 'photoUrl': null,
        });

        return "success";
      }

      // ===============================
      // 🔹 CASE 2: Username changed
      // ===============================
      final newUsernameRef =
          _firestore.collection('usernames').doc(normalizedUsername);

      final oldUsernameRef =
          _firestore.collection('usernames').doc(oldUsername);

      await _firestore.runTransaction((transaction) async {
        final newUsernameSnap = await transaction.get(newUsernameRef);

        if (newUsernameSnap.exists) {
          throw Exception("Username already taken.");
        }

        transaction.set(newUsernameRef, {'uid': uid});
        transaction.delete(oldUsernameRef);

        transaction.update(userRef, {
          'username': normalizedUsername,
          'bio': bio.trim(),
          if (clickFlag && photoUrl != null) 'photoUrl': photoUrl,
          if (clickFlag && photoUrl == null) 'photoUrl': null,
        });
      });

      return "success";
    } catch (e) {
      // print("Update user error: $e");
      return e.toString();
    }
  }

  Future<String> checkAndAddUsername(String username) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      if (normalizedUsername.isEmpty) {
        return "Username cannot be empty";
      }

      final usernameRef =
          _firestore.collection('usernames').doc(normalizedUsername);

      final snap = await usernameRef.get();

      // 🔥 If username doesn't exist → available
      if (!snap.exists) {
        return "success";
      }

      final existingUid = snap.data()?['uid'];

      // 🔥 If username belongs to current user → allowed
      if (_auth.currentUser != null && existingUid == _auth.currentUser!.uid) {
        return "success";
      }

      return "Username already taken. Please choose another.";
    } catch (e) {
      return "Error checking username";
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance
          .collection('users_private')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'fcmTokens': FieldValue.arrayRemove([token])
      });
      await _auth.signOut();
      await Provider.of<UserProvider>(context, listen: false).clearUser();
      await InstaCacheManager().emptyCache();
      await GroupStorage.clear();
      AppFirestore.setGroup(null);
    } catch (e) {
      print("Sign out error: $e");
    }
  }
}
