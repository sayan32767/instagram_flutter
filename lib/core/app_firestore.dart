import 'package:cloud_firestore/cloud_firestore.dart';

class AppFirestore {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// TEMP: default groupId from migration
  /// 🔴 Replace with real join logic later
  static String currentGroupId = "f69cc9b5-0d72-11f1-b91b-3c5576023505";

  static DocumentReference get _groupDoc =>
      _db.collection('groups').doc(currentGroupId);

  // -------- scoped collections --------

  static CollectionReference posts() => _groupDoc.collection('posts');

  static CollectionReference reels() => _groupDoc.collection('reels');

  static CollectionReference chats() => _groupDoc.collection('chats');

  // -------- generic fallback --------

  static CollectionReference collection(String name) =>
      _groupDoc.collection(name);
}
