import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instagram_flutter/utils/colors.dart';

class MyTextformfield extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final String? hintText;
  final Color? color;
  final FocusNode? focusNode; // ⭐ NEW
  final void Function(String)? onFieldSubmitted; // ⭐ NEW
  final List<TextInputFormatter>? inputFormatters; // ⭐ NEW

  const MyTextformfield({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode, // ⭐ NEW
    this.onFieldSubmitted, // ⭐ NEW
    this.hintText,
    this.color,
    this.inputFormatters, // ⭐ NEW
  });

  @override
  State<MyTextformfield> createState() => _MyTextformfieldState();
}

class _MyTextformfieldState extends State<MyTextformfield> {
  Color computeColor(Color color) {
    // Calculate the brightness of the color
    double brightness = color.computeLuminance();

    // If brightness is high, use a darker color for the search bar (e.g., matte black or gray)
    // If brightness is low, use a lighter color for the search bar (e.g., matte white or light gray)
    return brightness > 0.5
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.3);
  }

  Color getTextColor(Color backgroundColor) {
    // Calculate the brightness of the color
    double brightness = backgroundColor.computeLuminance();

    // If the background color is bright, return a dark text color, otherwise return a light text color
    return brightness < 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide:
          Divider.createBorderSide(context, color: widget.color ?? null),
    );
    return TextFormField(
        inputFormatters:
            widget.inputFormatters != null ? widget.inputFormatters! : null,
        onFieldSubmitted: widget.onFieldSubmitted, // ⭐ NEW
        textInputAction: TextInputAction.search,
        controller: widget.controller,
        focusNode: widget.focusNode, // ⭐ NEW
        onChanged: widget.onChanged,
        decoration: InputDecoration(
            filled: true,
            fillColor: widget.color == null
                ? Colors.grey[800]
                : computeColor(widget.color!),
            border: inputBorder,
            focusedBorder: inputBorder,
            enabledBorder: inputBorder,
            hintText: widget.hintText ?? 'Search for a user...',
            contentPadding: const EdgeInsets.all(8),
            hintStyle: TextStyle(
                color: widget.color == null
                    ? Colors.white
                    : getTextColor(widget.color!))),
        style: TextStyle(
            color: widget.color == null
                ? Colors.white
                : getTextColor(widget.color!)),
        keyboardType: TextInputType.text);
  }
}
