import 'package:flutter/material.dart';

class TypingBubble extends StatefulWidget {
  final bool isMe;

  const TypingBubble({super.key, required this.isMe});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const double _waveHeight = 8;
  static const double _pauseStart = 0.65;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        double t = (_controller.value + delay) % 1.0;

        if (t > _pauseStart) {
          return _dot(0);
        }

        double waveT = t / _pauseStart;

        double offset = Curves.easeInOut.transform(
              waveT < 0.5 ? waveT * 2 : (1 - waveT) * 2,
            ) *
            _waveHeight;

        return _dot(-offset);
      },
    );
  }

  Widget _dot(double offsetY) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: CircleAvatar(
          radius: 3.5,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 12), // ⭐ SAME AS MESSAGE
        decoration: BoxDecoration(
          color: Colors.grey.shade600, // ⭐ SAME GREY
          borderRadius: BorderRadius.circular(12), // ⭐ SAME RADIUS
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0.0),
            _buildDot(0.15),
            _buildDot(0.3),
          ],
        ),
      ),
    );
  }
}
