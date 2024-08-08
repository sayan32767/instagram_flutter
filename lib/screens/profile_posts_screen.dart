import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/widgets/post_card.dart';

class ProfileScreenPosts extends StatefulWidget {
  final String uid;
  final String url;

  ProfileScreenPosts({super.key, required this.uid, required this.url});

  @override
  State<ProfileScreenPosts> createState() => _ProfileScreenPostsState();
}

class _ProfileScreenPostsState extends State<ProfileScreenPosts> {
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot>? _documents;

  String? _scrollToUrl;

  @override
  void initState() {
    super.initState();
    _scrollToUrl = widget.url;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          
          stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: widget.uid)
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              // child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasData) {
            _documents = snapshot.data!.docs;

            final index = _documents!.indexWhere(
              (doc) => doc['postUrl'] == _scrollToUrl,
            );

            if (index != -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent * (index / _documents!.length));
              });
            }
          }
      
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: false,
                  floating: true,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    title: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SvgPicture.asset(
                        'assets/images/ic_instagram.svg',
                        color: primaryColor,
                        
                      ),
                    ),
                    background: Container(
                      color: mobileBackgroundColor,
                    ),
                  ),
                  backgroundColor: mobileBackgroundColor,
                  toolbarHeight: 70
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      child: PostCard(
                        snap: snapshot.data!.docs[index].data(),
                      ),
                    ),
                    childCount: snapshot.data!.docs.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
