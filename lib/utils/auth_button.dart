import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final Color color;
  final Color textColor;
  final double height;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isLoading,
    required this.color,
    this.textColor = Colors.white,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap, // prevent double taps while loading
      child: Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: ShapeDecoration(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          color: color,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: textColor,
                  // fontWeight: FontWeight.w60,
                ),
              ),
      ),
    );
  }
}
