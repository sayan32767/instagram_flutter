// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:instagram_flutter/models/user.dart';
// import 'package:instagram_flutter/providers/user_provider.dart';
// import 'package:instagram_flutter/resources/firestore_methods.dart';
// import 'package:instagram_flutter/utils/colors.dart';
// import 'package:instagram_flutter/utils/global_variables.dart';
// import 'package:instagram_flutter/utils/utils.dart';
// import 'package:provider/provider.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart' as VideoThumbnail;

// class PostReelScreen extends StatefulWidget {
//   const PostReelScreen({super.key});

//   @override
//   State<PostReelScreen> createState() => _PostReelScreenState();
// }

// class _PostReelScreenState extends State<PostReelScreen> {
//   String? resultUrl;
//   bool isLoading = false;
//   bool isValidated = false;

//   bool buttonIsLoading = false;

//   XFile? _videoFile;
//   late TextEditingController _descriptionController;
//   bool _isLoading = false;
//   String? resultMessage;

//   Uint8List? _thumbnailBytes;

//   // REEL METHOD
//   _selectVideo(BuildContext context) async {
//     XFile? file = await pickVideo(ImageSource.gallery);
//     if (file != null) {
//       setState(() {
//         _videoFile = file;
//       });
//       await _initializeVideo();
//     } else {
//       showSnackBar(context, 'No video selected');
//     }
//   }

//   String cleanMessage(String res) {
//     if (res.toLowerCase().startsWith('exception:')) {
//       return res.substring(10).trim();
//     }
//     return res;
//   }

//   // REEL UPLOAD
//   Future<void> _uploadReel(
//       String uid, String username, String profImage) async {
//     if (_videoFile == null) return;

//     setState(() => _isLoading = true);

//     String res = await FirestoreMethods().uploadReel(
//         _descriptionController.text,
//         _videoFile!,
//         uid,
//         username,
//         profImage,
//         _thumbnailBytes!);

//     setState(() => _isLoading = false);

//     if (res == "success") {
//       clearVideo();

//       if (mounted) {
//         Provider.of<NavigationProvider>(context, listen: false).setPage(0);
//         Provider.of<NavigationProvider>(context, listen: false)
//             .pageController!
//             .jumpToPage(0);
//         Navigator.pop(context);

//         showSnackBar(context, 'Reel uploaded successfully');
//       }
//     } else {
//       showSnackBar(context, cleanMessage(res));
//     }
//   }

//   Future<void> _generateThumbnail(String videoPath) async {
//     final bytes = await VideoThumbnail.VideoThumbnail.thumbnailData(
//       video: videoPath,
//       imageFormat: VideoThumbnail.ImageFormat.JPEG,
//       maxWidth: 512, // good balance of quality vs size
//       quality: 75, // 0–100
//     );

//     if (!mounted) return;

//     setState(() {
//       _thumbnailBytes = bytes;
//     });
//   }

//   VideoPlayerController? _videoController;
//   bool _isVideoInitialized = false;

//   Future<void> _initializeVideo() async {
//     _videoController = VideoPlayerController.file(File(_videoFile!.path));

//     await _videoController!.initialize();

//     /// 🔹 Generate thumbnail immediately
//     await _generateThumbnail(_videoFile!.path);

//     _videoController!
//       ..setLooping(true)
//       ..setVolume(0)
//       ..play();

//     setState(() {});
//   }

//   void clearVideo() {
//     setState(() {
//       _videoFile = null;
//       _thumbnailBytes = null;
//       _videoController?.dispose();
//       _videoController = null;
//     });
//   }

//   @override
//   void initState() {
//     _descriptionController = TextEditingController();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _descriptionController.dispose();
//     _videoController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final User user = Provider.of<UserProvider>(context).getUser!;

//     if (_videoFile == null) {
//       return Scaffold(
//         backgroundColor: mobileBackgroundColor,
//         appBar: AppBar(
//           backgroundColor: mobileBackgroundColor,
//           leading: IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.arrow_back),
//           ),
//           title: const Text('Post Reel'),
//         ),
//         body: Center(
//           child: ElevatedButton(
//             onPressed: () => _selectVideo(context),
//             child: const Text('Pick a video from gallery'),
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: mobileBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: mobileBackgroundColor,
//         leading: IconButton(
//           onPressed: clearVideo,
//           icon: const Icon(Icons.arrow_back),
//         ),
//         title: const Text('Post Reel'),
//         actions: [
//           _isLoading
//               ? Container()
//               : TextButton(
//                   onPressed: () async {
//                     if (_isLoading) return;

//                     setState(() {
//                       _isLoading = true;
//                     });
//                     await Future.delayed(Duration(seconds: 2));
//                     await _uploadReel(
//                         user.uid, user.username, user.photoUrl ?? '');
//                     setState(() {
//                       _isLoading = false;
//                     });
//                   },
//                   child: const Text(
//                     "Post",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blueAccent,
//                       fontSize: 16,
//                     ),
//                   ),
//                 )
//         ],
//       ),
//       body: Column(
//         children: [
//           _isLoading
//               ? const LinearProgressIndicator(
//                   color: blueColor,
//                 )
//               : const Padding(
//                   padding: EdgeInsets.only(top: 0),
//                 ),

//           /// 📝 CAPTION FIELD
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: TextField(
//               controller: _descriptionController,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 hintText: "Write a caption...",
//                 border: InputBorder.none,
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

//           /// 🎬 VIDEO PREVIEW
//           Center(
//             child: _videoController != null &&
//                     _videoController!.value.isInitialized
//                 ? ConstrainedBox(
//                     constraints: const BoxConstraints(
//                       maxHeight: 500, // limit portrait height
//                     ),
//                     child: AspectRatio(
//                       aspectRatio: _videoController!.value.aspectRatio,
//                       child: VideoPlayer(_videoController!),
//                     ),
//                   )
//                 : const SizedBox.shrink(),
//           )
//         ],
//       ),
//     );
//   }
// }
