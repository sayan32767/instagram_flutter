import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart' as model;
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/audio_story_screen.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/screens/text_story_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:provider/provider.dart';

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final FirestoreMethods _firestoreMethods = FirestoreMethods();

  bool _isStoryChooser = true;
  bool _isStoryPosting = false;

  removeStory(String uid) async {
    setState(() {
      _isStoryPosting = true;
    });
    await Future.delayed(Duration(seconds: 1));
    String res = await _firestoreMethods.removeStory(uid);

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

        showSnackBar(context, "Story deleted successfully");
      }
    } else {
      showSnackBar(context, 'Can\'t delete the story!');
    }
  }

  Future<void> _showModal(String uid) async {
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
          title: Text('Delete Story'),
          content: Text('Are you sure you want to delete your story?'),
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
                await removeStory(uid);
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
  }

  @override
  void initState() {
    super.initState();
  }

  // Fetch user data and story data here if needed in the future
  void _fetchData() async {}

  @override
  Widget build(BuildContext context) {
    final model.User user =
        Provider.of<UserProvider>(context, listen: false).getUser!;

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Create a Story",
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
        backgroundColor: mobileBackgroundColor,
        body: _isStoryChooser
            ? Column(
                children: [
                  _isStoryPosting
                      ? LinearProgressIndicator(
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        )
                      : SizedBox.shrink(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ListTile(
                          leading: user.photoUrl == null
                              ? CircleAvatar(
                                  radius: 20,
                                  backgroundImage: AssetImage(
                                      'assets/images/placeholder.jpg'),
                                  backgroundColor: Colors.grey[300],
                                )
                              : ProgressImageDots(url: user.photoUrl!),
                          title: Row(
                            children: [
                              Text('Posting as ${user.username}'),
                              SizedBox(
                                width: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Text('Choose the type of story...'),
                      ),
                      // SizedBox(height: 20),
                      GridView.count(
                        padding: const EdgeInsets.all(18.0),
                        crossAxisCount: 2,
                        crossAxisSpacing: 0.0,
                        mainAxisSpacing: 0.0,
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
                ],
              )
            : SizedBox());
  }

  Widget _buildCard(IconData icon, String text, {model.User? user}) {
    return GestureDetector(
      onTap: () async {
        if (text == 'Text Story') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TextStoryScreen()),
          );
        } else if (text == 'Audio Story') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AudioStoryScreen()),
          );
        } else if (text == 'Remove Your\nStory') {
          if (user != null) {
            await _showModal(user.uid);
          }
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
