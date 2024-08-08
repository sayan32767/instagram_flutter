import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final TextInputType textInputType;
  final String hintText;
  final TextInputFormatter? textInputFormatter;

  const TextFieldInput({super.key, required this.textEditingController, this.isPass = false, required this.textInputType, required this.hintText, this.textInputFormatter});

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: Divider.createBorderSide(context)
    );
    return TextField(
      controller: textEditingController,
      inputFormatters: textInputFormatter != null ? [textInputFormatter!] : [],
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
