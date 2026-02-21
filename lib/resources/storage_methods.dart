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

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class StorageMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  static String _uploadPreset = dotenv.get(
    'CLOUDINARY_UPLOAD_PRESET',
    fallback: '',
  );

  /// Upload image → Cloudinary
  Future<dynamic> uploadImageToStorage(
    String childName,
    Uint8List? file,
    bool isPost,
  ) async {
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

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = _uploadPreset
      ..fields["public_id"] = publicId
      ..fields["asset_folder"] = childName // ⭐ ADD THIS
      ..files.add(
        http.MultipartFile.fromBytes("file", compressed, filename: "$id.jpg"),
      );

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

  /// COMPRESSION WITH FFMPEG

  Future<String> compressVideoWithFFmpeg(String inputPath) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';

    print("🔹 Input: $inputPath");
    print("🔹 Output: $outputPath");

    await FFmpegKit.cancel();

    final command = '-y '
        '-i "$inputPath" '
        '-vf scale=720:-2 '
        '-c:v libx264 '
        '-preset veryfast '
        '-b:v 1200k '
        '-maxrate 1200k '
        '-bufsize 2400k '
        '-pix_fmt yuv420p '
        '-movflags +faststart '
        '-c:a aac '
        '-b:a 128k '
        '"$outputPath"';

    print("🚀 Starting FFmpeg...");

    final session = await FFmpegKit.execute(command);

    print("🟢 FFmpeg finished");

    final returnCode = await session.getReturnCode();
    print("Return code: $returnCode");

    final logs = await session.getAllLogsAsString();
    print("Logs:");
    print(logs);

    if (!ReturnCode.isSuccess(returnCode)) {
      throw Exception("Compression failed");
    }

    final exists = await File(outputPath).exists();
    print("File exists: $exists");

    if (!exists) {
      throw Exception("Output file missing");
    }

    final finalSizeMB = await File(outputPath).length() / (1024 * 1024);

    print("Final size: $finalSizeMB MB");

    return outputPath;
  }

  Future<double> getVideoDuration(String path) async {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    final duration = double.tryParse(info?.getDuration() ?? "0") ?? 0;
    return duration;
  }

  /// 🎬 Upload VIDEO → Flask → Telegram (for Reels)
  Future<Map<String, dynamic>> uploadReelToStorage(
    XFile videoFile,
    String reelId,
  ) async {
    const int maxSizeMB =
        100; // 100 MB max for Telegram, but we aim for much less after compression
    const int maxDurationSec = 90;

    /// 📏 Check file size
    final file = File(videoFile.path);
    final sizeMB = await file.length() / (1024 * 1024);

    if (sizeMB > maxSizeMB) {
      throw Exception("Video too large. Max allowed is $maxSizeMB MB.");
    }

    /// ⏱ Get duration
    final duration = await getVideoDuration(videoFile.path);

    if (duration > maxDurationSec) {
      throw Exception("Video too long. Max $maxDurationSec seconds allowed.");
    }

    String uploadPath = videoFile.path;

    /// 🗜 Compress if size > 5MB
    try {
      if (sizeMB > 1) {
        debugPrint("Original size: $sizeMB MB");

        final compressedPath = await compressVideoWithFFmpeg(videoFile.path);

        final finalSizeMB = await File(compressedPath).length() / (1024 * 1024);

        debugPrint(
          "Final size: $finalSizeMB MB",
        );

        if (finalSizeMB > 10) {
          throw Exception("Video too large after compression.");
        }

        uploadPath = compressedPath;
      }
    } catch (e) {
      throw Exception("Failed to compress video: $e");
    }

    /// 🔥 IMPORTANT: return Telegram file_id
    // throw Exception("Video upload disabled for testing");

    /// 🌐 Upload to YOUR Flask API (Telegram backend now)
    final String baseUrl = dotenv.get('BASE_URL', fallback: '');
    final uri = Uri.parse("$baseUrl/upload-reel");

    final request = http.MultipartRequest("POST", uri)
      ..headers["X-API-KEY"] =
          dotenv.get('API_KEY', fallback: '') // For simple auth in Flask API
      ..files.add(await http.MultipartFile.fromPath("video", uploadPath,
          contentType: http.MediaType("video", "mp4")))
      ..fields["caption"] = reelId;

    final response = await request.send();
    final body = await response.stream.bytesToString();

    final data = json.decode(body) as Map<String, dynamic>;

    if (data["success"] != true) {
      throw Exception(data["error"] ?? "Upload failed");
    }

    if (response.statusCode != 200) {
      throw Exception("Video upload failed");
    }

    /// 🔥 IMPORTANT: return Telegram file_id
    return {"fileId": data["file_id"]};
  }
}
