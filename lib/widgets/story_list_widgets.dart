import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/models/user.dart';
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
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).getUser!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestore.stories()
          // .where('expiryTime', isGreaterThan: Timestamp.now())
          .orderBy('storyPostedAt', descending: true)
          .limit(25)
          .snapshots() as Stream<QuerySnapshot<Map<String, dynamic>>>,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
              height: 210, child: Center(child: Text('Error loading stories')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 170,
            child: null,
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            height: 170,
            child: Center(
              child: Text('No stories available'),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return _buildAddStoryOnly(user);
        }

        /// Move current user story to front (lightweight)
        final sortedDocs = List.of(docs);
        final index =
            sortedDocs.indexWhere((doc) => doc.data()['uid'] == user.uid);

        if (index != -1) {
          final mine = sortedDocs.removeAt(index);
          sortedDocs.insert(0, mine);
        }

        return SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sortedDocs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryOnly(user);
              }

              final data = sortedDocs[index - 1].data();

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 250 + ((index % 5) * 40)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 16),
                  child: _buildStoryCard(
                    data,
                    // playerStateProvider,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddStoryOnly(User user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      child: AddToStoryCard(
        userName: user.username,
        userProfilePicUrl: user.photoUrl,
      ),
    );
  }

  Widget _buildStoryCard(
    Map<String, dynamic> data,
  ) {
    final storyType = data['storyType'];
    final storyData = data['story'];

    final uid = data['uid'];
    final username = data['username'];
    final photoUrl = data['photoUrl'];

    if (storyType == 'TEXT' && storyData != null) {
      return GestureDetector(
        onTap: () {
          Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => StoryFullScreen(
                storyText: storyData['text'],
                storyColor: storyData['color'],
                userProfilePicUrl: photoUrl,
                userName: username,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
        child: StoryTextCard(
          text: storyData['text'],
          color: storyData['color'],
          userProfilePicUrl: photoUrl,
          userName: username,
          uid: uid,
        ),
      );
    }

    if (storyType == 'MUSIC' && storyData != null) {
      final previewUrl = storyData['preview_url'];

      return GestureDetector(
        onTap: () {
          if (previewUrl == null || previewUrl.isEmpty) {
            showSnackBar(context, "No preview available for this track");
            return;
          }
        },
        child: StoryCard(
          albumArtUrl: storyData['album_art_url'],
          artistName: storyData['artist'],
          songName: storyData['name'],
          songUrl: previewUrl,
          userProfilePicUrl: photoUrl,
          userName: username,
          uid: uid,
        ),
      );
    }

    return const SizedBox();
  }
}
