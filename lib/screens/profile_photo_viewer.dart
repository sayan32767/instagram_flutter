import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';

class ProfilePhotoViewer extends StatelessWidget {
  final String? imageUrl;

  const ProfilePhotoViewer({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: Stack(
          children: [
            /// 🔹 BLUR BACKGROUND
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: null
                    // Colors.black.withOpacity(0.4), // dark tint like Instagram
                    ),
              ),
            ),

            /// 🔹 ORIGINAL CONTENT (unchanged)
            Center(
              child: Hero(
                tag: imageUrl ?? "placeholder_dp",
                child: CircleAvatar(
                  radius: 130,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl!,
                          cacheManager: InstaCacheManager())
                      : const AssetImage('assets/images/placeholder.jpg')
                          as ImageProvider,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
