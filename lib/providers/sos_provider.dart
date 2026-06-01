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
