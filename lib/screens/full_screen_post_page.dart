import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:photo_view/photo_view.dart';

class FullscreenImageViewer extends StatefulWidget {
  final String uid;
  final String imageUrl;
  final String username;
  final String? profilePic;
  final String? userType;

  const FullscreenImageViewer({
    super.key,
    required this.uid,
    required this.imageUrl,
    required this.username,
    this.profilePic,
    this.userType,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  bool _showOverlay = true;

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black, // 🔥 black status bar
        statusBarIconBrightness: Brightness.light, // white icons (Android)
        statusBarBrightness: Brightness.dark, // iOS support
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true, // ⭐ important
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: AnimatedOpacity(
            opacity: _showOverlay ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                /// BACK BUTTON
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),

                const SizedBox(width: 8),

                /// PROFILE PIC
                GestureDetector(
                  onTap: () {
                    // Navigate to user profile screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          uid: widget.uid,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.profilePic != null &&
                            widget.profilePic!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.profilePic!,
                            cacheManager: InstaCacheManager())
                        : const AssetImage('assets/images/placeholder.jpg')
                            as ImageProvider,
                  ),
                ),

                const SizedBox(width: 10),

                /// USERNAME + BADGE
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigate to user profile screen
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                              uid: widget.uid,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        widget.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (widget.userType == 'ADMIN')
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Image.asset(
                          'assets/images/verification_badge.png',
                          height: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,

          /// ⭐ Dark gradient only in AppBar area
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black87,
                  Colors.black54,
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleOverlay,
          child: Stack(
            children: [
              /// IMAGE WITH ZOOM
              Center(
                child: Hero(
                  tag: widget.imageUrl,
                  child: PhotoView(
                    imageProvider: CachedNetworkImageProvider(widget.imageUrl,
                        cacheManager: InstaCacheManager()),
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),

                    /// Instagram-like subtle zoom limits
                    minScale: PhotoViewComputedScale.contained * 1,
                    maxScale: PhotoViewComputedScale.contained * 1,

                    enableRotation: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
