import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();

  final XFile? _file = await _imagePicker.pickImage(
    source: source,
    maxWidth: 1080,
    maxHeight: 1080,
  );

  if (_file != null) {
    return await _file.readAsBytes();
  }
  print('no image selected');
  return null;
}

showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(content))
  );
}
