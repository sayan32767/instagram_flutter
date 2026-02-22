import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:provider/provider.dart';

class StoryTextCard extends StatelessWidget {
  final String? userProfilePicUrl;
  final String userName;
  final String uid;
  final String text;
  final String color;

  StoryTextCard(
      {this.userProfilePicUrl,
      required this.userName,
      required this.uid,
      required this.text,
      required this.color,
      super.key});

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser!;

    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.33,
          height: 200,
          decoration: BoxDecoration(
            color: Color(int.parse(color.substring(1), radix: 16)),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Stack(
            children: [
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
              Padding(
                padding:
                    EdgeInsets.fromLTRB(15, user.uid != uid ? 50 : 30, 15, 15),
                child: Center(
                  child: Text(
                    text,
                    style: GoogleFonts.lato().copyWith(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.fade,
                  ),
                ),
              )
              // Positioned(
              //   bottom: 0,
              //   left: 0,
              //   right: 0,
              //   child: Container(
              //     padding: EdgeInsets.all(8.0),
              //     color: Colors.black.withOpacity(0.6),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [

              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
