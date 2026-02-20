import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart' as model;
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/instagram_searchbar.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:provider/provider.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
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

  bool _isStoryChooser =
      true; //////////////////////////////////////////////////////////////////////
  bool _isAudioStoryChosen = false;

  bool _isStoryPosting = false;

  List<Color> _colorOptions = [
    Color(0xffE57373), // Matte Coral Red
    Color(0xffF06292), // Matte Pink
    Color(0xffBA68C8), // Matte Purple
    Color(0xff64B5F6), // Matte Light Blue
    Color(0xff4DB6AC), // Matte Teal
    Color(0xff4CAF50), // Matte Green
    Color(0xffFFB74D), // Matte Orange
    Color(0xffFBC02D), // Matte Yellow
    Color(0xffB0BEC5), // Matte Blue Gray
    Color(0xff90A4AE), // Matte Slate Blue
  ];

  late Color _storyColor;

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

    setState(() {
      _loadingMap[url] = false;
      _isPreviewLoading = false;
      _playingPreviewUrl = url;
      _isPaused = false;
    });
  }

  _postToStoryText(String text, Color color) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isStoryPosting = true;
    });

    final String username =
        Provider.of<UserProvider>(context, listen: false).getUser!.username;
    final String? photoUrl =
        Provider.of<UserProvider>(context, listen: false).getUser!.photoUrl;
    final String userType =
        Provider.of<UserProvider>(context, listen: false).getUser!.userType;

    // String res = 'success';
    String res = await _firestoreMethods.postToStoryText(
        text: text,
        color: color,
        username: username,
        photoUrl: photoUrl,
        userType: userType);
    // await Future.delayed(Duration(seconds: 3));

    setState(() {
      _isStoryPosting = false;
    });

    Navigator.pop(context);
    Provider.of<GlobalKeyProvier>(context, listen: false)
        .globalKey
        ?.currentState
        ?.setState(() {});

    if (res == 'success') {
      showSnackBar(context, 'Story Posted!');
    } else {
      showSnackBar(context, 'Can\'t post the story!');
    }
  }

  _postToStory(var story) async {
    setState(() {
      _isStoryPosting = true;
    });

    final String username =
        Provider.of<UserProvider>(context, listen: false).getUser!.username;
    final String? photoUrl =
        Provider.of<UserProvider>(context, listen: false).getUser!.photoUrl;
    final String userType =
        Provider.of<UserProvider>(context, listen: false).getUser!.userType;

    String res = await _firestoreMethods.postToStory(
        story: story,
        username: username,
        photoUrl: photoUrl,
        userType: userType);

    setState(() {
      _isStoryPosting = false;
    });

    Navigator.pop(context);
    Provider.of<GlobalKeyProvier>(context, listen: false)
        .globalKey
        ?.currentState
        ?.setState(() {});

    if (res == 'success') {
      showSnackBar(context, 'Story Posted!');
    } else {
      showSnackBar(context, 'Can\'t post the story!');
    }
  }

  removeStory(String uid) async {
    setState(() {
      _isStoryPosting = true;
    });

    String res = await _firestoreMethods.removeStory(uid);

    setState(() {
      _isStoryPosting = false;
    });

    Navigator.pop(context);
    Provider.of<GlobalKeyProvier>(context, listen: false)
        .globalKey
        ?.currentState
        ?.setState(() {});

    if (res == 'success') {
      showSnackBar(context, 'Story Deleted!');
    } else {
      showSnackBar(context, 'Can\'t delete the story!');
    }
  }

  _stopProcesses() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }

  Future<void> _showModal(var track) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Post to Story'),
          content: Text('Do you want to post this track to your story?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'No',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Yes',
                style: TextStyle(color: Colors.blue),
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
    _storyColor = _colorOptions[0];
  }

  @override
  Widget build(BuildContext context) {
    final model.User user =
        Provider.of<UserProvider>(context, listen: false).getUser!;

    return Scaffold(
      body: _isStoryChooser
          ? Column(
              children: [
                _isStoryPosting
                    ? LinearProgressIndicator(color: Colors.blue)
                    : SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 60),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Text('Posting story as'),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: user.photoUrl == null
                            ? CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor: Colors.grey[300],
                              )
                            : ProgressImageDots(url: user.photoUrl!),
                        title: Row(
                          children: [
                            Text(user.username),
                            SizedBox(
                              width: 5,
                            ),
                            user.userType == 'ADMIN'
                                ? SizedBox(
                                    height: 20,
                                    child: Image.asset(
                                        'assets/images/verification_badge.png'),
                                  )
                                : Container()
                          ],
                        ),
                      ),
                      SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Text('Choose the type of story...'),
                      ),
                      SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          _buildCard(Icons.edit, 'Text Story'),
                          _buildCard(Icons.music_note, 'Audio Story'),
                          _buildCard(Icons.delete, 'Remove Your\nStory',
                              user: user),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            )

          // Audio Story
          : _isAudioStoryChosen
              ? SafeArea(
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      _isStoryPosting
                          ? LinearProgressIndicator(
                              color: Colors.blue,
                            )
                          : Container(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 8.0),
                        child: Row(
                          children: [
                            InstagramSearchBar(
                              controller: _searchController,
                              hintText: 'Search for a song...',
                            ),
                            SizedBox(width: 10),
                            GenerateButton(
                              hintText: 'Search',
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
                            )
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
                                      _loadingMap[track['preview_url']] ??
                                          false;

                                  return ListTile(
                                    leading: track['album_art_url'] != null
                                        ? CachedNetworkImage(
                                            imageUrl: track['album_art_url'],
                                            width: 50,
                                            height: 50,
                                            cacheManager: InstaCacheManager(),
                                          )
                                        : Icon(Icons.music_note),
                                    title: Text(track['name']),
                                    subtitle: Text(
                                        '${track['artist']} • ${track['album']}'),
                                    onTap: () {
                                      _showModal(track);
                                    },
                                    trailing: track['preview_url'] == null
                                        ? Icon(Icons.music_off,
                                            color: Colors.grey)
                                        : InkWell(
                                            onTap: () {
                                              if (_playingPreviewUrl ==
                                                  track['preview_url']) {
                                                _pauseOrPlayMusic();
                                              } else {
                                                _playPreview(
                                                    track['preview_url']);
                                              }
                                            },
                                            child: isLoading
                                                ? SizedBox(
                                                    height: 24,
                                                    width: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.blue,
                                                    ),
                                                  )
                                                : Icon(isPlaying && !_isPaused
                                                    ? Icons.pause
                                                    : Icons.play_arrow),
                                          ),
                                  );
                                },
                              ),
                            )
                          : Expanded(
                              child: !_isLoading
                                  ? Center(
                                      child: Text(
                                          'Results will be displayed here'))
                                  : Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.blue),
                                    ),
                            )
                    ],
                  ),
                )

              // Text and Image Story
              : Scaffold(
                  backgroundColor: _storyColor,
                  bottomNavigationBar: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: _colorOptions.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _storyColor = color;
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Stack(
                                alignment: Alignment
                                    .center, // Ensures that child is centered
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color:
                                            Colors.grey[800]!, // Border color
                                        width: 2, // Border width
                                      ),
                                    ),
                                  ),
                                  if (color == _storyColor)
                                    Icon(
                                      Icons.check,
                                      color: Colors.black, // Icon color
                                      size: 24, // Icon size
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 30),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        _isStoryPosting
                            ? Column(
                                children: [
                                  LinearProgressIndicator(color: Colors.white),
                                  SizedBox(height: 20)
                                ],
                              )
                            : SizedBox.shrink(),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: MyTextformfield(
                                  // color: _storyColor,
                                  // textColor: _storyColor,
                                  color: _storyColor,
                                  controller: _storyController,
                                  onChanged: (_) {},
                                  hintText: 'Drop your thoughts...',
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            GenerateButton(
                              hintText: 'Post',
                              onPressed: () {
                                _postToStoryText(
                                    _storyController.text, _storyColor);
                              },
                            )
                          ],
                        ),
                        SizedBox(height: 16), // Add some space between widgets
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 30.0, horizontal: 40),
                              child: Text(
                                _storyController.text,
                                style: GoogleFonts.lato().copyWith(
                                    fontSize: 50, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCard(IconData icon, String text, {model.User? user}) {
    return GestureDetector(
      onTap: () async {
        if (text == 'Text Story') {
          setState(() {
            _isStoryChooser = false;
          });
        } else if (text == 'Audio Story') {
          setState(() {
            _isStoryChooser = false;
            _isAudioStoryChosen = true;
          });
        } else if (text == 'Remove Your\nStory') {
          await removeStory(user!.uid);
        }
      },
      child: Center(
        child: Container(
          width: 150, // Width of the card
          height: 150, // Height of the card
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40.0,
                color: Colors.white,
              ),
              SizedBox(height: 8.0), // Space between icon and text
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
