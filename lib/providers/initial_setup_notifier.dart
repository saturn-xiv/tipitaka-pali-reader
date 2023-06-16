import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class InitialSetupNotifier extends ChangeNotifier {
  String _status = '';

  String get status => _status;

  set status(String message) {
    _status = message;
    notifyListeners();
  }
}
