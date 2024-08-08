import 'package:flutter/material.dart';
import 'package:instagram_flutter/utils/colors.dart';

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
            child: Image.network(
              url,
              width: radius == null ? 40 : radius! * 2,
              height: radius == null ? 40 : radius! * 2,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                } else {
                  return Center(
                    child: SizedBox(
                      width: 50,
                      child: Image.asset('assets/images/loading_dots_2.gif')
                    )
                  );
                }
              },
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                return Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}