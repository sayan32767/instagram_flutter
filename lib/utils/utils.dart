import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();

  final XFile? _file = await _imagePicker.pickImage(
    source: source,
    maxWidth: 1080,
    maxHeight: 1080,
  );

  if (_file != null) {
    return await _file.readAsBytes();
  }
  print('no image selected');
  return null;
}

Future<XFile?> pickVideo(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();

  final XFile? file = await imagePicker.pickVideo(
    source: source,
    maxDuration: const Duration(seconds: 60),
  );

  if (file == null) {
    print('No video selected');
  }

  return file; // return file path, NOT bytes
}

void showSnackBar(BuildContext context, String content,
    {Duration duration = const Duration(seconds: 2)}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  late OverlayEntry overlayEntry;

  final animationController = AnimationController(
    vsync: Navigator.of(context),
    duration: const Duration(milliseconds: 400),
  );

  final animation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final mediaQuery = MediaQuery.of(context);

  final bottomInset = mediaQuery.viewInsets.bottom > 0
      ? mediaQuery.viewInsets.bottom
      : mediaQuery.viewPadding.bottom;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        bottom: bottomInset + 16,
        left: 16,
        right: 16,
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.95,
                end: 1.0,
              ).animate(animation),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(overlayEntry);

  // 🔥 Haptic feedback
  HapticFeedback.lightImpact();

  animationController.forward();

  Future.delayed(duration, () async {
    await animationController.reverse();
    overlayEntry.remove();
    animationController.dispose();
  });
}
