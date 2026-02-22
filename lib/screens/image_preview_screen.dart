import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:provider/provider.dart';

class ImagePreviewScreen extends StatefulWidget {
  final Uint8List file;

  const ImagePreviewScreen({super.key, required this.file});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    _descriptionController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> postImage() async {
    final user = Provider.of<UserProvider>(context, listen: false).getUser!;

    setState(() => _isLoading = true);

    String res = await FirestoreMethods().uploadPost(
      _descriptionController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      widget.file,
      user.uid,
      user.username,
      user.photoUrl ?? '',
      user.userEmoji,
      user.tagline,
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

        showSnackBar(context, "Post created successfully");
      }
    } else {
      showSnackBar(context, "Failed to post");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0, // 🔥 IMPORTANT
        surfaceTintColor: Colors.transparent, // 🔥 VERY IMPORTANT
        backgroundColor: Colors.black,
        title:
            const Text("Post", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          !_isLoading
              ? TextButton(
                  onPressed: postImage,
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E1E1E),
                  child: ClipOval(
                    child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFF2A2A2A),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/placeholder.jpg',
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            ),
                          )
                        : Image.asset(
                            'assets/images/placeholder.jpg',
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s{2,}')),
                    ],
                    controller: _descriptionController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Image.memory(widget.file, fit: BoxFit.cover),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
