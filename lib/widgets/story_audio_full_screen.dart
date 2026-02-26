import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StoryAudioFullScreen extends StatefulWidget {
  final String? albumArtUrl;
  final String? artistName;
  final String? songName;
  final String? userProfilePicUrl;
  final String userName;
  final String? songUrl;

  const StoryAudioFullScreen({
    super.key,
    this.albumArtUrl,
    this.artistName,
    this.songName,
    this.userProfilePicUrl,
    required this.userName,
    this.songUrl,
  });

  @override
  State<StoryAudioFullScreen> createState() => _StoryAudioFullScreenState();
}

class _StoryAudioFullScreenState extends State<StoryAudioFullScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _rotationController;

  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playerErrorSub;

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioPlayer = AudioPlayer();

    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final url = widget.songUrl ??
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      _playerStateSub =
          _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (!mounted) return;

        setState(() {
          _playerState = state;
          _isLoading = false;
        });

        if (state == PlayerState.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });

      _audioPlayer.onPlayerComplete.listen((event) {
        if (!mounted) return;

        setState(() {
          _playerState = PlayerState.completed;
        });

        _rotationController.stop();
      });

      setState(() {
        _isLoading = true;
      });

      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Pause audio when app goes background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      final url = widget.songUrl ??
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else if (_playerState == PlayerState.completed) {
        await _audioPlayer.play(UrlSource(url)); // 🔥 restart properly
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      debugPrint("Toggle error: $e");
    }
  }

  IconData _getIcon() {
    if (_isLoading) return PhosphorIcons.hourglass();

    switch (_playerState) {
      case PlayerState.playing:
        return PhosphorIcons.pauseCircle();
      case PlayerState.completed:
        return PhosphorIcons.playCircle();
      default:
        return PhosphorIcons.playCircle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _playerStateSub?.cancel();
    _playerErrorSub?.cancel();

    _rotationController.dispose();

    /// HARD STOP
    _audioPlayer.stop();
    _audioPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumArt = widget.albumArtUrl ??
        "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4";

    return Scaffold(
      // backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// Blurred Background
          Positioned.fill(
            child: Image.network(
              albumArt,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          /// Content
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 55),

                  /// User Info (Instagram Story style top bar)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: widget.userProfilePicUrl == null ||
                            widget.userProfilePicUrl!.isEmpty
                        ? CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                AssetImage('assets/images/placeholder.jpg'),
                            backgroundColor:
                                const Color.fromARGB(255, 24, 24, 24),
                          )
                        : ProgressImageDots(
                            url: widget.userProfilePicUrl!, radius: 24),
                    title: Text(
                      widget.userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(PhosphorIcons.x(), color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  const Spacer(),

                  /// Rotating Album Art
                  RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      height: 250,
                      width: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(albumArt),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Song Info
                  Text(
                    widget.songName ?? "Unknown Song",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.artistName ?? "Unknown Artist",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  /// Controls
                  if (_isLoading)
                    SizedBox(
                      height: 70,
                      child: Center(
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    )
                  else if (_hasError)
                    const Text(
                      "Failed to load audio",
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    GestureDetector(
                      child: Icon(
                        _getIcon(),
                        color: Colors.white,
                        size: 70,
                      ),
                      onTap: _isLoading ? null : _togglePlayPause,
                    ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
