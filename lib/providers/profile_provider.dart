import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  Uint8List? profileImageBytes;
  bool isUploadingImage = false;

  void setProfileImage(Uint8List imageBytes) {
    profileImageBytes = imageBytes;
    notifyListeners();
  }

  void setUploading(bool value) {
    isUploadingImage = value;
    notifyListeners();
  }

  void clearProfileImage() {
    profileImageBytes = null;
    notifyListeners();
  }
  bool notificationsEnabled = true;

void toggleNotifications(bool value) {
  notificationsEnabled = value;
  notifyListeners();
}
bool isSaving = false;
bool hidePassword = true;

void setSaving(bool value) {
  isSaving = value;
  notifyListeners();
}

void togglePasswordVisibility() {
  hidePassword = !hidePassword;
  notifyListeners();
}
}