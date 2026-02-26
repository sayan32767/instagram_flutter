import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_flutter/resources/auth_methods.dart';
import 'package:instagram_flutter/responsive/mobile_screen_layout.dart';
import 'package:instagram_flutter/responsive/responsive_layout_screen.dart';
import 'package:instagram_flutter/responsive/web_screen_layout.dart';
import 'package:instagram_flutter/screens/group_gate_screen.dart';
import 'package:instagram_flutter/screens/signup_screen.dart';
import 'package:instagram_flutter/utils/colors.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:instagram_flutter/widgets/text_field_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future loginUser() async {
    setState(() {
      _isLoading = true;
    });
    String email = _emailController.text;
    String password = _passwordController.text;
    String res =
        await AuthMethods().loginUser(email: email, password: password);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (res != 'success') {
      showSnackBar(context, 'Failed to login, please check your credentials');
    } else {
      // Navigator.of(context).pushReplacement(MaterialPageRoute(
      //     builder: (context) => const ResponsiveLayout(
      //         webScreenLayout: WebScreenLayout(),
      //         mobileScreenLayout: MobileScreenLayout())));
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const GroupGateScreen(),
      ));
      ////////////MAYBE NEED TO CHANGE HERE
    }
  }

  void navigateToSignup() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/ic_instagram.svg',
                        height: 64,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 64),
                      TextFieldInput(
                        textEditingController: _emailController,
                        textInputType: TextInputType.emailAddress,
                        hintText: 'Enter your email',
                      ),
                      const SizedBox(height: 12),
                      TextFieldInput(
                        textEditingController: _passwordController,
                        textInputType: TextInputType.visiblePassword,
                        isPass: true,
                        hintText: 'Enter your password',
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: loginUser,
                        child: Container(
                          height: 60,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: const ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40)),
                            ),
                            color: blueColor,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white70,
                                )
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          GestureDetector(
                            onTap: navigateToSignup,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'Signup',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
