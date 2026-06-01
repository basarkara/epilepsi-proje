import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'app_to_app_alert_service.dart';
import 'emergency_alert_store.dart';
import 'emergency_app_settings_store.dart';
import 'emergency_config.dart';
import 'emergency_notification_service.dart';
import 'motion_emergency_detector.dart';

Future<void> initializeEmergencyBackgroundService() async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  final settings = await EmergencyAppSettingsStore.load();
  final foregroundTypes = settings.mode == EmergencyAppMode.responder
      ? const [AndroidForegroundType.dataSync]
      : const [AndroidForegroundType.health, AndroidForegroundType.location];

  await EmergencyNotificationService.initialize();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: emergencyBackgroundServiceStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: EmergencyNotificationService.foregroundChannelId,
      initialNotificationTitle: 'Epilepsi koruması aktif',
      initialNotificationContent: 'Acil durum sistemi çalışıyor.',
      foregroundServiceNotificationId:
          EmergencyNotificationService.foregroundNotificationId,
      foregroundServiceTypes: foregroundTypes,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: emergencyBackgroundServiceStart,
      onBackground: emergencyIosBackgroundFetch,
    ),
  );
}

Future<void> restartEmergencyBackgroundService() async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke('stopService');
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  await initializeEmergencyBackgroundService();
}

@pragma('vm:entry-point')
Future<bool> emergencyIosBackgroundFetch(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void emergencyBackgroundServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await EmergencyNotificationService.initialize();

  final settings = await EmergencyAppSettingsStore.load();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  MotionEmergencyDetector? detector;

  service.on('cancelEmergency').listen((event) async {
    final incidentId = event?['incidentId'] as String?;
    if (incidentId != null) {
      await EmergencyAlertStore.cancel(incidentId);
      await EmergencyNotificationService.cancelEmergencyNotification();
    }
  });

  service.on('stopService').listen((event) async {
    await detector?.stop();
    await AppToAppAlertService.stopResponderListener();
    service.stopSelf();
  });

  if (settings.mode == EmergencyAppMode.responder) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Acil uyarılar dinleniyor',
        content: 'Eşleşme kodu: ${settings.pairingCode}',
      );
    }

    await AppToAppAlertService.startResponderListener();
    return;
  }

  detector = MotionEmergencyDetector(
    onTrigger: (trigger) async {
      final incidentId = trigger.detectedAt.microsecondsSinceEpoch.toString();
      await EmergencyAlertStore.markPending(incidentId);

      service.invoke('motionTriggered', {
        'incidentId': incidentId,
        ...trigger.toJson(),
      });

      await _runEmergencyCountdown(incidentId);
    },
  );

  await detector.start();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Epilepsi koruması aktif',
      content: 'Düşme ve şiddetli sarsıntı sinyalleri izleniyor.',
    );
  }
}

Future<void> _runEmergencyCountdown(String incidentId) async {
  for (
    var secondsLeft = EmergencyConfig.countdownSeconds;
    secondsLeft > 0;
    secondsLeft--
  ) {
    if (await EmergencyAlertStore.isCancelled(incidentId)) {
      await EmergencyNotificationService.cancelEmergencyNotification();
      await EmergencyAlertStore.clear(incidentId);
      return;
    }

    await EmergencyNotificationService.showCountdownNotification(
      incidentId: incidentId,
      secondsLeft: secondsLeft,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  if (await EmergencyAlertStore.isCancelled(incidentId)) {
    await EmergencyNotificationService.cancelEmergencyNotification();
    await EmergencyAlertStore.clear(incidentId);
    return;
  }

  await AppToAppAlertService.sendEmergencyAlert();
  await EmergencyNotificationService.showAlertSentNotification();
  await EmergencyAlertStore.clear(incidentId);
}
