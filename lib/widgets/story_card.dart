import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/player_provider.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/story_list_widgets.dart';
import 'package:provider/provider.dart';

class StoryCard extends StatelessWidget {
  final String albumArtUrl;
  final String artistName;
  final String songName;
  final String? userProfilePicUrl;
  final String userName;
  final String? songUrl;
  final String uid;

  StoryCard(
      {required this.albumArtUrl,
      required this.artistName,
      required this.songName,
      this.userProfilePicUrl,
      required this.userName,
      required this.songUrl,
      required this.uid,
      super.key});

  @override
  Widget build(BuildContext context) {
    final playerStateProvider = Provider.of<PlayerStateProvider>(context);
    final User user = Provider.of<UserProvider>(context).getUser!;

    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.33,
          height: 200,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 24, 24, 24),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: albumArtUrl,
                    fit: BoxFit.cover,
                    cacheManager: InstaCacheManager(),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  child: Column(
                    children: [
                      user.uid == uid
                          ? Container(
                              padding: EdgeInsets.all(4.0),
                              color: Colors.black.withOpacity(0.6),
                              child: Column(
                                children: [
                                  Center(
                                    child: Text(
                                      'Your Story',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            user.uid != uid
                                ? userProfilePicUrl == null
                                    ? CircleAvatar(
                                        radius: 16,
                                        backgroundImage: AssetImage(
                                            'assets/images/placeholder.jpg'),
                                        backgroundColor: const Color.fromARGB(
                                            255, 24, 24, 24),
                                      )
                                    : ProgressImageDots(url: userProfilePicUrl!)
                                : SizedBox.shrink(),
                            SizedBox(width: 8.0),
                            user.uid != uid
                                ? Flexible(
                                    fit: FlexFit.loose,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            userName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4.0,
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                  offset: Offset(2.0, 2.0),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox.shrink()
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  color: Colors.black.withOpacity(0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artistName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        songName,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 70,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.6),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(200.0),
              ),
              padding: EdgeInsets.all(10),
              child: playerStateProvider.url == songUrl &&
                      playerStateProvider.uid == uid
                  ? playerStateProvider.isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: Colors.grey),
                        )
                      : playerStateProvider.isPlaying
                          ? Icon(Icons.pause)
                          : Icon(Icons.play_arrow)
                  : Icon(Icons.play_arrow),
            ),
          ),
        )
      ],
    );
  }
}
