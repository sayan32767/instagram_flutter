import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/player_provider.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/story_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/story_list_widgets.dart';
import 'package:provider/provider.dart';

class AddToStoryCard extends StatelessWidget {
  final String? userProfilePicUrl;
  final String userName;

  AddToStoryCard({
    this.userProfilePicUrl,
    required this.userName,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser!;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => StoryScreen()));
      },
      child: Stack(
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
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        userProfilePicUrl == null
                            ? CircleAvatar(
                                radius: 16,
                                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor: const Color.fromARGB(255, 24, 24, 24),
                              )
                            : ProgressImageDots(url: userProfilePicUrl!),
                        SizedBox(width: 8.0),
                        Flexible(
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
                                        color: Colors.black.withOpacity(0.4),
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 5),
                              
                              user.userType == 'ADMIN' ? SizedBox(
                                height: 20,
                                child: Image.asset('assets/images/verification_badge.png'),
                              )
                            : Container(),
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
                    padding: EdgeInsets.all(16.0),
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
                  padding: const EdgeInsets.only(top: 70.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.add_circle,
                      size: 60,
                      color: Colors.grey,
                    ),
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
