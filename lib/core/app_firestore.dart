import 'package:cloud_firestore/cloud_firestore.dart';

class AppFirestore {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? _currentGroupId;

  /// Call this after user selects group
  static void setGroup(String? groupId) {
    _currentGroupId = groupId;
  }

  static String? get currentGroupId => _currentGroupId;

  static DocumentReference get _groupDoc =>
      _db.collection('groups').doc(currentGroupId);

  // -------- scoped collections --------

  static CollectionReference posts() => _groupDoc.collection('posts');

  static CollectionReference reels() => _groupDoc.collection('reels');

  static CollectionReference chats() => _groupDoc.collection('chats');

  static CollectionReference stories() => _groupDoc.collection('stories');

  // -------- generic fallback --------

  static CollectionReference collection(String name) =>
      _groupDoc.collection(name);
}
