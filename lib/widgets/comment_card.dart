import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/core/navigation_keys.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/screens/reels_screen.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CommentCard extends StatefulWidget {
  final snap;
  const CommentCard({super.key, required this.snap});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Container(
        key: const ValueKey("comment"),
        padding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        child: GestureDetector(
          onTap: () async {
            // reelsKey.currentState?.setActive(false);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileScreen(uid: widget.snap['uid']),
              ),
            );
            // reelsKey.currentState?.setActive(true);
          },
          child: Row(
            children: [
              widget.snap['profilePic'] == null ||
                      widget.snap['profilePic'] == ""
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          const AssetImage('assets/images/placeholder.jpg'),
                      backgroundColor: Colors.grey[300],
                    )
                  : ProgressImageDots(url: widget.snap['profilePic']),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.snap['name'] ?? 'unknown user',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.snap['text'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat.yMMMd()
                              .add_jm()
                              .format(widget.snap['datePublished'].toDate()),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
