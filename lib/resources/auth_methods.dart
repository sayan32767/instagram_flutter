import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram_flutter/resources/storage_methods.dart';
import 'package:instagram_flutter/models/user.dart' as model;

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<String>signUpUser({required String email, required String password, required String username, required String bio, Uint8List? file}) async {
    String res = "Random error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        String? photoUrl = await StorageMethods().uploadImageToStorage('profilePics', file, false);

        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          email: email,
          bio: bio,
          followers: [],
          following: [],
          photoUrl: photoUrl,
        );

        await _firestore.collection('user').doc(cred.user!.uid).set(user.toJson());
        
        res = 'success';
      } else {
        res = 'Please fill the form (bio could be empty)';
      }
    // } on FirebaseAuthException catch(e) {
    //   if (e.code == 'invalid-email') {
    //     res = 'The email address is badly formatted';
    //   } else if (e.code == 'weak-password') {
    //     res = 'Password should be atleast 8 characters';
    //   }
    } catch(e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> loginUser({required String email, required String password}) async {
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
    } catch(e) {
      res = e.toString();
    }
    return res;
  }
}
