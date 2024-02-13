import 'package:flutter/material.dart';

class AttendanceViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get getIsLoadingStatus => _isLoading;
  setIsLoadingStatus(bool status) {
    _isLoading = status;
    notifyListeners();
  }
}
