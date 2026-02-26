import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/player_provider.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/story_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/story_list_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class AddToStoryCard extends StatelessWidget {
  final String? userProfilePicUrl;
  final String userName;

  AddToStoryCard({this.userProfilePicUrl, required this.userName, super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUser;
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => StoryScreen()));
      },
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.33,
            height: 150,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 24, 24, 24),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // userProfilePicUrl == null
                        user?.photoUrl == null ||
                                user?.photoUrl?.toString().isEmpty == true
                            ? CircleAvatar(
                                radius: 16,
                                backgroundImage:
                                    AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor:
                                    const Color.fromARGB(255, 24, 24, 24),
                              )
                            : ProgressImageDots(
                                url: user!.photoUrl!, radius: 16),
                        SizedBox(width: 8.0),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.username == null ||
                                          user?.username?.isEmpty == true
                                      ? 'Your Story'
                                      : user!.username,
                                  style: TextStyle(
                                    color: Colors.white,
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
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Story...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Align(
                    alignment: Alignment.topCenter,

                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFE1306C),
                            Color(0xFFF77737),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: PhosphorIcon(
                        PhosphorIconsRegular.plusCircle,
                        size: 50,
                        color: Colors.white, // Important: must NOT be grey
                      ),
                    ),
                    // child: null,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
