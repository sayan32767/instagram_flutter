import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String description;
  final String uid;
  final String reelId;
  final String username;
  final datePublished;
  final String reelUrl;
  final String profImage;
  final likes;

  const Reel({
    required this.description,
    required this.uid,
    required this.reelId,
    required this.username,
    required this.datePublished,
    required this.reelUrl,
    required this.profImage,
    required this.likes,
  });

  Map<String, dynamic> toJson() => {
        "username": username,
        "uid": uid,
        "description": description,
        "reelId": reelId,
        "datePublished": datePublished,
        "reelUrl": reelUrl,
        "profImage": profImage,
        "likes": likes,
      };

  static Reel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Reel(
      username: snapshot['username'] ?? '',
      uid: snapshot['uid'],
      description: snapshot['description'] ?? '',
      reelId: snapshot['reelId'],
      datePublished: snapshot['datePublished'],
      reelUrl: snapshot['reelUrl'],
      profImage: snapshot['profImage'] ?? '',
      likes: snapshot['likes'] ?? [],
    );
  }
}
