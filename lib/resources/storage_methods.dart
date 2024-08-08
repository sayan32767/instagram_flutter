import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

class StorageMethods {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<dynamic> uploadImageToStorage(String childName, Uint8List? file, bool isPost) async {

    if (file == null) return file;

    // Decode
    img.Image? image = img.decodeImage(file);

    if (image == null) {
      return null;
    }

    final jpgImage = img.encodeJpg(image);

    final compressedImage = await FlutterImageCompress.compressWithList(
      jpgImage,
      quality: 75,
      format: CompressFormat.jpeg,
    );

    Reference ref = _storage.ref().child(childName).child(_auth.currentUser!.uid);

    if (isPost) {
      String id = const Uuid().v1();
      ref = ref.child(id);
    }

    UploadTask uploadTask =  ref.putData(compressedImage, SettableMetadata(contentType: 'image/jpeg'));

    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }
}
