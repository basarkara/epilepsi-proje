import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  static const String medicationChannelId = 'epilepsy_medication_reminders';
  static const int emergencyNotificationId = 7001;
  static const int foregroundNotificationId = 7002;

  static bool _initialized = false;
  static bool _timeZoneInitialized = false;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    void Function(NotificationResponse response)? onNotificationResponse,
  }) async {
    _ensureTimeZoneInitialized();

    if (_initialized) {
      return;
    }

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

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        medicationChannelId,
        'İlaç hatırlatmaları',
        description: 'İlaç saatlerinde hatırlatma bildirimi gösterir.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  static void _ensureTimeZoneInitialized() {
    if (_timeZoneInitialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    _timeZoneInitialized = true;
  }

  static Future<void> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
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
    await initialize();

    await _plugin.show(
      emergencyNotificationId,
      'Olası kriz algılandı',
      'Acil bildirim $secondsLeft saniye içinde gönderilecek.',
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
              'İptal et',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: incidentId,
    );
  }

  static Future<void> showAlertSentNotification() async {
    await initialize();

    await _plugin.show(
      emergencyNotificationId,
      'Acil bildirim gönderildi',
      'Acil durum kişilerine haber verildi.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          emergencyChannelId,
          'Emergency alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_bg_service_small',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> showIncomingEmergencyAlert({
    required String patientName,
    required String mapsUrl,
  }) async {
    await initialize();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Acil durum: $patientName',
      mapsUrl.isEmpty
          ? 'Konum paylaşılamadı. Detayları görmek için uygulamayı aç.'
          : 'Konum hazır. Detayları görmek için uygulamayı aç.',
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
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: mapsUrl,
    );
  }

  static Future<void> cancelEmergencyNotification() async {
    await _plugin.cancel(emergencyNotificationId);
  }

  static Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required TimeOfDayParts time,
  }) async {
    _ensureTimeZoneInitialized();
    await requestPermission();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'İlaç zamanı',
      '$medicationName${dosage.isEmpty ? '' : ' - $dosage'} alma zamanı.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          medicationChannelId,
          'İlaç hatırlatmaları',
          channelDescription: 'İlaç saatlerinde hatırlatma bildirimi gösterir.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_bg_service_small',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication:$id',
    );
  }
}

class TimeOfDayParts {
  const TimeOfDayParts({required this.hour, required this.minute});

  final int hour;
  final int minute;
}
