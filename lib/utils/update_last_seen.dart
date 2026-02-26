import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram_flutter/core/app_firestore.dart';

class UpdateLastSeen with WidgetsBindingObserver {
  final _auth = FirebaseAuth.instance;

  Timer? _heartbeatTimer;

  Timer? _debounceTimer;
  late final StreamSubscription _authSub;

  void start() {
    WidgetsBinding.instance.addObserver(this);

    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _updateLastActive();
      } else {
        _heartbeatTimer?.cancel();
      }
    });

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updateLastActive(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateLastActive();
    }
  }

  Future<void> _updateLastActive() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await AppFirestore.collection('members').doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _debounceTimer?.cancel();
    _authSub.cancel();
  }
}
