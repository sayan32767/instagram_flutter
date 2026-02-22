import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';

class ProgressImageDots extends StatelessWidget {
  final String url;
  double? radius;
  ProgressImageDots({super.key, required this.url, this.radius});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius ?? 20,
          backgroundColor: Colors.transparent,
          child: ClipOval(
              child: CachedNetworkImage(
            imageUrl: url,
            width: radius == null ? 40 : radius! * 2,
            height: radius == null ? 40 : radius! * 2,
            fit: BoxFit.cover,
            cacheManager: InstaCacheManager(), // ⭐ long-term disk cache

            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 50,
                child: Container(
                  color: const Color.fromARGB(255, 24, 24, 24),
                ),
              ),
            ),

            errorWidget: (context, url, error) => const Center(
              child: CircleAvatar(
                radius: 20,
                backgroundColor:
                    const Color.fromARGB(255, 71, 71, 71), // 👈 white base
                child: ClipOval(),
              ),
            ),
          )),
        ),
      ],
    );
  }
}
