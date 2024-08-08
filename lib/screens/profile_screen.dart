import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
import 'package:instagram_flutter/screens/profile_posts_screen.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/follow_button.dart';
import 'package:instagram_flutter/widgets/loading_builder_images.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  dynamic userData;
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;
  late FirebaseFirestore _firestore;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot postSnap = await _firestore
          .collection('posts')
          .where('uid', isEqualTo: widget.uid)
          .get();
      DocumentSnapshot snap =
          await _firestore.collection('user').doc(widget.uid).get();
      postLen = postSnap.docs.length;
      userData = snap.data()!;
      followers = (snap.data()! as Map)['followers'].length;
      following = (snap.data()! as Map)['following'].length;
      isFollowing = (snap.data()! as Map)['followers']
          .contains(FirebaseAuth.instance.currentUser!.uid);
      setState(() {});
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading == false
        ? Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Text(userData != null ? userData['username'] : ""),
              centerTitle: false,
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          userData == null ? CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                              backgroundColor: Colors.grey[300],
                            ) : userData['photoUrl'] == null ?
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                              backgroundColor: Colors.grey[300],
                            ) : ProgressImageDots(url: userData['photoUrl'], radius: 40),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    buildStatColumn(postLen, 'posts'),
                                    buildStatColumn(followers, 'followers'),
                                    buildStatColumn(following, 'following'),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    FirebaseAuth.instance.currentUser!.uid ==
                                            widget.uid
                                        ? FollowButton(
                                            backgroundColor:
                                                mobileBackgroundColor,
                                            text: 'Sign Out',
                                            textColor: primaryColor,
                                            borderColor: Colors.grey,
                                            onPressed: () async {
                                              AuthMethods().signOut();
                                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                                                return const LoginScreen();
                                              }));
                                            },
                                          )
                                        : isFollowing
                                            ? FollowButton(
                                                backgroundColor:
                                                    Colors.white,
                                                text: 'Unfollow',
                                                textColor: Colors.black,
                                                borderColor: Colors.white,
                                                onPressed: userData == null ? () {} : () async {
                                                  await FirestoreMethods().followUser(FirebaseAuth.instance.currentUser!.uid, userData['uid']);
                                                  setState(() {
                                                    isFollowing = !isFollowing;
                                                    followers -= 1;
                                                  });
                                                },
                                              )
                                            : FollowButton(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                text: 'Follow',
                                                textColor: primaryColor,
                                                borderColor: Colors.blueAccent,
                                                onPressed: userData == null ? () {} : () async {
                                                  await FirestoreMethods().followUser(FirebaseAuth.instance.currentUser!.uid, userData['uid']);
                                                  setState(() {
                                                    isFollowing = !isFollowing;
                                                    followers += 1;
                                                  });
                                                },
                                              )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(top: 15),
                            child: Text(
                              userData != null ? userData['username'] : "",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        
                          FirebaseAuth.instance.currentUser!.uid == widget.uid ?

                          GestureDetector(

                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) {
                                return EditProfileScreen(userData: userData);
                              }));
                            },

                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(
                                ' | Edit Profile',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ) : 

                          Container(),
                        ],
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 1),
                        child: userData != null ? userData['bio'] == "" ? null : Text(
                          userData != null ? userData['bio'] : "",
                        ) : null // BAD LOGIC IK, BUT WORKS
                      )
                    ],
                  ),
                ),
                const Divider(),
                FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('posts')
                        .where('uid', isEqualTo: widget.uid).orderBy('datePublished', descending: true)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          // child: CircularProgressIndicator(
                          //   color: const Color.fromARGB(255, 48, 47, 47),
                          // ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GridView.builder(
                              shrinkWrap: true,
                              itemCount: snapshot.data!.docs.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 1.5,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                DocumentSnapshot snap =
                                    snapshot.data!.docs[index];
                                return Container(
                                  child: GestureDetector(
                                    onTap: () {
                                      final url = snap['postUrl'];
                                      final uid = widget.uid;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreenPosts(url: url, uid: uid),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: CustomImageLoader(imageUrl: snap['postUrl'])
                                    ),
                                  ),
                                );
                              }),
                        );
                      }
                    })
              ],
            ))
        : const Center(
                // child: CircularProgressIndicator(
                //   color: const Color.fromARGB(255, 48, 47, 47),
                // ),
              );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400, color: Colors.grey),
        ),
      ],
    );
  }
}
