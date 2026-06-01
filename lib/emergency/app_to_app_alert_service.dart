import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'emergency_app_settings_store.dart';
import 'emergency_notification_service.dart';
import 'incoming_alert_ui.dart';
import 'incoming_emergency_alert.dart';
import '../firebase_options.dart';

class AppToAppAlertService {
  AppToAppAlertService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _listener;
  static bool _firebaseReady = false;

  static Future<bool> initializeFirebase() async {
    if (_firebaseReady) {
      return true;
    }

    try {
      if (DefaultFirebaseOptions.isConfigured) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      return true;
    } catch (error) {
      debugPrint('Firebase is not configured yet: $error');
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    await EmergencyNotificationService.requestPermission();
    return _requestLocationPermission();
  }

  static Future<void> sendEmergencyAlert() async {
    final settings = await EmergencyAppSettingsStore.load();
    if (!settings.isReady) {
      throw StateError('Eşleşme kodu ve isim ayarlanmamış.');
    }
    if (settings.mode != EmergencyAppMode.patient) {
      throw StateError('Acil durum göndermek için Hasta modu seçilmeli.');
    }
    if (!await initializeFirebase()) {
      throw StateError('Firebase bağlantısı yapılandırılmamış.');
    }

    final location = await _tryGetLocation();
    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('emergency_groups')
        .doc(settings.pairingCode)
        .collection('alerts')
        .add({
          'patientName': settings.displayName,
          'pairingCode': settings.pairingCode,
          'hasLocation': location.hasLocation,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
          'mapsUrl': location.mapsUrl,
          'locationError': location.errorMessage,
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtMillis': now.millisecondsSinceEpoch,
        });
  }

  static Future<void> startResponderListener() async {
    await _listener?.cancel();

    final settings = await EmergencyAppSettingsStore.load();
    if (settings.mode != EmergencyAppMode.responder || !settings.isReady) {
      return;
    }
    if (!await initializeFirebase()) {
      return;
    }

    final listenFrom = DateTime.now().millisecondsSinceEpoch;
    _listener = FirebaseFirestore.instance
        .collection('emergency_groups')
        .doc(settings.pairingCode)
        .collection('alerts')
        .where('createdAtMillis', isGreaterThanOrEqualTo: listenFrom)
        .orderBy('createdAtMillis')
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) {
                continue;
              }
              final data = change.doc.data();
              if (data == null) {
                continue;
              }
              final alert = IncomingEmergencyAlert.fromMap(data);
              EmergencyNotificationService.showIncomingEmergencyAlert(
                patientName: alert.patientName,
                mapsUrl: alert.mapsUrl,
              );
              IncomingAlertUi.show(alert);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Responder listener failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  static Future<void> stopResponderListener() async {
    await _listener?.cancel();
    _listener = null;
  }

  static Future<Position> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Konum servisleri kapalı.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Konum izni verilmedi.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  static Future<_EmergencyLocation> _tryGetLocation() async {
    try {
      final position = await _getLocation();
      return _EmergencyLocation.withPosition(position);
    } catch (error) {
      debugPrint('Emergency alert will be sent without location: $error');
      return _EmergencyLocation.withoutPosition(error.toString());
    }
  }

  static Future<bool> _requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

class _EmergencyLocation {
  const _EmergencyLocation({
    required this.hasLocation,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.mapsUrl,
    required this.errorMessage,
  });

  factory _EmergencyLocation.withPosition(Position position) {
    return _EmergencyLocation(
      hasLocation: true,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      mapsUrl:
          'https://maps.google.com/?q=${position.latitude},${position.longitude}',
      errorMessage: '',
    );
  }

  factory _EmergencyLocation.withoutPosition(String errorMessage) {
    return _EmergencyLocation(
      hasLocation: false,
      latitude: null,
      longitude: null,
      accuracy: null,
      mapsUrl: '',
      errorMessage: errorMessage,
    );
  }

  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String mapsUrl;
  final String errorMessage;
}
