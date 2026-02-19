import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
import 'package:instagram_flutter/screens/profile_photo_viewer.dart';
import 'package:instagram_flutter/screens/profile_posts_screen.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/screens/reels_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/follow_button.dart';
import 'package:instagram_flutter/widgets/loading_builder_images.dart';
import 'package:instagram_flutter/models/user.dart' as model;
import 'package:provider/provider.dart';

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
  String userType = "";
  bool isFollowing = false;
  bool isLoading = false;
  late FirebaseFirestore _firestore;
  late FirestoreMethods _firestoreMethods;

  bool _isTaglinePosting = false;

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
      userType = (snap.data()! as Map)['userType'] ?? "";
      setState(() {});
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildProfileHeader(model.User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          /// 👤 Avatar + stats + follow button
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (_, __, ___) =>
                          ProfilePhotoViewer(imageUrl: userData['photoUrl']),
                    ),
                  );
                },
                child: (userData['photoUrl'] == null ||
                        userData['photoUrl'].toString().isEmpty)
                    ? const CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            AssetImage('assets/images/placeholder.jpg'),
                      )
                    : ProgressImageDots(
                        url: userData['photoUrl'],
                        radius: 40,
                      ),
              ),

              /// 📊 Stats + follow/signout
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildStatColumn(postLen, 'posts'),
                        buildStatColumn(followers, 'followers'),
                        buildStatColumn(following, 'following'),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FirebaseAuth.instance.currentUser!.uid == widget.uid
                              ? FollowButton(
                                  width: 230,
                                  backgroundColor: mobileBackgroundColor,
                                  text: 'Sign Out',
                                  textColor: primaryColor,
                                  borderColor: Colors.grey,
                                  onPressed: () async {
                                    AuthMethods().signOut();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen()),
                                    );
                                  },
                                )
                              : isFollowing
                                  ? FollowButton(
                                      width: 230,
                                      backgroundColor: Colors.white,
                                      text: 'Unfollow',
                                      textColor: Colors.black,
                                      borderColor: Colors.white,
                                      onPressed: () async {
                                        await _firestoreMethods.followUser(
                                          FirebaseAuth
                                              .instance.currentUser!.uid,
                                          userData['uid'],
                                        );
                                        setState(() {
                                          isFollowing = false;
                                          followers -= 1;
                                        });
                                      },
                                    )
                                  : FollowButton(
                                      width: 230,
                                      backgroundColor: Colors.blueAccent,
                                      text: 'Follow',
                                      textColor: primaryColor,
                                      borderColor: Colors.blueAccent,
                                      onPressed: () async {
                                        await _firestoreMethods.followUser(
                                          FirebaseAuth
                                              .instance.currentUser!.uid,
                                          userData['uid'],
                                        );
                                        setState(() {
                                          isFollowing = true;
                                          followers += 1;
                                        });
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// 🧑 Username
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top: 15),
            child: Text(
              userData?['username'] ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          /// 📄 Bio (safe — never null)
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top: 1),
            child: (userData != null &&
                    (userData['bio'] ?? "").toString().isNotEmpty)
                ? Text(userData['bio'], overflow: TextOverflow.ellipsis)
                : const SizedBox.shrink(),
          ),

          /// ✏️ Owner actions
          FirebaseAuth.instance.currentUser!.uid == widget.uid
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        FollowButton(
                          width: 120,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          text: 'Edit Profile',
                          textColor:
                              Theme.of(context).textTheme.bodyMedium!.color!,
                          borderColor: Theme.of(context).dividerColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(userData: userData),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        FollowButton(
                          width: 120,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          text: 'Set Emoji',
                          textColor:
                              Theme.of(context).textTheme.bodyMedium!.color!,
                          borderColor: Theme.of(context).dividerColor,
                          onPressed: () => _showEmojiModal(context),
                        ),
                        const SizedBox(width: 8),

                        FollowButton(
                          width: 120,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          text: 'Set Tagline',
                          textColor:
                              Theme.of(context).textTheme.bodyMedium!.color!,
                          borderColor: Theme.of(context).dividerColor,
                          onPressed: () => _showTaglineModal(context),
                        ),

                        /// 🛠 Admin tools (subtle danger style)
                        if (user.userType == 'ADMIN') ...[
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: _firestoreMethods.cleanUpDuplicatePosts,
                            child: const Text(
                              'Clean Up!',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: _firestoreMethods.deleteDuplicatePhotos,
                            child: const Text(
                              'Clean Up V2!',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox(height: 0)
        ],
      ),
    );
  }

  Future _updateUserTagline(String tagline) async {
    // String res = 'success';
    String res = await _firestoreMethods.updateTagline(tagline);
    // await Future.delayed(Duration(seconds: 3));

    if (res == 'success') {
      showSnackBar(context, 'Tagline Updated!');
    } else {
      showSnackBar(context, 'Can\'t update the tagline!');
    }
  }

  Future _updateUserEmoji(XFile? emoji) async {
    // String res = 'success';
    String res = await _firestoreMethods.updateEmoji(emoji);
    // await Future.delayed(Duration(seconds: 3));

    if (res == 'success') {
      showSnackBar(context, 'Emoji Updated!');
    } else {
      showSnackBar(context, 'Can\'t update the Emoji!');
    }
  }

  void _showEmojiModal(BuildContext context) {
    final ImagePicker _picker = ImagePicker();
    XFile? _selectedImage;

    showModalBottomSheet(
      backgroundColor: mobileBackgroundColor,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> _pickImage() async {
              final XFile? image =
                  await _picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() {
                  _selectedImage = image;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // To avoid keyboard overlap
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimizes the modal height
                children: [
                  Container(
                    width: double.infinity,
                  ),
                  Text(
                    "Pick and Preview Emoji",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Image preview container
                  _selectedImage == null
                      ? Text(
                          "No emoji selected",
                          style: TextStyle(fontSize: 16),
                        )
                      : Image.file(
                          File(_selectedImage!.path), // Display selected image
                          height: 150,
                          width: 150,
                        ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text(
                      "Pick an Image",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  SizedBox(height: 20),

                  _isTaglinePosting
                      ? CircularProgressIndicator(color: Colors.blue)
                      : ElevatedButton(
                          // onPressed: _selectedImage != null ?
                          onPressed: () async {
                            setState(() {
                              _isTaglinePosting = true;
                            });

                            await _updateUserEmoji(_selectedImage);
                            // await Future.delayed(Duration(seconds: 3));

                            setState(() {
                              _isTaglinePosting = false;
                            });

                            Navigator.of(context).pop();

                            Provider.of<NavigationProvider>(context,
                                    listen: false)
                                .setPage(0);
                            Provider.of<NavigationProvider>(context,
                                    listen: false)
                                .pageController!
                                .jumpToPage(0);
                          },
                          // : null, // Disable button if no image is selected
                          child: Text(
                            "Update",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTaglineModal(BuildContext context) {
    TextEditingController taglineController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: mobileBackgroundColor,
      context: context,
      isScrollControlled: true, // To handle the keyboard overlay properly
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // To avoid keyboard overlap
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimizes the modal height
                children: [
                  Text(
                    "Set your tagline",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: taglineController,
                    decoration: InputDecoration(
                      hintText: 'Enter your tagline',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.blue, // Set border color to blue
                          width: 1.0, // Border width
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors
                              .blue, // Set border color to blue when focused
                          width: 2.0, // Border width when focused
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors
                              .blue, // Set border color to blue when enabled
                          width: 1.0, // Border width when enabled
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _isTaglinePosting
                      ? CircularProgressIndicator(color: Colors.blue)
                      : ElevatedButton(
                          onPressed: () async {
                            String tagline = taglineController.text;

                            // if (tagline.isEmpty) return;

                            setState(() {
                              _isTaglinePosting = true;
                            });

                            await _updateUserTagline(tagline);

                            setState(() {
                              _isTaglinePosting = false;
                            });

                            Navigator.of(context).pop();

                            Provider.of<NavigationProvider>(context,
                                    listen: false)
                                .setPage(0);
                            Provider.of<NavigationProvider>(context,
                                    listen: false)
                                .pageController!
                                .jumpToPage(0);
                          },
                          child: Text(
                            "Save",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _firestoreMethods = FirestoreMethods();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser!;

    return isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 48, 47, 47),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      userData != null ? userData['username'] : "",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (userType == 'ADMIN')
                    SizedBox(
                      height: 20,
                      child:
                          Image.asset('assets/images/verification_badge.png'),
                    ),
                ],
              ),
            ),
            body: DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    /// 👤 PROFILE HEADER
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(user),
                    ),

                    /// 📑 TAB BAR
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      automaticallyImplyLeading: false,
                      elevation: 0,

                      /// 🎨 Theme-aware background
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,

                      /// 👇 Reduce tab height
                      bottom: PreferredSize(
                        preferredSize:
                            const Size.fromHeight(0), // 🔥 smaller height
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,

                          /// 🎨 Theme-aware colors
                          indicatorColor:
                              Theme.of(context).textTheme.bodyLarge!.color,
                          labelColor:
                              Theme.of(context).textTheme.bodyLarge!.color,
                          unselectedLabelColor: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .color
                              ?.withOpacity(0.6),

                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on, size: 20)),
                            Tab(icon: Icon(Icons.video_library, size: 20)),
                          ],
                        ),
                      ),
                    )
                  ];
                },

                /// 📱 TAB CONTENT
                body: TabBarView(
                  children: [
                    // _buildPostsGrid(),
                    ProfilePostsGrid(uid: widget.uid),
                    ProfileReelsGrid(uid: widget.uid),
                  ],
                ),
              ),
            ),
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

class ProfilePostsGrid extends StatefulWidget {
  final String uid;

  const ProfilePostsGrid({super.key, required this.uid});

  @override
  State<ProfilePostsGrid> createState() => _ProfilePostsGridState();
}

class _ProfilePostsGridState extends State<ProfilePostsGrid> {
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _posts = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  // 🔹 Load first batch
  Future<void> _loadInitialPosts() async {
    final snap = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .limit(_limit)
        .get();

    _posts = snap.docs;

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // 🔹 Load more when scrolling
  Future<void> _fetchMorePosts() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    final snap = await FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _posts.addAll(snap.docs);
    }

    _isFetchingMore = false;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _loadInitialPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 400) {
        _fetchMorePosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Initial loader
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white70,
      ));
    }

    // 🔹 No posts
    if (_posts.isEmpty) {
      return const Center(child: Text("No posts yet"));
    }

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final snap = _posts[index];
                  final data = snap.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreenPosts(
                            postId: snap.id,
                            uid: widget.uid,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CustomImageLoader(imageUrl: data['postUrl']),
                    ),
                  );
                },
                childCount: _posts.length,
              ),
            ),
          ],
        ),

        // 🔹 Bottom floating loader (no scroll jump)
        if (_isFetchingMore)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            )),
          ),
      ],
    );
  }
}

class ProfileReelsGrid extends StatefulWidget {
  final String uid;

  const ProfileReelsGrid({super.key, required this.uid});

  @override
  State<ProfileReelsGrid> createState() => _ProfileReelsGridState();
}

class _ProfileReelsGridState extends State<ProfileReelsGrid> {
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _reels = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  // 🔹 Initial load
  Future<void> _loadInitialReels() async {
    final snap = await FirebaseFirestore.instance
        .collection('reels')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .limit(_limit)
        .get();

    _reels = snap.docs;

    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    } else {
      _hasMore = false;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // 🔹 Fetch more on scroll
  Future<void> _fetchMoreReels() async {
    if (_isFetchingMore || !_hasMore || _lastDoc == null) return;

    _isFetchingMore = true;

    final snap = await FirebaseFirestore.instance
        .collection('reels')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('datePublished', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_limit)
        .get();

    if (snap.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDoc = snap.docs.last;
      _reels.addAll(snap.docs);
    }

    _isFetchingMore = false;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _loadInitialReels();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 400) {
        _fetchMoreReels();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Initial loader
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white70,
      ));
    }

    // 🔹 No reels
    if (_reels.isEmpty) {
      return const Center(child: Text("No reels yet"));
    }

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final snap = _reels[index];
                  final data = snap.data() as Map<String, dynamic>;
                  final reelId = snap.id;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReelsScreen(initialReelId: reelId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomImageLoader(
                              imageUrl: data[
                                  'thumbnailUrl']), // Placeholder thumbnail
                          const Positioned(
                            bottom: 6,
                            right: 6,
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _reels.length,
              ),
            ),
          ],
        ),

        // 🔹 Bottom floating loader
        if (_isFetchingMore)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            )),
          ),
      ],
    );
  }
}
