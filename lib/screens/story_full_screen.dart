import 'package:flutter/material.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/widgets/story_view.dart';

class StoryFullScreen extends StatefulWidget {
  @override
  _StoryFullScreenState createState() => _StoryFullScreenState();

  final String storyText;
  final String storyColor;
  final String? userProfilePicUrl;
  final String userName;

  StoryFullScreen({
    required this.storyText,
    required this.storyColor,
    required this.userProfilePicUrl,
    required this.userName,
  });
}

class _StoryFullScreenState extends State<StoryFullScreen> {
  final StoryController _storyController = StoryController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color(int.parse(widget.storyColor.substring(1), radix: 16)),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Column(
          children: [
            SizedBox(height: 55),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  widget.userProfilePicUrl == null
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              AssetImage('assets/images/placeholder.jpg'),
                          backgroundColor:
                              const Color.fromARGB(255, 24, 24, 24),
                        )
                      : ProgressImageDots(
                          url: widget.userProfilePicUrl!, radius: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
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
                  ),
                ],
              ),
            ),
            Expanded(
              child: StoryView(
                  storyItems: [
                    StoryItem.text(
                        title: widget.storyText,
                        backgroundColor: Color(int.parse(
                            widget.storyColor.substring(1),
                            radix: 16)),
                        textStyle: TextStyle(fontSize: 30),
                        textOuterPadding: EdgeInsets.fromLTRB(35, 25, 35, 50)),
                  ],
                  onStoryShow: null,
                  onComplete: () {
                    print("Stories completed!");
                    Navigator.pop(context);
                  },
                  progressPosition: ProgressPosition.bottom,
                  repeat: false,
                  controller: _storyController,
                  indicatorOuterPadding:
                      EdgeInsets.symmetric(vertical: 20, horizontal: 20)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storyController.dispose();
    super.dispose();
  }
}
