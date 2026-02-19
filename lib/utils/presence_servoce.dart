import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Timer? _heartbeatTimer;

  /// START presence tracking
  void start() {
    WidgetsBinding.instance.addObserver(this);

    _updateLastActive(); // immediate ping

    /// heartbeat every 60s (industry standard: 30–90s)
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _updateLastActive(),
    );
  }

  /// STOP presence tracking
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
  }

  /// APP LIFECYCLE HANDLING
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /// Only care about RESUMED
    if (state == AppLifecycleState.resumed) {
      _updateLastActive();
    }
  }

  /// 🔥 CORE: update lastActive using SERVER time
  Future<void> _updateLastActive() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection('user').doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      /// silently ignore network errors
    }
  }
}
