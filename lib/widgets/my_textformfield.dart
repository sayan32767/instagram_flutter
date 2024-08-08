import 'package:flutter/material.dart';
import 'package:instagram_flutter/utils/colors.dart';

class MyTextformfield extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const MyTextformfield({super.key, required this.controller, required this.onChanged});

  @override
  State<MyTextformfield> createState() => _MyTextformfieldState();
}

class _MyTextformfieldState extends State<MyTextformfield> {
  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context)
    );
    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: mobileBackgroundColor,
        border: inputBorder,
        focusedBorder: inputBorder,
        enabledBorder: inputBorder,
        hintText: 'Search for a user...',
        contentPadding: const EdgeInsets.all(8)
      ),
      keyboardType: TextInputType.text
    );
  }
}
