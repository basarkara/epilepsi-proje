import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'app_to_app_alert_service.dart';
import 'emergency_alert_store.dart';
import 'emergency_config.dart';
import 'emergency_notification_service.dart';
import 'motion_emergency_detector.dart';

Future<void> initializeEmergencyBackgroundService() async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }

  await EmergencyNotificationService.initialize();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: emergencyBackgroundServiceStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: EmergencyNotificationService.foregroundChannelId,
      initialNotificationTitle: 'Epilepsy protection active',
      initialNotificationContent: 'Monitoring motion for emergency events.',
      foregroundServiceNotificationId:
          EmergencyNotificationService.foregroundNotificationId,
      foregroundServiceTypes: const [
        AndroidForegroundType.health,
        AndroidForegroundType.location,
      ],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: emergencyBackgroundServiceStart,
      onBackground: emergencyIosBackgroundFetch,
    ),
  );
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
    service.stopSelf();
  });

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
      title: 'Epilepsy protection active',
      content: 'Monitoring fall and violent shaking signals.',
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
