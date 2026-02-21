import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/group_gate_screen.dart';
import 'package:instagram_flutter/screens/login_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  Uint8List? _image;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    if (RegExp(r'^[._]').hasMatch(value) || RegExp(r'[._]$').hasMatch(value)) {
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
    });
  }

  void signUpUser() async {
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

    String res =
        await AuthMethods().checkAndAddUsername(_usernameController.text);

    if (res != 'success') {
      setState(() {
        _isLoading = false;
      });
      showSnackBar(
          context, 'Username updating failed, please choose another username');
    } else {
      String res = await AuthMethods().signUpUser(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          file: _image);
      setState(() {
        _isLoading = false;
      });
      if (res != 'success') {
        showSnackBar(context, 'Failed to sign up, please try again');
      } else {
        // Navigator.of(context).pushReplacement(MaterialPageRoute(
        //     builder: (context) => const ResponsiveLayout(
        //         webScreenLayout: WebScreenLayout(),
        //         mobileScreenLayout: MobileScreenLayout())));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const GroupGateScreen(),
          ),
        );
      }
    }
  }

  void navigateToLogin() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(flex: 2, child: Container()),
          SvgPicture.asset(
            'assets/images/ic_instagram.svg',
            height: 64,
            color: primaryColor,
          ),
          const SizedBox(height: 64),
          Stack(
            children: [
              _image != null
                  ? CircleAvatar(
                      radius: 64, backgroundImage: MemoryImage(_image!))
                  : const CircleAvatar(
                      radius: 64,
                      backgroundImage:
                          AssetImage('assets/images/placeholder.jpg'),
                    ),
              Positioned(
                  bottom: -10,
                  left: 80,
                  child: IconButton(
                      onPressed: selectImage,
                      icon: const Icon(Icons.add_a_photo)))
            ],
          ),
          const SizedBox(height: 24),
          TextFieldInput(
              textEditingController: _usernameController,
              textInputFormatter: LowerCaseTextFormatter(),
              textInputType: TextInputType.text,
              hintText: 'Enter your username'),
          const SizedBox(height: 24),
          TextFieldInput(
              textEditingController: _emailController,
              textInputType: TextInputType.emailAddress,
              hintText: 'Enter your email'),
          const SizedBox(height: 24),
          TextFieldInput(
              textEditingController: _passwordController,
              textInputType: TextInputType.visiblePassword,
              isPass: true,
              hintText: 'Enter your password'),
          const SizedBox(height: 24),
          TextFieldInput(
              textEditingController: _bioController,
              textInputType: TextInputType.text,
              hintText: 'Enter your bio'),
          const SizedBox(height: 24),
          InkWell(
            onTap: signUpUser,
            child: Container(
              width: double.infinity,
              height: 60,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  color: blueColor),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: Colors.white70,
                    ))
                  : const Text(
                      'Signup',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            flex: 2,
            child: Container(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text('Already have an account?'),
              ),
              GestureDetector(
                onTap: navigateToLogin,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    )));
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
    final filteredText = newValue.text.replaceAll(' ', '').toLowerCase();
    return newValue.copyWith(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}
