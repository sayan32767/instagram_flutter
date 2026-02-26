import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// APPLE MUSIC API INTEGRATION FOR AUDIO STORIES
class AudioStoryScreen extends StatefulWidget {
  const AudioStoryScreen({super.key});

  @override
  State<AudioStoryScreen> createState() => _AudioStoryScreenState();
}

class _AudioStoryScreenState extends State<AudioStoryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<dynamic> _tracks = [];
  bool _isSearching = false;
  bool _isStoryPosting = false;
  late TextEditingController _searchController;
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  String? _currentUrl;
  bool _isLoadingAudio = false;
  PlayerState _playerState = PlayerState.stopped;

  late StreamSubscription<PlayerState> _playerStateSub;
  late StreamSubscription<void> _playerCompleteSub;

  _postToStory(var story) async {
    setState(() {
      _isStoryPosting = true;
    });

    final String username =
        Provider.of<UserProvider>(context, listen: false).getUser!.username;
    final String? photoUrl =
        Provider.of<UserProvider>(context, listen: false).getUser!.photoUrl;

    await Future.delayed(Duration(seconds: 1));

    String res = await _firestoreMethods.postToStory(
      // ONLY ADD CERTAIN FIELDS TO STORY DATA TO AVOID WASTE
      story: {
        'trackName': story['trackName'],
        'artistName': story['artistName'],
        'collectionName': story['collectionName'],
        'artworkUrl100': story['artworkUrl100'],
        'previewUrl': story['previewUrl'] ?? story['trackViewUrl'] ?? '',
      },
      username: username,
      photoUrl: photoUrl,
    );

    setState(() {
      _isStoryPosting = false;
    });

    if (res == 'success') {
      if (mounted) {
        final navProvider =
            Provider.of<NavigationProvider>(context, listen: false);

        /// 🔥 Trigger feed refresh
        final key =
            Provider.of<GlobalKeyProvier>(context, listen: false).globalKey;

        if (key?.currentState is FeedScreenState) {
          (key?.currentState as FeedScreenState).refresh();
        }

        /// 🔥 Go Home
        navProvider.setPage(0);
        navProvider.pageController?.jumpToPage(0);

        Navigator.of(context).popUntil((route) => route.isFirst);

        showSnackBar(context, "Story posted successfully");
      }
    } else {
      showSnackBar(context, 'Can\'t post the story!');
    }
  }

  Future<void> _showModal(var track) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // change background color to black
          backgroundColor: Color(0xFF1C1C1C),
          // change border radius to 10
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          title: Text('Post to Story'),
          content: Text('Do you want to post this track to your story?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'No',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _postToStory(track);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _searchTracks() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      // setState(() => _tracks.clear());
      return;
    }

    setState(() {
      _isSearching = true;
      _tracks.clear();
    });

    final uri = Uri.parse(
      "https://itunes.apple.com/search"
      "?term=${Uri.encodeComponent(query)}"
      "&entity=song"
      "&limit=25"
      "&country=IN",
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tracks = data['results'];
        });
      }
    } catch (_) {}

    setState(() => _isSearching = false);
  }

  Future<void> _playOrPause(String url) async {
    if (_currentUrl == url) {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      }
      return;
    }

    setState(() {
      _isLoadingAudio = true;
      _currentUrl = url;
    });

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      showSnackBar(context, "Couldn't play audio");
    }

    setState(() {
      _isLoadingAudio = false;
    });
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _playerCompleteSub.cancel();
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _playerState = state;
      });
    });

    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() {
        _currentUrl = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Search Music",
            style: TextStyle(fontWeight: FontWeight.bold),
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
        body: Column(
          children: [
            SizedBox(height: 10),
            _isStoryPosting
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: LinearProgressIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  )
                : Container(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: MyTextformfield(
                        onFieldSubmitted: (_) {
                          if (_searchController.text.isEmpty) {
                            // setState(() {
                            //   _tracks.clear();
                            // });
                            return;
                          } else {
                            _searchTracks();
                          }
                        },
                        onChanged: (_) {},
                        controller: _searchController,
                        hintText: 'Search for a song...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    // non rounded corners button
                    child: ElevatedButton(
                      onPressed: () {
                        if (_searchController.text.isEmpty) {
                          setState(() {
                            _tracks.clear();
                          });
                          return;
                        } else {
                          _searchTracks();
                        }
                      },
                      child: const Text(
                        "Search",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _isSearching
                ? Expanded(
                    child: Center(
                        child:
                            CircularProgressIndicator(color: Colors.white70)),
                  )
                : _tracks.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: _tracks.length,
                          itemBuilder: (context, index) {
                            final track = _tracks[index];
                            final previewUrl = track['previewUrl'];
                            final isCurrent = previewUrl == _currentUrl;
                            final isPlaying = isCurrent &&
                                _playerState == PlayerState.playing;
                            final isLoading = isCurrent && _isLoadingAudio;

                            return ListTile(
                              leading: track['artworkUrl100'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: track['artworkUrl100'],
                                      width: 50,
                                      height: 50,
                                      cacheManager: InstaCacheManager(),
                                    )
                                  : PhosphorIcon(
                                      PhosphorIconsRegular.speakerSimpleLow,
                                      size: 40,
                                      color: Colors.white70,
                                    ),
                              title: Text(track['trackName']),
                              subtitle: Text(
                                  '${track['artistName']} • ${track['collectionName']}'),
                              onTap: () {
                                _showModal(track);
                              },
                              trailing: previewUrl == null
                                  ? Icon(Icons.block, color: Colors.grey)
                                  : GestureDetector(
                                      onTap: () => _playOrPause(previewUrl),
                                      child: isLoading
                                          ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white70,
                                              ),
                                            )
                                          : Icon(
                                              isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                            ),
                                    ),
                            );
                          },
                        ),
                      )
                    : SizedBox()
          ],
        ),
      ),
    );

    // Text and Image Story
  }
}
