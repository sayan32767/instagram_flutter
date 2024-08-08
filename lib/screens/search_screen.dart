import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/screens/profile_posts_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/loading_builder_images.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:skeleton_loader/skeleton_loader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isShowUsers = false;
  Future? posts;

  getPosts() {
    posts = FirebaseFirestore.instance.collection('posts').get();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void initState() {
    super.initState();
    getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          backgroundColor: mobileBackgroundColor,
          title: MyTextformfield(
            controller: _controller,
            onChanged: (String s) {
              if (s.isNotEmpty) {
                setState(() {
                  isShowUsers = true;
                });
              } else {
                setState(() {
                  isShowUsers = false;
                });
              }
            },
          ),
        ),
        body: isShowUsers
            ? FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('user')
                    .where('username', isGreaterThanOrEqualTo: _controller.text.toLowerCase())
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      // child: CircularProgressIndicator(
                      //   color: const Color.fromARGB(255, 48, 47, 47),
                      // ),
                    );
                  } else {
                    return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return ProfileScreen(
                                    uid: snapshot.data!.docs[index]
                                        .data()['uid']);
                              }));
                            },
                            child: ListTile(
                              leading: snapshot.data!.docs[index].data()['photoUrl'] == null
                                  ? CircleAvatar(
                                      radius: 20,
                                      backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                                      backgroundColor: Colors.grey[300],
                                    )
                                  : ProgressImageDots(url: snapshot.data!.docs[index].data()['photoUrl']),
                                    title: Text(snapshot.data!.docs[index].data()['username']),
                                  )
                          );
                        });
                  }
                },
              )
            : FutureBuilder(
                future: posts,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
              //         child: const Center(
              //   child: CircularProgressIndicator(
              //     color: const Color.fromARGB(255, 48, 47, 47),
              //   ),
              // )
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GridView.custom(
                        gridDelegate: SliverQuiltedGridDelegate(
                          crossAxisCount: 4,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          repeatPattern: QuiltedGridRepeatPattern.inverted,
                          pattern: [
                            QuiltedGridTile(2, 2),
                            QuiltedGridTile(1, 1),
                            QuiltedGridTile(1, 1),
                            QuiltedGridTile(1, 2),
                          ],
                        ),
                        childrenDelegate: SliverChildBuilderDelegate(
                            childCount: snapshot.data!.docs.length,
                            (context, index) => GestureDetector(
                                onTap: () {
                                  final url = snapshot.data!.docs[index]
                                    .data()['postUrl'];
                                  final uid = snapshot.data!.docs[index]
                                    .data()['uid'];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreenPosts(url: url, uid: uid),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: CustomImageLoader(imageUrl: snapshot.data!.docs[index]
                                      .data()['postUrl'])
                                ))),
                      ),
                    );
                  }
                }),
      ),
    );
  }
}
