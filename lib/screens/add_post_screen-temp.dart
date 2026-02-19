// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:instagram_flutter/models/user.dart';
// import 'package:instagram_flutter/providers/user_provider.dart';
// import 'package:instagram_flutter/resources/firestore_methods.dart';
// import 'package:instagram_flutter/utils/colors.dart';
// import 'package:instagram_flutter/utils/utils.dart';
// import 'package:instagram_flutter/widgets/progress_image_dots.dart';
// import 'package:provider/provider.dart';
// import 'package:http/http.dart' as http;

// class AddPostScreen extends StatefulWidget {
//   const AddPostScreen({super.key});

//   @override
//   State<AddPostScreen> createState() => _AddPostScreenState();
// }

// class _AddPostScreenState extends State<AddPostScreen> {
//   Uint8List? _file;
//   final TextEditingController _descriptionController = TextEditingController();
//   bool _isLoading = false;
//   String? resultMessage;

//   void clearImage() {
//     setState(() {
//       _file = null;
//     });
//   }

//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     _descriptionController.dispose();
//   }

//   Future generateImage() async {

//     try {
//       final response = await http.get(Uri.parse(
//         'http://127.0.0.1:8080/generate'
//       ));

//       if (response.statusCode == 200) {
//         // Parse the JSON response
//         final Map<String, dynamic> data = jsonDecode(response.body);
//         setState(() {
//           resultMessage = data['data']['media'][0]['url'] ?? 'No message';
//         });
//       } else {
//         setState(() {
//           resultMessage = 'Failed to load data';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         resultMessage = 'Error: $e';
//       });
//     }

//   }

//   void postImage(String uid, String username, String profImage) async {
//     setState(() {
//       _isLoading = true;
//     });
//     try {
//       String res = await FirestoreMethods().uploadPost(
//           _descriptionController.text, _file!, uid, username, profImage);
//       if (res == 'success') {
//         setState(() {
//           _isLoading = false;
//         });
//         showSnackBar(context, 'Posted');
//         clearImage();
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         showSnackBar(context, res);
//         clearImage();
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       showSnackBar(context, e.toString());
//     }
//   }

//   _selectImage(BuildContext context) async {
//     return showDialog(
//         context: context,
//         builder: (context) {
//           return SimpleDialog(
//             title: const Text('Create a Post'),
//             children: [
//               SimpleDialogOption(
//                 padding: const EdgeInsets.all(20),
//                 child: const Text('Take a Photo'),
//                 onPressed: () async {
//                   Navigator.of(context).pop();
//                   Uint8List file = await pickImage(ImageSource.camera);
//                   setState(() {
//                     _file = file;
//                   });
//                 },
//               ),
//               SimpleDialogOption(
//                 padding: const EdgeInsets.all(20),
//                 child: const Text('Choose From Gallery'),
//                 onPressed: () async {
//                   Navigator.of(context).pop();
//                   Uint8List file = await pickImage(ImageSource.gallery);
//                   setState(() {
//                     _file = file;
//                   });
//                 },
//               ),
//               SimpleDialogOption(
//                 padding: const EdgeInsets.all(20),
//                 child: const Text('Cancel'),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//               )
//             ],
//           );
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final User user = Provider.of<UserProvider>(context).getUser;

//     return _file == null
//         ? Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Scaffold(
//               body: Column(
//                 children: [
//                   IconButton(
//                     onPressed: () => _selectImage(context),
//                     icon: Icon(Icons.upload),
//                   ),
//                   TextButton(
//                     onPressed: () {

//                       generateImage();

//                     },
//                     child: Text('HI'),
//                   ),

//                   Text(
//                     resultMessage ?? ''
//                   )

//                 ],
//               ),
//             ),
//           )
//         : Scaffold(
//             appBar: AppBar(
//               backgroundColor: mobileBackgroundColor,
//               leading: IconButton(
//                 onPressed: clearImage,
//                 icon: Icon(Icons.arrow_back),
//               ),
//               title: const Text('Post to'),
//               centerTitle: false,
//               actions: [
//                 !_isLoading
//                     ? TextButton(
//                         onPressed: () async {
//                           setState(() {
//                             _isLoading = true;
//                           });
//                           await Future.delayed(Duration(seconds: 2));
//                           postImage(
//                               user.uid, user.username, user.photoUrl ?? '');
//                         },
//                         child: const Text(
//                           'Post',
//                           style: TextStyle(
//                             color: Colors.blueAccent,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ))
//                     : Container()
//               ],
//             ),
//             body: Column(
//               children: [
//                 _isLoading
//                     ? const LinearProgressIndicator(
//                         color: blueColor,
//                       )
//                     : Padding(
//                         padding: const EdgeInsets.only(top: 0),
//                       ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     user.photoUrl == null
//                         ? CircleAvatar(
//                             radius: 16,
//                             backgroundImage:
//                                 AssetImage('assets/images/placeholder.jpg'),
//                             backgroundColor:
//                                 const Color.fromARGB(255, 23, 13, 13),
//                           )
//                         : ProgressImageDots(url: user.photoUrl!),
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width * 0.45,
//                       child: TextField(
//                         controller: _descriptionController,
//                         decoration: const InputDecoration(
//                             hintText: 'Write a caption...',
//                             border: InputBorder.none),
//                         maxLines: 8,
//                       ),
//                     ),
//                     SizedBox(
//                       height: 45,
//                       width: 45,
//                       child: AspectRatio(
//                         aspectRatio: 487 / 451,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             image: DecorationImage(
//                               image: MemoryImage(_file!),
//                               fit: BoxFit.fill,
//                               alignment: FractionalOffset.topCenter,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const Divider(),
//                   ],
//                 )
//               ],
//             ),
//           );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/models/user.dart';
import 'package:instagram_flutter/providers/global_key_provier.dart';
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/resources/firestore_methods.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/global_variables.dart';
import 'package:instagram_flutter/utils/image_cache_manager.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/instagram_searchbar.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  late TextEditingController _controller;
  String? resultUrl;
  bool isLoading = false;
  bool isValidated = false;

  bool buttonIsLoading = false;

  Uint8List? _file;
  XFile? _videoFile;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  String? resultMessage;

  @override
  void dispose() {
    // TODO: implement dispose
    _descriptionController.dispose();
    _controller.dispose();
    _videoController?.dispose(); // null-safe.dispose();
    super.dispose();
  }

  void clearImage() {
    setState(() {
      _file = null;
      _videoFile = null;
    });
  }

  void selectGeneratedImage(String url) async {
    setState(() {
      buttonIsLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          buttonIsLoading = false;
        });
        final Uint8List bytes = response.bodyBytes;
        Uint8List file = bytes;
        setState(() {
          _file = file;
        });
      } else {
        setState(() {
          buttonIsLoading = false;
        });
        showSnackBar(context, 'Failed, please try again!');
      }
    } catch (_) {
      setState(() {
        buttonIsLoading = false;
      });
      showSnackBar(context, 'Failed, please try again!');
    } finally {
      setState(() {
        buttonIsLoading = false;
      });
    }
  }

  void postImage(String uid, String username, String profImage) async {
    setState(() {
      _isLoading = true;
    });
    try {
      String res = await FirestoreMethods().uploadPost(
          _descriptionController.text, _file!, uid, username, profImage);
      if (res == 'success') {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(context, 'Posted');
        clearImage();

        Provider.of<NavigationProvider>(context, listen: false).setPage(0);
        Provider.of<NavigationProvider>(context, listen: false)
            .pageController!
            .jumpToPage(0);
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
        });
        showSnackBar(context, res);
        clearImage();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showSnackBar(context, e.toString());
    }
  }

  _selectImage(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Create a Post'),
            children: [
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Take a Photo'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(ImageSource.camera);
                  setState(() {
                    _file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Choose From Gallery'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(ImageSource.gallery);
                  setState(() {
                    _file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  // REEL METHOD
  _selectVideo(BuildContext context) async {
    // Uint8List? file = await pickVideo(ImageSource.gallery);
    // setState(() {
    //   _file = file;
    // });
    XFile? file = await pickVideo(ImageSource.gallery);
    if (file != null) {
      setState(() {
        _videoFile = file;
      });
      await _initializeVideo();
      // Handle the video file as needed
      // For example, you can upload it to your server or display it in the UI
    } else {
      showSnackBar(context, 'No video selected');
    }
  }

  // REEL UPLOAD
  Future<void> _uploadReel(
      String uid, String username, String profImage) async {
    if (_videoFile == null) return;

    setState(() => _isLoading = true);

    String res = await FirestoreMethods().uploadReel(
        _descriptionController.text,
        _videoFile!,
        uid,
        username,
        profImage,
        [] as Uint8List);

    setState(() => _isLoading = false);

    if (res == "success") {
      clearImage();

      if (mounted) {
        Provider.of<NavigationProvider>(context, listen: false).setPage(0);
        Provider.of<NavigationProvider>(context, listen: false)
            .pageController!
            .jumpToPage(0);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reel uploaded sucessfully")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
    }
  }

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(_videoFile!.path));

    await _videoController!.initialize();

    _videoController!
      ..setLooping(true)
      ..setVolume(0)
      ..play();

    setState(() {});
  }

  Future generateImage() async {
    setState(() {
      isLoading = true;
    });

    final String prompt = _controller.text.trim();

    _controller.text = "";

    if (prompt.isEmpty) {
      setState(() {
        isLoading = false;
      });

      return;
    }

    final queryParams = {
      'prompt': prompt,
    };

    final String baseUrl = dotenv.get('BASE_URL', fallback: '');

    try {
      final uri =
          Uri.parse('$baseUrl/generate').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          resultUrl = data['data']['media'][0]['url'];
          isValidated = true;
        });
      } else if (response.statusCode == 429) {
        setState(() {
          isValidated = false;
          resultUrl = 'Please try again after 1 minute';
        });
      } else {
        setState(() {
          resultUrl = 'Failed to load data';
          isValidated = false;
        });
      }
    } catch (_) {
      setState(() {
        resultUrl = 'Failed to load data';
        isValidated = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _descriptionController = TextEditingController();
    _controller = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final User user = Provider.of<UserProvider>(context).getUser!;

    return _file == null && _videoFile == null
        ? Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Stack(children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.07),

                      // Row(
                      //   children: [
                      //     Text('Pick an Image'),
                      //     Icon(
                      //       // onPressed: () => _selectImage(context),
                      //       Icons.upload,
                      //     ),
                      //   ],
                      // ),

                      Row(
                        children: [
                          InstagramSearchBar(
                            assetPath: 'assets/images/search.svg',
                            controller: _controller,
                            onChanged: (_) {},
                            hintText: 'Generate an Image...',
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          !isLoading
                              ? GenerateButton(
                                  onPressed: () {
                                    generateImage();
                                  },
                                )
                              : Container()
                        ],
                      ),

                      SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.02),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: GenerateButton(
                          hintText: 'Pick an image from gallery...',
                          onPressed: () {
                            _selectImage(context);
                          },
                        ),
                      ),

                      // SizedBox(
                      //     height: MediaQuery.sizeOf(context).height * 0.02),

                      // Align(
                      //   alignment: Alignment.centerLeft,
                      //   child: GenerateButton(
                      //     hintText: 'Pick a video from gallery...',
                      //     onPressed: () {
                      //       _selectVideo(context);
                      //     },
                      //   ),
                      // ),

                      SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.04),

                      isLoading
                          ? Container(
                              height: MediaQuery.sizeOf(context).height * 0.4,
                              width: MediaQuery.sizeOf(context).height * 0.4,
                              decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.grey[400])))
                          : resultUrl != null && isValidated
                              ? Container(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.4,
                                  width:
                                      MediaQuery.sizeOf(context).height * 0.4,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: CachedNetworkImage(
                                    imageUrl: resultUrl!,
                                    fit: BoxFit.cover,
                                    cacheManager: InstaCacheManager(),
                                  ),
                                )
                              : resultUrl != null && !isValidated
                                  ? Container(
                                      child: Center(
                                        child: Text(resultUrl!),
                                      ),
                                    )
                                  : Container(),
                    ],
                  ),
                ),
                resultUrl != null && isValidated
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: !buttonIsLoading
                                ? GenerateButton(
                                    hintText: 'Continue with this image...',
                                    onPressed: () {
                                      setState(() {
                                        buttonIsLoading = true;
                                      });
                                      selectGeneratedImage(resultUrl!);
                                    },
                                  )
                                : SizedBox(
                                    height: 60,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.grey[400])),
                                  )),
                      )
                    : Container(),
              ]),
            ),
          )
        : _videoFile == null
            ? Scaffold(
                appBar: AppBar(
                  backgroundColor: mobileBackgroundColor,
                  leading: IconButton(
                    onPressed: clearImage,
                    icon: Icon(Icons.arrow_back),
                  ),
                  title: const Text('Post to'),
                  centerTitle: false,
                  actions: [
                    !_isLoading
                        ? TextButton(
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              await Future.delayed(Duration(seconds: 2));
                              postImage(
                                  user.uid, user.username, user.photoUrl ?? '');
                            },
                            child: const Text(
                              'Post',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ))
                        : Container()
                  ],
                ),
                body: Column(
                  children: [
                    _isLoading
                        ? const LinearProgressIndicator(
                            color: blueColor,
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 0),
                          ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        user.photoUrl == null
                            ? CircleAvatar(
                                radius: 16,
                                backgroundImage:
                                    AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor:
                                    const Color.fromARGB(255, 23, 13, 13),
                              )
                            : ProgressImageDots(url: user.photoUrl!),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                                hintText: 'Write a caption...',
                                border: InputBorder.none),
                            maxLines: 8,
                          ),
                        ),
                        SizedBox(
                          height: 45,
                          width: 45,
                          child: AspectRatio(
                            aspectRatio: 487 / 451,
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: MemoryImage(_file!),
                                  fit: BoxFit.fill,
                                  alignment: FractionalOffset.topCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(),
                      ],
                    )
                  ],
                ),
              )
            : Scaffold(
                backgroundColor: mobileBackgroundColor,
                appBar: AppBar(
                  backgroundColor: mobileBackgroundColor,
                  leading: IconButton(
                    onPressed: clearImage,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  title: const Text('Post Reel'),
                  actions: [
                    _isLoading
                        ? Container()
                        : TextButton(
                            onPressed: () async {
                              if (_isLoading) return;

                              setState(() {
                                _isLoading = true;
                              });
                              await Future.delayed(Duration(seconds: 2));
                              _uploadReel(
                                  user.uid, user.username, user.photoUrl ?? '');
                            },
                            child: const Text(
                              "Post",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                  ],
                ),
                body: Column(
                  children: [
                    _isLoading
                        ? const LinearProgressIndicator(
                            color: blueColor,
                          )
                        : const Padding(
                            padding: EdgeInsets.only(top: 0),
                          ),

                    /// 📝 CAPTION FIELD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Write a caption...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 🎬 VIDEO PREVIEW
                    Center(
                      child: SizedBox(
                        height: 400, // 👈 control size here
                        child: _videoController != null &&
                                _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              );
  }
}

// Make sure to add this package in your pubspec.yaml file
class GenerateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? hintText;

  const GenerateButton({Key? key, this.onPressed, this.hintText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 25, 25, 25), // Button color
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        hintText ?? 'Generate',
        style: TextStyle(
          color: Colors.grey[400], // Text color
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
