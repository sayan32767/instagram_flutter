import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConnectionBanner extends StatefulWidget {
  final bool isOffline;

  const ConnectionBanner({
    super.key,
    required this.isOffline,
  });

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _animation;

  Timer? _hideTimer;
  bool _visible = false;
  bool _lastState = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260), // slightly faster
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // slight bounce
      reverseCurve: Curves.easeInCubic,
    );

    _lastState = widget.isOffline;
  }

  @override
  void didUpdateWidget(covariant ConnectionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOffline != _lastState) {
      _lastState = widget.isOffline;

      // 🔔 subtle haptic
      HapticFeedback.lightImpact();

      _show();
    }
  }

  void _show() {
    _hideTimer?.cancel();

    setState(() => _visible = true);
    _controller.forward();

    // Auto-hide only when back online
    if (!widget.isOffline) {
      _hideTimer = Timer(const Duration(seconds: 2), () async {
        if (!mounted) return;
        await _controller.reverse();
        if (mounted) {
          setState(() => _visible = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Stack(
        children: [
          /// 🔹 Subtle dim overlay (animated)
          FadeTransition(
            opacity: _animation,
            child: Container(
              color: Colors.black.withOpacity(0.3), // subtle, premium dim
            ),
          ),

          /// 🔹 Banner
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
              ),
              child: IgnorePointer(
                ignoring: true,
                child: FadeTransition(
                  opacity: _animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.4),
                      end: Offset.zero,
                    ).animate(_animation),
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.96,
                        end: 1.0,
                      ).animate(_animation),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(235, 26, 26, 26),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isOffline
                                    ? Icons.wifi_off_rounded
                                    : Icons.wifi_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isOffline
                                    ? "No Internet"
                                    : "Back Online",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
