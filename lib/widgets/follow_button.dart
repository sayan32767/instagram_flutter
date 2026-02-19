import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final String text;
  final Color textColor;
  final double? width;
  final double? height;

  const FollowButton({
    super.key,
    this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.text,
    this.width,
    this.height,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // ✅ no forced 240 width
      height: height ?? 32, // slightly better touch height
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // modern radius
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
