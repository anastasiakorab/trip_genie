import 'package:flutter/material.dart';

class WebCameraProvider extends ChangeNotifier {
  bool isCameraReady = false;
  String? errorMessage;

  void setReady(bool value) {
    isCameraReady = value;
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    isCameraReady = false;
    notifyListeners();
  }

  void reset() {
    isCameraReady = false;
    errorMessage = null;
    notifyListeners();
  }
}