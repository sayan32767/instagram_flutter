import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool isPass;
  final TextInputType textInputType;
  final String hintText;
  final TextInputFormatter? textInputFormatter;
  final List<TextInputFormatter>? inputFormatters; // ⭐ NEW

  const TextFieldInput(
      {super.key,
      required this.textEditingController,
      this.isPass = false,
      required this.textInputType,
      required this.hintText,
      this.textInputFormatter,
      this.inputFormatters}); // ⭐ NEW

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: textEditingController,
      inputFormatters: inputFormatters != null ? inputFormatters! : null,
      decoration: InputDecoration(
          filled: true,
          border: inputBorder,
          focusedBorder: inputBorder,
          enabledBorder: inputBorder,
          hintText: hintText,
          contentPadding: const EdgeInsets.all(8)),
      obscureText: isPass,
      keyboardType: textInputType,
    );
  }
}
