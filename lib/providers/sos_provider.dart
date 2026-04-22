import 'package:flutter/material.dart';

class SOSProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> sendSOS() async {
    _isLoading = true;
    notifyListeners();
    
    // Şimdilik sadece simüle ediyoruz
    await Future.delayed(const Duration(seconds: 2));
    // ignore: avoid_print
    print("SOS Gönderildi!");
    
    _isLoading = false;
    notifyListeners();
  }
}