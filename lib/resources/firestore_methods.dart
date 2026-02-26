import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/storage_methods.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> postToStory(
      {var story, String? username, String? photoUrl}) async {
    String res = 'Some error occurred!';
    try {
      await AppFirestore.stories().doc(_auth.currentUser!.uid).set({
        'story': story,
        'storyType': 'MUSIC',
        "storyPostedAt": DateTime.now(),
        "expiryTime": DateTime.now().add(Duration(hours: 24)),
        "storyViews": [],
        "username": username,
        "uid": _auth.currentUser!.uid,
        "photoUrl": photoUrl,
      });

      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> updateTagline(String text) async {
    String res = 'Some error occurred!';
    try {
      await AppFirestore.collection('members')
          .doc(_auth.currentUser!.uid)
          .update({'tagline': text});

      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> updateEmoji(XFile? emoji) async {
    String res = 'Some Error Occurred';

    try {
      if (emoji == null) {
        await AppFirestore.collection('members')
            .doc(_auth.currentUser!.uid)
            .update({
          'userEmoji': FieldValue.delete(),
        });
      } else {
        Uint8List file = await emoji.readAsBytes();

        String emojiUrl =
            await StorageMethods().uploadImageToStorage('emojis', file, false);

        await AppFirestore.collection('members')
            .doc(_auth.currentUser!.uid)
            .update({
          'userEmoji': emojiUrl,
        });
      }

      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> postToStoryText({
    String? text,
    required Color color,
    String? username,
    String? photoUrl,
  }) async {
    String res = 'Some error occurred!';
    try {
      await AppFirestore.stories().doc(_auth.currentUser!.uid).set({
        'story': {
          'text': text,
          'color': '#${color.value.toRadixString(16).padLeft(8, '0')}'
        },
        'storyType': 'TEXT',
        "storyPostedAt": DateTime.now(),
        "expiryTime": DateTime.now().add(Duration(hours: 24)),
        "storyViews": [],
        "username": username,
        "uid": _auth.currentUser!.uid,
        "photoUrl": photoUrl,
      });

      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<String> removeStory(String uid) async {
    String res = 'Some error occurred!';
    try {
      await AppFirestore.stories().doc(_auth.currentUser!.uid).update({
        'story': FieldValue.delete(),
        'storyType': FieldValue.delete(),
        'storyPostedAt': FieldValue.delete(),
        'expiryTime': FieldValue.delete(),
        "storyViews": FieldValue.delete(),
      });

      res = 'success';
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  // Future<void> deleteDuplicatePhotos() async {
  //   try {
  //     // Initialize Firestore and Firebase Storage
  //     FirebaseFirestore firestore = FirebaseFirestore.instance;

  //     // Fetch all posts
  //     QuerySnapshot allPostsSnapshot = await AppFirestore.posts().get();

  //     // Map to store image hashes
  //     Map<String, String> imageHashes = {};
  //     Map<String, String> imageUrlsToDelete = {};

  //     // Iterate through each document
  //     for (QueryDocumentSnapshot doc in allPostsSnapshot.docs) {
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       String photoUrl = data['postUrl'];

  //       // Download image
  //       Uint8List imageData = await downloadImage(photoUrl);
  //       String hash = computeImageHash(imageData);

  //       // Check for duplicates
  //       if (imageHashes.containsKey(hash)) {
  //         // Mark the URL for deletion
  //         imageUrlsToDelete[photoUrl] = doc.id;
  //       } else {
  //         imageHashes[hash] = photoUrl;
  //       }
  //     }

  //     for (String url in imageUrlsToDelete.keys) {
  //       await AppFirestore.posts()
  //           .where('postUrl', isEqualTo: url)
  //           .get()
  //           .then((snapshot) {
  //         for (var doc in snapshot.docs) {
  //           doc.reference.delete();
  //         }
  //       });
  //     }
  //     print('Cleanup completed. Duplicates have been removed.');
  //   } catch (e) {
  //     print('An error occurred while cleaning up duplicates: $e');
  //   }
  // }

  // Future<Uint8List> downloadImage(String url) async {
  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     return response.bodyBytes;
  //   } else {
  //     throw Exception('Failed to download image');
  //   }
  // }

  // String computeImageHash(Uint8List data) {
  //   var digest = sha256.convert(data);
  //   return digest.toString();
  // }

  // Future<void> cleanUpDuplicatePosts() async {
  //   try {
  //     // Fetch all posts from the 'posts' collection
  //     QuerySnapshot allPostsSnapshot = await AppFirestore.posts().get();

  //     // A map to keep track of seen descriptions
  //     Map<String, String> seenDescriptions = {};

  //     // Iterate through each document in the snapshot
  //     for (QueryDocumentSnapshot doc in allPostsSnapshot.docs) {
  //       // Get the post data
  //       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  //       String description = data['description'];

  //       if (seenDescriptions.containsKey(description)) {
  //         // If the description is already seen, delete the current document
  //         await AppFirestore.posts().doc(doc.id).delete();
  //         print('Deleted duplicate post with description: $description');
  //       } else {
  //         // Otherwise, add it to the seen descriptions map
  //         seenDescriptions[description] = doc.id;
  //       }
  //     }

  //     print('Cleanup completed. Duplicates have been removed.');
  //   } catch (e) {
  //     print('An error occurred while cleaning up duplicates: $e');
  //   }
  // }

  // Upload Post
  Future<String> uploadPost(
      String description,
      Uint8List file,
      String uid,
      String username,
      String profImage,
      String userEmoji,
      String tagline) async {
    String res = 'Some Error Occurred';
    try {
      DocumentSnapshot lastPostSnapshot =
          await AppFirestore.collection('members').doc(uid).get();

      if (lastPostSnapshot.exists &&
          lastPostSnapshot.data() != null &&
          (lastPostSnapshot.data() as Map<String, dynamic>)
              .containsKey('lastPostTime')) {
        DateTime lastPostTime =
            (lastPostSnapshot.data() as Map<String, dynamic>)['lastPostTime']
                .toDate();
        DateTime currentTime = DateTime.now();

        // Calculate the difference in minutes
        int difference = currentTime.difference(lastPostTime).inSeconds;

        // Check if the difference is less than 5 minutes
        if (difference < 30) {
          return 'Failed!';
        } else {
          String photoUrl =
              await StorageMethods().uploadImageToStorage('posts', file, true);
          String postId = const Uuid().v1();
          Post post = Post(
              description: description,
              uid: uid,
              username: username,
              postId: postId,
              datePublished: DateTime.now(),
              postUrl: photoUrl,
              profImage: profImage,
              userEmoji: userEmoji,
              tagline: tagline,
              likes: [],
              commentCount: 0);

          AppFirestore.posts().doc(postId).set(post.toJson());

          await AppFirestore.collection('members').doc(uid).update({
            'lastPostTime': DateTime.now(),
          });

          res = 'success';
        }
      } else {
        String photoUrl =
            await StorageMethods().uploadImageToStorage('posts', file, true);
        String postId = const Uuid().v1();
        Post post = Post(
            description: description,
            uid: uid,
            username: username,
            postId: postId,
            datePublished: DateTime.now(),
            postUrl: photoUrl,
            profImage: profImage,
            userEmoji: userEmoji,
            tagline: tagline,
            likes: [],
            commentCount: 0);

        AppFirestore.posts().doc(postId).set(post.toJson());

        await _firestore.collection('user').doc(uid).update({
          'lastPostTime': DateTime.now(),
        });

        res = 'success';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> likePost(
      String collectionName, String uid, String postId, List likes) async {
    try {
      if (likes.contains(uid)) {
        await AppFirestore.collection(collectionName).doc(postId).update({
          'likes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await AppFirestore.collection(collectionName).doc(postId).update({
          'likes': FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      print(
        e.toString(),
      );
    }
  }

  Future<void> postComment(String collectionName, String postId, String text,
      String uid, String name, String profilePic) async {
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();
        final docRef = AppFirestore.collection(collectionName).doc(postId);
        await docRef.collection('comments').doc(commentId).set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now()
        });

        /// 🔥 increment counter
        await docRef.update({
          'commentCount': FieldValue.increment(1),
        });
      } else {
        debugPrint('Text is empty');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await AppFirestore.posts().doc(postId).delete();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // Future<void> followUser(String uid, String followId) async {
  //   try {
  //     DocumentSnapshot snap =
  //         await _firestore.collection('user').doc(uid).get();
  //     List following = (snap.data()! as Map)['following'];
  //     if (following.contains(followId)) {
  //       await _firestore.collection('user').doc(followId).update({
  //         'followers': FieldValue.arrayRemove([uid])
  //       });

  //       await _firestore.collection('user').doc(uid).update({
  //         'following': FieldValue.arrayRemove([followId])
  //       });
  //     } else {
  //       await _firestore.collection('user').doc(followId).update({
  //         'followers': FieldValue.arrayUnion([uid])
  //       });

  //       await _firestore.collection('user').doc(uid).update({
  //         'following': FieldValue.arrayUnion([followId])
  //       });
  //     }
  //   } catch (e) {
  //     print(e.toString());
  //   }
  // }

  Future<String> uploadReel(
    String description,
    XFile videoFile,
    String uid,
    String username,
    String profImage,
    Uint8List thumbnailFile,
  ) async {
    String res = 'Some error occurred';
    try {
      String reelId = const Uuid().v1();

      Map result =
          await StorageMethods().uploadReelToStorage(videoFile, reelId);

      /// 2️⃣ create thumbnail
      // final thumbnailUrl = generateThumbnail(fileId);

      await AppFirestore.reels().doc(reelId).set({
        "description": description,
        "uid": uid,
        "reelId": reelId,
        "username": username,
        "datePublished": DateTime.now(),
        "fileId": result['fileId'],
        // "thumbnailUrl": thumbnailUrl,
        "profImage": profImage,
        "likes": [],
      });

      res = 'success';

      // THUMBNAIL UPLOAD (Separate API call to avoid issues)
      try {
        final thumbnailUrl = await StorageMethods()
            .uploadImageToStorage("reelThumbnails", thumbnailFile, false);

        await AppFirestore.reels().doc(reelId).update({
          "thumbnailUrl": thumbnailUrl,
        });
      } catch (e) {
        return res; // Return success even if thumbnail upload fails
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> sendPushNotification({
    required String receiverUid,
    required String senderUsername,
    String? mediaOwnerUsername,
    String? mediaOwnerId,
    String type = 'text', // text | reel | post
    String? text,
  }) async {
    final String baseUrl = dotenv.get('BASE_URL_MESSAGING', fallback: '');
    debugPrint("Sending push notification to $receiverUid via $baseUrl");

    try {
      await AppFirestore.collection('members')
          .doc(receiverUid)
          .get()
          .then((doc) async {
        if (!doc.exists) {
          debugPrint('No member document found for receiverUid: $receiverUid');
          return null;
        }

        final result = await http.post(
          Uri.parse("$baseUrl/send-dm-push"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "receiverId": receiverUid,
            "title": senderUsername,
            "body": type == 'text'
                ? text ?? "Sent you a message"
                : (type == 'reel'
                    ? "🎥 Sent a reel by $mediaOwnerUsername"
                    : "📷 Sent a post by $mediaOwnerUsername"),
          }),
        );

        if (result.statusCode != 200) {
          debugPrint(
              'Failed to send push notification. Status code: ${result.statusCode}, Response: ${result.body}');
          return 'Failed to send push notification';
        } else {
          debugPrint('Push notification sent successfully: ${result.body}');
        }
      });
    } catch (e) {
      debugPrint('Error fetching member document: $e');
    }
  }

  Future<String> getOrCreateChat(String otherUid) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final chatId = getChatId(currentUid, otherUid);

    final chatRef = AppFirestore.chats().doc(chatId);

    await chatRef.set({
      'participants': [currentUid, otherUid]..sort(),
      'lastMessage': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    return chatId;
  }

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) <= 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> sendMessage({
    required String senderUsername,
    required String? mediaOwnerUsername,
    required String? mediaOwnerId,
    required String receiverId,
    required String type, // text | reel | post
    String? text,
    String? reelId,
    String? postId,
  }) async {
    final uid = _auth.currentUser!.uid;
    final chatId = getChatId(uid, receiverId);

    final chatRef = AppFirestore.chats().doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final now = FieldValue.serverTimestamp();

    final List<String> participants = [uid, receiverId]..sort();

    /// 1️⃣ create/update chat doc
    await chatRef.set({
      'participants': participants,
      'lastMessage': text ?? type,
      "mediaOwnerUid": type == 'text'
          ? null
          : (mediaOwnerId != null && mediaOwnerId.isNotEmpty
              ? mediaOwnerId
              : null),
      "mediaOwnerUsername": type == 'text'
          ? null
          : (mediaOwnerUsername != null && mediaOwnerUsername.isNotEmpty
              ? mediaOwnerUsername
              : "someone"),
      'lastMessageType': type,
      'lastMessageTime': now,
      'lastSender': uid,
      'unreadCount_$receiverId':
          uid != receiverId ? FieldValue.increment(1) : 0,
    }, SetOptions(merge: true));

    /// 2️⃣ create message
    await msgRef.set({
      "mediaOwnerUid": type == 'text'
          ? null
          : (mediaOwnerId != null && mediaOwnerId.isNotEmpty
              ? mediaOwnerId
              : null),
      "mediaOwnerUsername": type == 'text'
          ? null
          : (mediaOwnerUsername != null && mediaOwnerUsername.isNotEmpty
              ? mediaOwnerUsername
              : null),
      'senderId': uid,
      'senderUsername': senderUsername,
      'receiverId': receiverId,
      'type': type,
      'text': text,
      'reelId': reelId,
      'postId': postId,
      'createdAt': now,
      'localCreatedAt': DateTime.now().millisecondsSinceEpoch,
      'seenBy': [uid],
    });
  }
}
