import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/player_provider.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/story_full_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/add_to_story_card.dart';
import 'package:instagram_flutter/widgets/story_card.dart';
import 'package:instagram_flutter/widgets/story_text_card.dart';
import 'package:provider/provider.dart';

class StoryListWidgets extends StatefulWidget {
  const StoryListWidgets({Key? key}) : super(key: key);

  @override
  State<StoryListWidgets> createState() => _StoryListWidgetsState();
}

class _StoryListWidgetsState extends State<StoryListWidgets> {
  final AudioPlayer audioPlayer = AudioPlayer();

  QuerySnapshot<Map<String, dynamic>>? data;

  remove() async {
    await audioPlayer.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    remove();
  }

  void _fetchAllData() async {
    data = await FirebaseFirestore.instance.collection('user').get();
  }

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  void _pauseOrPlayMusic(PlayerStateProvider playerStateProvider) async {
    if (audioPlayer.state == PlayerState.playing) {
      await audioPlayer.pause();
      playerStateProvider.setPlayStatus(false);
      playerStateProvider.setLoadingStatus(false);
    } else if (audioPlayer.state == PlayerState.paused) {
      await audioPlayer.resume();
      playerStateProvider.setPlayStatus(true);
      playerStateProvider.setLoadingStatus(false);
    }
  }

  void _playPreview(
      String url, String uid, PlayerStateProvider playerStateProvider) async {
    if (playerStateProvider.url == url && playerStateProvider.uid == uid) {
      if (audioPlayer.state == PlayerState.playing ||
          audioPlayer.state == PlayerState.paused) {
        _pauseOrPlayMusic(playerStateProvider);
        return;
      }
    }

    playerStateProvider.setUrl(url);
    playerStateProvider.setUid(uid);
    playerStateProvider.setLoadingStatus(true);

    await audioPlayer.stop();

    try {
      await audioPlayer.play(UrlSource(url));
      playerStateProvider.setLoadingStatus(false);
      playerStateProvider.setPlayStatus(true);
    } catch (_) {
      playerStateProvider.setLoadingStatus(false);
      playerStateProvider.setUrl(null);
      playerStateProvider.setUid(null);

      showSnackBar(context, 'Sorry, can\'t play that audio!');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerStateProvider =
        Provider.of<PlayerStateProvider>(context, listen: false);
    final User user =
        Provider.of<UserProvider>(context, listen: false).getUser!;

    Stream<QuerySnapshot<Map<String, dynamic>>> storyStream =
        FirebaseFirestore.instance.collection('user').snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: storyStream,
      builder: (context, snapshot) {
        List<Widget> _addToStoryWidget = [];

        if (snapshot.hasData) {
          String refreshedUsername = snapshot.data!.docs
              .firstWhere((doc) => doc['uid'] == user.uid)
              .data()['username'];

          _addToStoryWidget = [
            SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
              child: AddToStoryCard(
                  userName: refreshedUsername,
                  userProfilePicUrl: user.photoUrl),
            ),
          ];
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Row(children: _addToStoryWidget));
        }

        if (snapshot.hasError) {
          return Center(child: Row(children: _addToStoryWidget));
        }

        List<Widget> _storyList = [];

        for (QueryDocumentSnapshot<Map<String, dynamic>> userDoc
            in snapshot.data!.docs) {
          if (!userDoc.data().containsKey('storyType')) continue;

          String uid = userDoc.data()['uid'];

          // Map oldData = data!.docs.where((doc) => doc.data()['uid'] == uid).toList().first.data();

          String storyType = userDoc.data()['storyType'];
          String username = userDoc.data()['username'];

          // String username = oldData['username'];

          String? photoUrl = userDoc.data()['photoUrl'];
          // String? photoUrl = oldData['photoUrl'];

          String? userType = userDoc.data()['userType'];
          Map<String, dynamic>? storyData = userDoc.data()['story'];

          if (storyType == 'MUSIC' && storyData != null) {
            _storyList.add(
              StoryCard(
                albumArtUrl: storyData['album_art_url'],
                artistName: storyData['artist'],
                songName: storyData['name'],
                songUrl: storyData['preview_url'],
                userProfilePicUrl: photoUrl,
                userName: username,
                uid: uid,
                userType: userType,
              ),
            );
          } else if (storyType == 'TEXT' && storyData != null) {
            _storyList.add(
              StoryTextCard(
                text: storyData['text'],
                color: storyData['color'],
                userProfilePicUrl: photoUrl,
                userName: username,
                uid: uid,
                userType: userType,
              ),
            );
          } else if (storyType == 'IMAGE') {
            // Handle image type stories here (if needed)
          }
        }

        int index = _storyList.indexWhere((story) {
          if (story is StoryCard) {
            return story.uid == user.uid;
          } else if (story is StoryTextCard) {
            return story.uid == user.uid;
          } else {
            return false;
          }
        });

        if (index != -1) {
          final Widget storyToMove = _storyList.removeAt(index);
          _storyList.insert(0, storyToMove);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _addToStoryWidget +
                _storyList.map(
                  (story) {
                    return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                        child: story is StoryCard
                            ? GestureDetector(
                                onTap: () {
                                  if (story.songUrl == null ||
                                      story.songUrl!.isEmpty) {
                                    showSnackBar(context,
                                        "No preview available for this track");
                                    return;
                                  }

                                  _playPreview(story.songUrl!, story.uid,
                                      playerStateProvider);
                                },
                                child: story,
                              )
                            : story is StoryTextCard
                                ? GestureDetector(
                                    onTap: () {
                                      // Nothing
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(builder: (context) => StoryFullScreen(
                                      //     storyText: story.text,
                                      //     storyColor: story.color,
                                      //     userProfilePicUrl: story.userProfilePicUrl,
                                      //     userName: story.userName,
                                      //     userType: story.userType ?? '',
                                      //   )),
                                      // );

                                      Navigator.of(context, rootNavigator: true)
                                          .push(
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              StoryFullScreen(
                                            storyText: story.text,
                                            storyColor: story.color,
                                            userProfilePicUrl:
                                                story.userProfilePicUrl,
                                            userName: story.userName,
                                            userType: story.userType ?? '',
                                          ),
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            const begin = Offset(0.0, 1.0);
                                            const end = Offset.zero;
                                            const curve = Curves.ease;

                                            var tween = Tween(
                                                    begin: begin, end: end)
                                                .chain(
                                                    CurveTween(curve: curve));

                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: story,
                                  )
                                : Container());
                  },
                ).toList(),
          ),
        );
      },
    );
  }
}
