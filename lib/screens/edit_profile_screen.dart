import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/screens/profile_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/progress_image_dots.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';

class EditProfileScreen extends StatefulWidget {
  dynamic userData;
  EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
  Uint8List? _image;
  bool clickFlag = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _bioController = TextEditingController(
      text: widget.userData == null ? '' : widget.userData['bio'],
    );

    _usernameController = TextEditingController(
      text: widget.userData == null ? '' : widget.userData['username'],
    );

  }

  @override
  void dispose() {
    _bioController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 1 || value.length > 30) {
      return 'Username must be between 1 and 30 characters';
    }
    if (RegExp(r'^[._]').hasMatch(value) ||
        RegExp(r'[._]$').hasMatch(value)) {
      return 'Username cannot start or end with a period or underscore';
    }
    if (RegExp(r'[\.\.]+').hasMatch(value)) {
      return 'Username cannot have consecutive periods';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, periods, and underscores';
    }
    return null;
  }

  void selectImage() async {
    Uint8List? img = await pickImage(ImageSource.gallery);
    
    if (img == null) return;
    setState(() {
      _image = img;
      clickFlag = true;
    });
  }

  void updateUser() async {
    setState(() {
      _isLoading = true;
    });

    String? validation = validator(_usernameController.text);

    if (validation != null) {
      showSnackBar(context, validation);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String res = await AuthMethods().checkAndAddUsername(_usernameController.text);

    if (res != 'success') {
      setState(() {
        _isLoading = false;
      });
      showSnackBar(context, res);
    } else {
      String res = await AuthMethods().updateUser(
      username: _usernameController.text,
      bio: _bioController.text,
      file: _image,
      clickFlag: clickFlag,
    );
    setState(() {
      _isLoading = false;
    });
    if (res != 'success') {
      showSnackBar(context, res);
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ProfileScreen(uid: widget.userData['uid'])));
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const ResponsiveLayout(webScreenLayout: WebScreenLayout(), mobileScreenLayout: MobileScreenLayout())));
    }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: Text('Edit Profile'),
        actions: [],
      ),

      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(flex: 2, child: Container()),
              Stack(
                children: [
                   _image != null ?
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: MemoryImage(_image!)
                  )
                  : clickFlag ? CircleAvatar(
                    radius: 64,
                    backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                    backgroundColor: Colors.grey[300],
                  ) : widget.userData == null ? CircleAvatar(
                    radius: 64,
                    backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                    backgroundColor: Colors.grey[300],
                  ) : widget.userData['photoUrl'] == null ?
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                    backgroundColor: Colors.grey[300],
                  ) : ProgressImageDots(url: widget.userData['photoUrl'], radius: 64), 
                  Positioned(
                    bottom: -10,
                    left: 80,
                    child: IconButton(
                      onPressed: selectImage,
                      icon: const Icon(Icons.add_a_photo)
                    )
                  )
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() {
                    clickFlag = true;
                    _image = null;
                  });
                },
                child: Text(
                  'Remove photo',
                  style: TextStyle(
                    color: blueColor,
                  ),
                )
              ),
              TextFieldInput(
                textEditingController: _usernameController,
                textInputFormatter: LowerCaseTextFormatter(),
                textInputType: TextInputType.text,
                hintText: 'Enter new username'
              ),
              const SizedBox(height: 24),
              
              TextFieldInput(
                textEditingController: _bioController,
                textInputType: TextInputType.text,
                hintText: 'Enter new bio'
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: updateUser,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    color: blueColor
                  ),
                  child: _isLoading ? const Center(child: CircularProgressIndicator()) : const Text(
                    'Update Details',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                flex: 2,
                child: Container(),
              ),
            ],
          ),
        )
      )
    );
  }
}

// class LowerCaseTextFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     return newValue.copyWith(
//       text: newValue.text.toLowerCase(),
//       selection: newValue.selection,
//     );
//   }
// }


class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    final filteredText = newValue.text
        .replaceAll(' ', '')
        .toLowerCase();
    return newValue.copyWith(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}
