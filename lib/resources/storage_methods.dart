// import 'dart:typed_data';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:uuid/uuid.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image/image.dart' as img;

// class StorageMethods {
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   Future<dynamic> uploadImageToStorage(
//       String childName, Uint8List? file, bool isPost) async {
//     if (file == null) return file;

//     // Decode
//     img.Image? image = img.decodeImage(file);

//     if (image == null) {
//       return null;
//     }

//     final jpgImage = img.encodeJpg(image);

//     final compressedImage = await FlutterImageCompress.compressWithList(
//       jpgImage,
//       quality: 75,
//       format: CompressFormat.jpeg,
//     );

//     Reference ref =
//         _storage.ref().child(childName).child(_auth.currentUser!.uid);

//     if (isPost) {
//       String id = const Uuid().v1();
//       ref = ref.child(id);
//     }

//     try {
//       UploadTask uploadTask = ref.putData(
//           compressedImage, SettableMetadata(contentType: 'image/jpeg'));
//       TaskSnapshot snap = await uploadTask;
//       String downloadUrl = await snap.ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       throw e.toString();
//     }
//   }

//   Future<void> deleteImageFromStorage(String childName) async {
//     try {
//       Reference ref =
//           _storage.ref().child(childName).child(_auth.currentUser!.uid);

//       await ref.delete();
//       print('File successfully deleted');
//     } catch (e) {
//       throw e.toString();
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  static String _uploadPreset =
      dotenv.get('CLOUDINARY_UPLOAD_PRESET', fallback: '');

  /// Upload image → Cloudinary
  Future<dynamic> uploadImageToStorage(
      String childName, Uint8List? file, bool isPost) async {
    if (file == null) return null;

    // Decode
    final image = img.decodeImage(file);
    if (image == null) return null;

    /// 🔹 Resize to max width = 1080 while keeping aspect ratio
    final resized =
        image.width > 1080 ? img.copyResize(image, width: 1080) : image;

    // Convert to JPG
    final jpg = img.encodeJpg(resized, quality: 95);
    // quality 95 here because final compression happens next

    // Compress
    final compressed = await FlutterImageCompress.compressWithList(
      jpg,
      quality: 75,
      format: CompressFormat.jpeg,
    );

    final sizeMB = compressed.lengthInBytes / (1024 * 1024);

    if (sizeMB > 2) {
      throw Exception("Image too large");
    }

    final uid = _auth.currentUser!.uid;
    final id = const Uuid().v1(); // unique for ALL uploads

    final publicId = "$childName/$uid/$id";

    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = _uploadPreset
      ..fields["public_id"] = publicId
      ..fields["asset_folder"] = childName // ⭐ ADD THIS
      ..files.add(http.MultipartFile.fromBytes(
        "file",
        compressed,
        filename: "$id.jpg",
      ));

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Cloudinary upload failed");
    }

    final data = json.decode(await response.stream.bytesToString())
        as Map<String, dynamic>;

    return data["secure_url"];
  }

  /// NOTE:
  /// Deletion must be done from backend using API secret.
  // Future<void> deleteImageFromStorage(String publicId) async {
  //   /// ⚠️ In production this MUST be done from backend (Node/Cloud Function)
  //   throw UnimplementedError(
  //       "Deletion should be handled securely from backend using Cloudinary API secret.");
  // }

  /// 🎬 Upload VIDEO → Flask → Telegram (for Reels)
  Future<Map<String, dynamic>> uploadReelToStorage(
      XFile videoFile, String reelId) async {
    const int maxSizeMB = 10;
    const int maxDurationSec = 90;

    /// 📏 Check file size
    final file = File(videoFile.path);
    final sizeMB = await file.length() / (1024 * 1024);

    if (sizeMB > maxSizeMB) {
      throw Exception("Video too large. Max allowed is $maxSizeMB MB.");
    }

    /// ⏱ Get duration
    final info = await VideoCompress.getMediaInfo(videoFile.path);

    if ((info.duration ?? 0) / 1000 > maxDurationSec) {
      throw Exception("Video too long. Max $maxDurationSec seconds allowed.");
    }

    String uploadPath = videoFile.path;

    /// 🗜 Compress if size > 5MB
    if (sizeMB > 5) {
      final compressed = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );

      if (compressed?.file != null) {
        uploadPath = compressed!.file!.path;
      }

      final finalSizeMB = await File(uploadPath).length() / (1024 * 1024);

      if (finalSizeMB > maxSizeMB) {
        throw Exception("video too large.");
      }
    }

    /// 🌐 Upload to YOUR Flask API (Telegram backend now)
    final String baseUrl = dotenv.get('BASE_URL', fallback: '');
    final uri = Uri.parse("$baseUrl/upload-reel");

    final request = http.MultipartRequest("POST", uri)
      ..headers["X-API-KEY"] =
          'SH(*(hhf^mbsrZLHDW2seg^T67wr67RWQ^RC76R3W6e##7R%%76Q'
      ..files.add(await http.MultipartFile.fromPath("video", uploadPath))
      ..fields["caption"] = reelId;

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception("Video upload failed: $body");
    }

    final data = json.decode(body) as Map<String, dynamic>;

    if (data["success"] != true) {
      throw Exception(data["error"] ?? "Upload failed");
    }

    /// 🔥 IMPORTANT: return Telegram file_id
    return {"fileId": data["file_id"]};
  }
}
