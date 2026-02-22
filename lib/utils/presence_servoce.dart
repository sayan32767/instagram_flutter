import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Timer? _heartbeatTimer;

  StreamSubscription? _connectionSub;

  final ValueNotifier<bool> isOffline = ValueNotifier(false);

  Timer? _debounceTimer;
  bool _lastRawState = false;
  late final StreamSubscription _authSub;

  void updateRawConnectionState(bool offline) {
    /// If state didn't change → ignore
    if (offline == _lastRawState) return;

    _lastRawState = offline;

    _debounceTimer?.cancel();

    /// ⏳ Wait 2 seconds before confirming state change
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      isOffline.value = offline;
    });
  }

  void start() {
    WidgetsBinding.instance.addObserver(this);

    _authSub = _auth.authStateChanges().listen((user) {
      _connectionSub?.cancel();

      if (user != null) {
        _updateLastActive();
        _listenToConnection();
      } else {
        /// User logged out → stop everything
        _heartbeatTimer?.cancel();
        isOffline.value = false;
      }
    });

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _updateLastActive(),
    );

    _listenToConnection();
  }

  void _listenToConnection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _connectionSub = _firestore
        .collection('user')
        .doc(_auth.currentUser!.uid)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
      updateRawConnectionState(snapshot.metadata.isFromCache);
    });
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
      await _firestore.collection('user').doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _connectionSub?.cancel();
    _debounceTimer?.cancel();
    _authSub.cancel();
    isOffline.dispose();
  }
}
