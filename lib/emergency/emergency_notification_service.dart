import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'emergency_alert_store.dart';

const String cancelEmergencyActionId = 'cancel_emergency';

@pragma('vm:entry-point')
void emergencyNotificationTapBackground(NotificationResponse response) {
  if (response.actionId == cancelEmergencyActionId &&
      response.payload != null &&
      response.payload!.isNotEmpty) {
    EmergencyAlertStore.cancel(response.payload!);
  }
}

class EmergencyNotificationService {
  EmergencyNotificationService._();

  static const String emergencyChannelId = 'epilepsy_emergency_alerts';
  static const String foregroundChannelId = 'epilepsy_motion_monitor';
  static const int emergencyNotificationId = 7001;
  static const int foregroundNotificationId = 7002;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    void Function(NotificationResponse response)? onNotificationResponse,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      'ic_bg_service_small',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == cancelEmergencyActionId &&
            response.payload != null &&
            response.payload!.isNotEmpty) {
          EmergencyAlertStore.cancel(response.payload!);
        }
        onNotificationResponse?.call(response);
      },
      onDidReceiveBackgroundNotificationResponse:
          emergencyNotificationTapBackground,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        foregroundChannelId,
        'Motion monitor',
        description: 'Keeps epilepsy emergency detection active.',
        importance: Importance.low,
      ),
    );

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        emergencyChannelId,
        'Emergency alerts',
        description: 'Emergency countdown and responder alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  static Future<void> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> showCountdownNotification({
    required String incidentId,
    required int secondsLeft,
  }) async {
    await _plugin.show(
      emergencyNotificationId,
      'Possible seizure detected',
      'Emergency notification will be sent in $secondsLeft seconds.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          emergencyChannelId,
          'Emergency alerts',
          channelDescription: 'Emergency countdown and responder alerts.',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          icon: 'ic_bg_service_small',
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              cancelEmergencyActionId,
              'Cancel',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: incidentId,
    );
  }

  static Future<void> showAlertSentNotification() async {
    await _plugin.show(
      emergencyNotificationId,
      'Emergency alert sent',
      'Your responders were notified.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          emergencyChannelId,
          'Emergency alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_bg_service_small',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  static Future<void> showIncomingEmergencyAlert({
    required String patientName,
    required String mapsUrl,
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Emergency alert: $patientName',
      mapsUrl.isEmpty
          ? 'Location could not be shared. Open the app to view details.'
          : 'Location: $mapsUrl',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          emergencyChannelId,
          'Emergency alerts',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          icon: 'ic_bg_service_small',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: mapsUrl,
    );
  }

  static Future<void> cancelEmergencyNotification() async {
    await _plugin.cancel(emergencyNotificationId);
  }
}
