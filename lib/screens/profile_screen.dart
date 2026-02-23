import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/core/app_firestore.dart';
import 'package:instagram_flutter/core/navigation_keys.dart';
import 'package:instagram_flutter/models/post.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/screens/add_post_screen.dart';
import 'package:instagram_flutter/screens/edit_profile_screen.dart';
import 'package:instagram_flutter/screens/group_chooser_screen.dart';
import 'package:instagram_flutter/screens/profile_photo_viewer.dart';
import 'package:instagram_flutter/screens/profile_posts_screen.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/screens/reels_screen.dart';
import 'package:instagram_flutter/screens/single_reel_screen.dart';
import 'package:instagram_flutter/utils/auth_button.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/my_textformfield.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/follow_button.dart';
import 'package:instagram_flutter/widgets/loading_builder_images.dart';
import 'package:instagram_flutter/models/user.dart' as model;
import 'package:instagram_flutter/widgets/text_field_input.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

// USER PHOTO, USERNAME, BIO
// ALL BEING FETCHED FORM PROVIDER,
// ALTHOUGH A QUERY HAPPENS
// ONLY IF PROFILE IS OF CURRENT USERS

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};

  final GlobalKey<_ProfilePostsGridState> _postsKey = GlobalKey();
  final GlobalKey<_ProfileReelsGridState> _reelsKey = GlobalKey();

  int totalPosts = 0;
  int totalReels = 0;

  bool isLoading = false;

  late FirebaseFirestore _firestore;
  late FirestoreMethods _firestoreMethods;

  bool _isTaglinePosting = false;

  void refresh() async {
    await loadProfileData();

    await Provider.of<UserProvider>(context, listen: false).refreshUser();

    _postsKey.currentState?.refreshPosts();
    _reelsKey.currentState?.refreshReels();
  }

  Future<void> loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        _firestore.collection('user').doc(widget.uid).get(),
        AppFirestore.posts().where('uid', isEqualTo: widget.uid).count().get(),
        AppFirestore.reels().where('uid', isEqualTo: widget.uid).count().get(),
      ]);

      final DocumentSnapshot userSnap = results[0] as DocumentSnapshot;

      final AggregateQuerySnapshot postsCountSnap =
          results[1] as AggregateQuerySnapshot;

      final AggregateQuerySnapshot reelsCountSnap =
          results[2] as AggregateQuerySnapshot;

      setState(() {
        userData = userSnap.data() as Map<String, dynamic>;
        totalPosts = postsCountSnap.count ?? 0;
        totalReels = reelsCountSnap.count ?? 0;
      });
    } catch (e) {
      showSnackBar(context, 'Failed to load profile data');
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildProfileHeader() {
    final currentUser =
        Provider.of<UserProvider>(context, listen: true).getUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          /// 👤 Avatar + stats + follow button
          Row(
            children: [
              if (userData['uid'] != currentUser?.uid)
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
                  child: userData['photoUrl'] == null ||
                          userData['photoUrl'].toString().isEmpty
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
              if (userData['uid'] == currentUser?.uid)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        transitionDuration: const Duration(milliseconds: 250),
                        pageBuilder: (_, __, ___) =>
                            ProfilePhotoViewer(imageUrl: currentUser?.photoUrl),
                      ),
                    );
                  },
                  child: currentUser?.photoUrl == null ||
                          currentUser?.photoUrl?.toString().isEmpty == true
                      ? const CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              AssetImage('assets/images/placeholder.jpg'),
                        )
                      : ProgressImageDots(
                          url: currentUser!.photoUrl!,
                          radius: 40,
                        ),
                ),

              /// 📊 Stats + Signout
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildStatColumn(totalPosts, 'posts'),
                        buildStatColumn(totalReels, 'reels'),
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
                                    await AuthMethods().signOut(context);
                                    Navigator.of(context, rootNavigator: true)
                                        .pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// 🧑 Username
          if (userData['uid'] != currentUser?.uid)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 15),
              child: Text(
                userData['username'] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),

          if (userData['uid'] == currentUser?.uid)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 15),
              child: Text(
                currentUser?.username ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),

          /// 📄 Bio (safe — never null)
          if (userData['uid'] != currentUser?.uid)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 1),
              child: userData['bio'] != null &&
                      userData['bio'].toString().isNotEmpty
                  ? Text(userData['bio'], overflow: TextOverflow.ellipsis)
                  : const SizedBox.shrink(),
            ),
          if (userData['uid'] == currentUser?.uid)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(top: 1),
              child: currentUser?.bio != null &&
                      currentUser?.bio?.toString().isNotEmpty == true
                  ? Text(currentUser!.bio!, overflow: TextOverflow.ellipsis)
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
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: StatefulBuilder(
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // const SizedBox(height: 8),

                    /// 🔥 CUSTOM SMALL HANDLE
                    // Container(
                    //   width: 32,
                    //   height: 3,
                    //   decoration: BoxDecoration(
                    //     color: Colors.white30,
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    // ),
                    // SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        color: mobileBackgroundColor,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize
                                  .min, // Minimizes the modal height
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: double.infinity,
                                ),
                                SizedBox(height: 10),

                                Text(
                                  "Pick and Preview Emoji",
                                  style: TextStyle(
                                    color: Colors.white,
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
                                        File(_selectedImage!
                                            .path), // Display selected image
                                        height: 150,
                                        width: 150,
                                      ),
                                SizedBox(height: 20),
                                AuthButton(
                                  color: blueColor,
                                  isLoading: false,
                                  onTap: _pickImage,
                                  // child: Text(
                                  //   "Pick an Image",
                                  //   style: TextStyle(color: Colors.white),
                                  // ),
                                  text: _selectedImage == null
                                      ? "Pick an Image"
                                      : "Select a different image",
                                ),
                                SizedBox(height: 20),

                                _isTaglinePosting
                                    ? CircularProgressIndicator(
                                        color: Colors.white70)
                                    : _selectedImage != null
                                        ? AuthButton(
                                            color: blueColor,
                                            isLoading: false,
                                            onTap: () async {
                                              setState(() {
                                                _isTaglinePosting = true;
                                              });

                                              await _updateUserEmoji(
                                                  _selectedImage);
                                              // await Future.delayed(Duration(seconds: 3));

                                              setState(() {
                                                _isTaglinePosting = false;
                                              });

                                              Navigator.of(context).pop();

                                              // Provider.of<NavigationProvider>(context,
                                              //         listen: false)
                                              //     .setPage(0);
                                              // Provider.of<NavigationProvider>(context,
                                              //         listen: false)
                                              //     .pageController!
                                              //     .jumpToPage(0);

                                              showSnackBar(context,
                                                  'Emoji updated successfully');
                                            },
                                            // : null, // Disable button if no image is selected
                                            text: "Set as Emoji",
                                          )
                                        : SizedBox.shrink(),
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showTaglineModal(BuildContext context) {
    TextEditingController taglineController = TextEditingController();

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // const SizedBox(height: 8),

                    // /// 🔥 CUSTOM SMALL HANDLE
                    // Container(
                    //   width: 32,
                    //   height: 3,
                    //   decoration: BoxDecoration(
                    //     color: Colors.white30,
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    // ),

                    // const SizedBox(height: 8),

                    /// 🔥 CONTENT
                    Expanded(
                      child: Container(
                        color: mobileBackgroundColor,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // SizedBox(height: 10),
                              const Text(
                                "Set your tagline",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFieldInput(
                                textInputType: TextInputType.text,
                                textEditingController: taglineController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\s{2,}'),
                                  )
                                ],
                                // controller: taglineController,
                                hintText: "Enter your new tagline",
                                // onChanged: (_) {},
                              ),
                              const SizedBox(height: 24),
                              AuthButton(
                                color: blueColor,
                                isLoading: _isTaglinePosting,
                                text: "Set as Tagline",
                                onTap: () async {
                                  final tagline = taglineController.text;

                                  setState(() {
                                    _isTaglinePosting = true;
                                  });

                                  await _updateUserTagline(tagline);

                                  setState(() {
                                    _isTaglinePosting = false;
                                  });

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _firestoreMethods = FirestoreMethods();
    loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
            backgroundColor: mobileBackgroundColor,
            body: const Center(
                child: CircularProgressIndicator(
              color: Colors.white70,
            )),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: mobileBackgroundColor,
              title: Row(
                children: [
                  /// LEFT → username + badge
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            userData['username'] ?? "",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// RIGHT → Switch group
                  if (FirebaseAuth.instance.currentUser!.uid == widget.uid)
                    GestureDetector(
                      onTap: () {
                        // showModalBottomSheet(
                        //   useRootNavigator: true,
                        //   context: context,
                        //   isScrollControlled: true,
                        //   showDragHandle: false, // ❌ disable default
                        //   backgroundColor: Colors.transparent,
                        //   builder: (_) => FractionallySizedBox(
                        //     heightFactor: 0.94,
                        //     child: Container(
                        //       decoration: BoxDecoration(
                        //         color: Color(0xFF1E1E1E),
                        //         borderRadius: BorderRadius.vertical(
                        //           top: Radius.circular(24),
                        //         ),
                        //       ),
                        //       child: Column(
                        //         mainAxisSize: MainAxisSize.min,
                        //         children: [
                        //           const SizedBox(height: 8),

                        //           /// 🔥 CUSTOM SMALL HANDLE
                        //           Container(
                        //             width: 32,
                        //             height: 3, // 👈 smaller height
                        //             decoration: BoxDecoration(
                        //               color: Colors.white30,
                        //               borderRadius: BorderRadius.circular(10),
                        //             ),
                        //           ),

                        //           const SizedBox(height: 8),

                        //           const Expanded(
                        //             child: GroupChooserScreen(),
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ),
                        // );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupChooserScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: const [
                          Text(
                            'Switch Group',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                          ),
                        ],
                      ),
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
                      child: _buildProfileHeader(),
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

                          tabs: [
                            Tab(
                              icon: PhosphorIcon(
                                PhosphorIcons.gridFour(),
                                size: 26,
                              ),
                            ),
                            Tab(
                              icon: PhosphorIcon(
                                PhosphorIcons.video(),
                                size: 26,
                              ),
                            ),
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
                    ProfilePostsGrid(
                      uid: widget.uid,
                      key: _postsKey,
                    ),
                    ProfileReelsGrid(uid: widget.uid, key: _reelsKey),
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

class _ProfilePostsGridState extends State<ProfilePostsGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _posts = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  Future<void> refreshPosts() async {
    _posts.clear();
    _lastDoc = null;
    _hasMore = true;
    _isLoading = true;

    if (mounted) setState(() {});

    await _loadInitialPosts();
  }

  // 🔹 Load first batch
  Future<void> _loadInitialPosts() async {
    final snap = await AppFirestore.posts()
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

    setState(() {
      _isFetchingMore = true;
    });

    final snap = await AppFirestore.posts()
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
    super.build(context);
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
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
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
                      padding: const EdgeInsets.only(
                          bottom: 1, right: 1, top: 0.5, left: 0.5),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(0), // 👈 adjust radius
                        child: CustomImageLoader(
                          imageUrl: data['postUrl'],
                        ),
                      ),
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
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(221, 63, 63, 63).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
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

class _ProfileReelsGridState extends State<ProfileReelsGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _reels = [];

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  DocumentSnapshot? _lastDoc;

  static const int _limit = 15;

  Future<void> refreshReels() async {
    _reels.clear();
    _lastDoc = null;
    _hasMore = true;
    _isLoading = true;

    if (mounted) setState(() {});

    await _loadInitialReels();
  }

  // 🔹 Initial load
  Future<void> _loadInitialReels() async {
    final snap = await AppFirestore.reels()
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

    setState(() {
      _isFetchingMore = true;
    });

    final snap = await AppFirestore.reels()
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
    super.build(context);
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
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final snap = _reels[index];
                  final data = snap.data() as Map<String, dynamic>;
                  // final reelId = snap.id;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SingleReelScreen(snap: data),
                        ),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 1, right: 1, top: 0.5, left: 0.5),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(0), // 👈 adjust radius
                            child: CustomImageLoader(
                              imageUrl: data['thumbnailUrl'],
                            ),
                          ),
                        ), // Placeholder thumbnail
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: PhosphorIcon(
                            PhosphorIcons.play(),
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ],
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
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(221, 63, 63, 63).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
