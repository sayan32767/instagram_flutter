import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  
  String username = "";

  @override
  void initState() {
    super.initState();
    getUsername();
  }

  Future getUsername() async {
    dynamic snap = await FirebaseFirestore.instance.collection('user').doc(FirebaseAuth.instance.currentUser!.uid).get();

    setState(() {
      username = (snap.data() as Map<String, dynamic>)['username'];
    });
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'This is mobile $username'
        ),
      ),
    );
  }
}
