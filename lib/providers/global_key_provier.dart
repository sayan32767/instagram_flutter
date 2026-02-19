import 'package:flutter/material.dart';

class GlobalKeyProvier with ChangeNotifier {
  GlobalKey? _globalKey;

  GlobalKey? get globalKey {
    return _globalKey;
  }

  void setGlobalKey(GlobalKey globalKey) {
    _globalKey = globalKey;
  }
}
