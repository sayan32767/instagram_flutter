import 'package:flutter/material.dart';

class PlayerStateProvider with ChangeNotifier {
  String? _url;
  String? _uid;
  bool _isPlaying = false;
  bool _isLoading = false;

  String? get url {
    return _url;
  }

  String? get uid {
    return _uid;
  }

  bool get isPlaying {
    return _isPlaying;
  }

  bool get isLoading => _isLoading;

  void setPlayStatus(bool status) {
    _isPlaying = status;
    notifyListeners();
  }

  void setLoadingStatus(bool status) {
    _isLoading = status;
    notifyListeners();
  }

  void setUrl(String? url) {
    _url = url;
    notifyListeners();
  }

  void setUid(String? uid) {
    _uid = uid;
    notifyListeners();
  }
}
