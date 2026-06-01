import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. BU İMPORT ŞART
import 'package:provider/provider.dart';

import 'app_navigator.dart';
import 'emergency/app_to_app_alert_service.dart';
import 'emergency/emergency_app_settings_store.dart';
import 'emergency/emergency_background_service.dart';
import 'emergency/emergency_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'screens/app_startup_screen.dart';
import 'screens/emergency_countdown_screen.dart';
import 'providers/sos_provider.dart';

// main fonksiyonunu async yaptık
void main() async {
  // 2. Flutter motorunun hazır olduğundan emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Türkçe dil verilerini yüklüyoruz (O kırmızı hatayı çözen satır)
  await initializeDateFormatting('tr_TR', null);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SOSProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.enableEmergencyProtection = true,
    this.enableAuth = true,
  });

  final bool enableEmergencyProtection;
  final bool enableAuth;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Map<String, dynamic>?>? _motionSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.enableEmergencyProtection) {
      _bootstrapEmergencyProtection();
    }
  }

  @override
  void dispose() {
    _motionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapEmergencyProtection() async {
    try {
      final settings = await EmergencyAppSettingsStore.load();
      if (!settings.isReady) {
        return;
      }

      await _motionSubscription?.cancel();
      _motionSubscription = null;

      await EmergencyNotificationService.requestPermission();
      await AppToAppAlertService.requestPermissions();

      if (settings.mode == EmergencyAppMode.responder) {
        await AppToAppAlertService.startResponderListener();
        if (defaultTargetPlatform == TargetPlatform.android) {
          await initializeEmergencyBackgroundService();
        }
        return;
      }

      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        return;
      }

      _motionSubscription = FlutterBackgroundService()
          .on('motionTriggered')
          .listen(_showEmergencyCountdown);

      await initializeEmergencyBackgroundService();
    } catch (error, stackTrace) {
      debugPrint('Emergency protection could not start: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _showEmergencyCountdown(Map<String, dynamic>? event) {
    final incidentId = event?['incidentId'] as String?;
    final kind = event?['kind'] as String?;
    if (incidentId == null || appNavigatorKey.currentState == null) {
      return;
    }

    final triggerLabel = kind == 'fall'
        ? 'Şiddetli düşme algılandı'
        : 'Şiddetli sarsıntı algılandı';

    appNavigatorKey.currentState!.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EmergencyCountdownScreen(
          incidentId: incidentId,
          triggerLabel: triggerLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Epilepsi Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: widget.enableAuth
          ? AuthGate(onConfigured: _bootstrapEmergencyProtection)
          : AppStartupScreen(onConfigured: _bootstrapEmergencyProtection),
    );
  }
}
