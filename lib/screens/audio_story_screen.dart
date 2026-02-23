import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/instagram_searchbar.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AudioStoryScreen extends StatefulWidget {
  const AudioStoryScreen({super.key});

  @override
  State<AudioStoryScreen> createState() => _AudioStoryScreenState();
}

class _AudioStoryScreenState extends State<AudioStoryScreen> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  late TextEditingController _searchController;
  late TextEditingController _storyController;
  List<dynamic> _tracks = [];
  AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, bool> _loadingMap = {};
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  bool _isPaused = false;
  String? _playingPreviewUrl;
  bool _isStoryChooser = true;
  bool _isAudioStoryChosen = false;
  bool _isStoryPosting = false;

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
      story: story,
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
    final query = _searchController.text;

    if (_searchController.text.isEmpty) {
      setState(() {
        _tracks.clear();
      });
      return;
    }

    setState(() {
      _tracks.clear();
      _isLoading = true;
    });

    final queryParams = {
      'query': query,
    };

    // final url = 'http://192.168.29.153:8080/search?query=$query';
    final String baseUrl = dotenv.get('BASE_URL', fallback: '');

    final uri =
        Uri.parse('$baseUrl/search').replace(queryParameters: queryParams);

    var response;

    try {
      response = await http.get(uri);
    } catch (_) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      _tracks = jsonDecode(response.body);

      if (mounted)
        setState(() {
          _tracks = _getUniqueTracks();
        });
    } else {
      print('Failed to search tracks');
    }
  }

  List<dynamic> _getUniqueTracks() {
    final seen = <String>{};

    return _tracks.where((track) {
      final key = track['spotify_url'] ?? track['name']; // unique fallback
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  void _pauseOrPlayMusic() async {
    if (_audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
      setState(() {
        _isPaused = true;
      });
    } else if (_audioPlayer.state == PlayerState.paused) {
      await _audioPlayer.resume();
      setState(() {
        _isPaused = false;
      });
    } else {
      return null;
    }
  }

  void _playPreview(String url) async {
    await _audioPlayer.stop();

    setState(() {
      _loadingMap.clear();
      _loadingMap[url] = true;
      _isPreviewLoading = true;
    });

    try {
      await _audioPlayer.play(
        UrlSource(url),
      );
    } catch (_) {
      setState(() {
        _loadingMap[url] = false;
        _isPreviewLoading = false;
      });

      showSnackBar(context, 'Sorry, can\'t play that audio!');
      return;
    }
  }

  _stopProcesses() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    _stopProcesses();
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _storyController = TextEditingController();
    _storyController.addListener(() {
      setState(() {}); // Update the UI when the text changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    child: MyTextformfield(
                      onFieldSubmitted: (_) {
                        if (_searchController.text.isEmpty) {
                          setState(() {
                            _tracks.clear();
                          });
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
            _tracks.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        final previewUrl = track['preview_url'];
                        final isPlaying = previewUrl != null &&
                            _playingPreviewUrl == previewUrl;
                        final isLoading =
                            _loadingMap[track['preview_url']] ?? false;

                        return ListTile(
                          leading: track['album_art_url'] != null
                              ? CachedNetworkImage(
                                  imageUrl: track['album_art_url'],
                                  width: 50,
                                  height: 50,
                                  cacheManager: InstaCacheManager(),
                                )
                              : PhosphorIcon(
                                  PhosphorIconsRegular.speakerSimpleLow,
                                  size: 40,
                                  color: Colors.white70,
                                ),
                          title: Text(track['name']),
                          subtitle:
                              Text('${track['artist']} • ${track['album']}'),
                          onTap: () {
                            _showModal(track);
                          },
                          trailing: track['preview_url'] == null
                              ? PhosphorIcon(
                                  PhosphorIconsRegular.speakerSimpleSlash,
                                  size: 24,
                                  color: Colors.grey,
                                )
                              : InkWell(
                                  onTap: () {
                                    if (_playingPreviewUrl ==
                                        track['preview_url']) {
                                      _pauseOrPlayMusic();
                                    } else {
                                      _playPreview(track['preview_url']);
                                    }
                                  },
                                  child: isLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white70,
                                          ),
                                        )
                                      // : Icon(isPlaying && !_isPaused
                                      //     ? Icons.pause
                                      //     : Icons.play_arrow),
                                      : PhosphorIcon(
                                          isPlaying && !_isPaused
                                              ? PhosphorIconsRegular.pause
                                              : PhosphorIconsRegular.play,
                                          size: 24,
                                          color: Colors.white70,
                                        ),
                                ),
                        );
                      },
                    ),
                  )
                : Expanded(
                    child: !_isLoading
                        ? Center(child: Text('Results will be displayed here'))
                        : Center(
                            child: CircularProgressIndicator(
                                color: Colors.white70),
                          ),
                  )
          ],
        ),
      ),
    );

    // Text and Image Story
  }
}
