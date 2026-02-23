import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/feed_screen.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class TextStoryScreen extends StatefulWidget {
  const TextStoryScreen({super.key});

  @override
  State<TextStoryScreen> createState() => _TextStoryScreenState();
}

class _TextStoryScreenState extends State<TextStoryScreen> {
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
  late FocusNode _focusNode;
  late TextEditingController _storyController;
  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  bool _isStoryPosting = false;

  @override
  void dispose() {
    // TODO: implement dispose
    _storyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _focusNode = FocusNode();
    _storyController = TextEditingController();
    _storyController.addListener(() {
      setState(() {}); // Update the UI when the text changes
    });
    _storyColor = _colorOptions[0];
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

    // String res = 'success';
    String res = await _firestoreMethods.postToStoryText(
        text: text, color: color, username: username, photoUrl: photoUrl);
    await Future.delayed(Duration(seconds: 1));

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

        showSnackBar(context, "Story posted successfully");
      }
    } else {
      showSnackBar(context, 'Can\'t post the story!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          !_isStoryPosting
              ? TextButton(
                  onPressed: () {
                    _isStoryPosting
                        ? null
                        : _postToStoryText(_storyController.text, _storyColor);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      "Share",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                )
              : SizedBox()
        ],
      ),
      backgroundColor: _storyColor,
      bottomNavigationBar: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: _colorOptions.map((color) {
              return GestureDetector(
                onTap: () {
                  if (_isStoryPosting)
                    return; // 🔥 disable color change while posting
                  setState(() {
                    _storyColor = color;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Stack(
                    alignment:
                        Alignment.center, // Ensures that child is centered
                    children: [
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey[800]!, // Border color
                            width: 2, // Border width
                          ),
                        ),
                      ),
                      if (color == _storyColor)
                        PhosphorIcon(
                          PhosphorIcons.check(),
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(_focusNode);
        },
        child: Column(
          children: [
            if (_isStoryPosting)
              LinearProgressIndicator(
                color: Colors.white70,
                backgroundColor: Colors.white24,
              ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    enabled: !_isStoryPosting, // 🔥 disables field
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(220),
                      // Disallow double spaces and newlines
                      FilteringTextInputFormatter.deny(RegExp(r'\s{2,}|\n')),
                    ],
                    controller: _storyController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textAlign: TextAlign.left,
                    cursorColor: Colors.white,
                    cursorHeight: 52,
                    style: GoogleFonts.lato().copyWith(
                      fontSize: 50,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Drop your thoughts...",
                      hintStyle: TextStyle(
                        color: Colors.white54,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
