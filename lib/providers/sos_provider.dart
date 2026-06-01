<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../emergency/app_to_app_alert_service.dart';

class SOSProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> sendSOS() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AppToAppAlertService.sendEmergencyAlert();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
=======
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
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
