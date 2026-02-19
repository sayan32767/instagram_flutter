import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class InstagramSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final String? assetPath;
  final Color? color;
  final Color? textColor;

  const InstagramSearchBar({
    Key? key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search',
    this.assetPath,
    this.color,
    this.textColor,
  }) : super(key: key);

  Color computeColor(Color color) {
    // Calculate the brightness of the color
    double brightness = color.computeLuminance();

    // If brightness is high, use a darker color for the search bar (e.g., matte black or gray)
    // If brightness is low, use a lighter color for the search bar (e.g., matte white or light gray)
    return brightness > 0.5 ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.3);
  }

  Color getTextColor(Color backgroundColor) {
    // Calculate the brightness of the color
    double brightness = backgroundColor.computeLuminance();

    // If the background color is bright, return a dark text color, otherwise return a light text color
    return brightness < 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color == null ? Colors.grey[800] : computeColor(color!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            assetPath != null ? SvgPicture.asset(
              assetPath!, // Path to your SVG icon
              color: Colors.grey[400],
              width: 20,
              height: 20,
            ) : Container(
              height: 20,),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                cursorColor: color == null ? Colors.blue : color,
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(color: textColor == null ? Colors.white : getTextColor(textColor!)),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: textColor == null ? Colors.white : getTextColor(textColor!)),
                  border: InputBorder.none,
                ),
              ),
            ),
            // if (controller != null && controller!.text.isNotEmpty)
            //   GestureDetector(
            //     onTap: () => controller!.clear(),
            //     child: Icon(Icons.close, color: Colors.grey[400]),
            //   ),
          ],
        ),
      ),
    );
  }
}
