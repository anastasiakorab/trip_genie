import 'package:flutter/material.dart';

class AuthFormProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorText;

  void startLoading() {
    errorText = null;
    isLoading = true;
    notifyListeners();
  }

  void stopLoading(String? error) {
    isLoading = false;
    errorText = error;
    notifyListeners();
  }

  void clear() {
    isLoading = false;
    errorText = null;
    notifyListeners();
  }
  bool hidePassword = true;

void togglePasswordVisibility() {
  hidePassword = !hidePassword;
  notifyListeners();
}
}