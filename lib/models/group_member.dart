import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String uid;
  final String? photoUrl;
  final String username;
  final String bio;
  final String tagline;
  final String userEmoji;

  const GroupMember({
    required this.uid,
    required this.photoUrl,
    required this.username,
    required this.bio,
    required this.tagline,
    required this.userEmoji,
  });

  Map<String, dynamic> toJson() => {
        "username": username,
        "uid": uid,
        "photoUrl": photoUrl,
        "bio": bio,
        "tagline": tagline,
        "userEmoji": userEmoji,
      };

  static GroupMember fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return GroupMember(
      username: snapshot['username'],
      uid: snapshot['uid'],
      photoUrl: snapshot['photoUrl'],
      bio: snapshot['bio'] ?? "",
      tagline: snapshot['tagline'] ?? "",
      userEmoji: snapshot['userEmoji'] ?? "",
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';

// class OriginalUser {
//   final String email; //
//   final String uid;
//   final String username; //

//   const OriginalUser({
//     required this.email,
//     required this.uid,
//     required this.username,
//   });

//   Map<String, dynamic> toJson() => {
//         "username": username,
//         "uid": uid,
//         "email": email,
//       };

//   static OriginalUser fromSnap(DocumentSnapshot snap) {
//     var snapshot = snap.data() as Map<String, dynamic>;

//     return OriginalUser(
//       username: snapshot['username'],
//       uid: snapshot['uid'],
//       email: snapshot['email'],
//     );
//   }
// }
