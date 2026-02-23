import 'package:flutter/widgets.dart';

class GroupProvider extends ChangeNotifier {
  String? _groupId;

  String? get groupId => _groupId;

  void setGroup(String id) {
    _groupId = id;
    notifyListeners();
  }
}
