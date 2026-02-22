import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/screens/generated_image_preview_screen.dart';
import 'package:instagram_flutter/screens/image_preview_screen.dart';
import 'package:instagram_flutter/screens/reel_preview_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  late TextEditingController _controller;
  bool isLoading = false;
  String? resultUrl;
  bool isValidated = false;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    Uint8List? file = await pickImage(ImageSource.gallery);

    if (file == null) return;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(file: file),
      ),
    );
  }

  Future<void> _generateImage() async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratedImagePreviewScreen(),
      ),
    );
  }

  Future<void> _pickVideo() async {
    XFile? file = await pickVideo(ImageSource.gallery);

    if (file == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReelPreviewScreen(videoFile: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.07),
            GenerateButton(
              hintText: "Pick Image From Gallery",
              onPressed: _pickImage,
            ),
            const SizedBox(height: 20),
            GenerateButton(
              hintText: "Pick Video From Gallery",
              onPressed: _pickVideo,
            ),
            const SizedBox(height: 20),
            GenerateButton(
              hintText: "Generate Image",
              onPressed: _generateImage,
            ),
          ],
        ),
      ),
    );
  }
}

// Make sure to add this package in your pubspec.yaml file
class GenerateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? hintText;

  const GenerateButton({Key? key, this.onPressed, this.hintText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        // backgroundColor: Color.fromARGB(255, 25, 25, 25), // Button color
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        hintText ?? 'Generate',
        style: TextStyle(
          color: Colors.grey[400], // Text color
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
