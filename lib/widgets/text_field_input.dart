import 'package:flutter/material.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final TextInputType textInputType;
  final String hintText;

  const TextFieldInput({super.key, required this.textEditingController, this.isPass = false, required this.textInputType, required this.hintText});

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context)
    );
    return TextField(
      controller: textEditingController,
      decoration: InputDecoration(
        filled: true,
        border: inputBorder,
        focusedBorder: inputBorder,
        enabledBorder: inputBorder,
        hintText: hintText,
        contentPadding: const EdgeInsets.all(8)
      ),
      obscureText: isPass,
      keyboardType: textInputType,
    );
  }
}
