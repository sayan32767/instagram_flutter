import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';

class CustomImageLoader extends StatelessWidget {
  final String imageUrl;

  const CustomImageLoader({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      cacheManager: InstaCacheManager(), // ⭐ long-term cache
      imageUrl: imageUrl,
      fit: BoxFit.cover,

      /// While loading
      placeholder: (context, url) {
        return Container(
          color: const Color.fromARGB(255, 24, 24, 24),
        );
      },

      /// On error
      errorWidget: (context, url, error) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load image'),
              Icon(Icons.error),
            ],
          ),
        );
      },
    );
  }
}
