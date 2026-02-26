import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ReelPreviewScreen extends StatefulWidget {
  final XFile videoFile;

  const ReelPreviewScreen({super.key, required this.videoFile});

  @override
  State<ReelPreviewScreen> createState() => _ReelPreviewScreenState();
}

class _ReelPreviewScreenState extends State<ReelPreviewScreen> {
  late VideoPlayerController _videoController;
  late TextEditingController _descriptionController;
  Uint8List? _thumbnailBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _initializeVideo();
  }

  bool _isPlaying = true;
  bool _isMuted = true;

  void _togglePlayPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
      setState(() => _isPlaying = false);
    } else {
      _videoController.play();
      setState(() => _isPlaying = true);
    }
  }

  void _toggleMute() {
    if (_videoController.value.volume > 0) {
      _videoController.setVolume(0);
      setState(() => _isMuted = true);
    } else {
      _videoController.setVolume(1);
      setState(() => _isMuted = false);
    }
    setState(() {});
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.videoFile.path));

    await _videoController.initialize();
    await _generateThumbnail();

    _videoController
      ..setLooping(true)
      ..setVolume(0)
      ..play();

    setState(() {});
  }

  Future<void> _generateThumbnail() async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: widget.videoFile.path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );

    _thumbnailBytes = bytes;
  }

  String cleanMessage(String res) {
    if (res.toLowerCase().startsWith('exception:')) {
      return res.substring(10).trim();
    }
    return res;
  }

  Future<void> _uploadReel() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser!;

    setState(() => _isLoading = true);

    String res = await FirestoreMethods().uploadReel(
      _descriptionController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      widget.videoFile,
      user.uid,
      user.username,
      user.photoUrl ?? '',
      _thumbnailBytes!,
    );

    setState(() => _isLoading = false);

    if (res == "success") {
      if (mounted) {
        final navProvider =
            Provider.of<NavigationProvider>(context, listen: false);

        /// 🔥 Trigger feed refresh
        final key =
            Provider.of<GlobalKeyProvier>(context, listen: false).globalKey;

        if (key?.currentState is FeedScreenState) {
          (key?.currentState as FeedScreenState).refresh();
        }

        /// 🔥 Go Home
        navProvider.setPage(0);
        navProvider.pageController?.jumpToPage(0);

        Navigator.of(context).popUntil((route) => route.isFirst);

        showSnackBar(context, "Reel uploaded");
      }
    } else {
      showSnackBar(context, 'Failed to upload reel, please try again');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0, // 🔥 IMPORTANT
          surfaceTintColor: Colors.transparent, // 🔥 VERY IMPORTANT
          backgroundColor: Colors.black,
          title: const Text("Post Reel",
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            !_isLoading
                ? TextButton(
                    onPressed: _uploadReel,
                    child: const Text(
                      "Post",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox()
          ],
        ),
        body: Column(
          children: [
            _isLoading
                ? const LinearProgressIndicator(
                    color: Colors.blueAccent,
                  )
                : const SizedBox(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
                ],
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Write a caption...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_videoController.value.isInitialized)
              GestureDetector(
                onTap: _toggleMute,
                child: SizedBox(
                  height: 500,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _videoController.value.volume < 1 ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(20),
                          child: PhosphorIcon(
                            PhosphorIcons.speakerSimpleSlash(),
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
