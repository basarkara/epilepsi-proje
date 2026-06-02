import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.doctorName,
    required this.clinicName,
    required this.dateTime,
    required this.notes,
    required this.notificationId,
  });

  final String id;
  final String doctorName;
  final String clinicName;
  final DateTime dateTime;
  final String notes;
  final int notificationId;

  bool get isPast => dateTime.isBefore(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'notificationId': notificationId,
    };
  }

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    final dateTime =
        DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now();
    return DoctorAppointment(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      doctorName: json['doctorName'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      dateTime: dateTime,
      notes: json['notes'] as String? ?? '',
      notificationId:
          (json['notificationId'] as num?)?.toInt() ??
          (dateTime.millisecondsSinceEpoch & 0x7fffffff),
    );
  }
}

class AppointmentStore {
  AppointmentStore._();

  static const _key = 'doctor_appointments_v1';
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<List<DoctorAppointment>> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final appointments = decoded
        .whereType<Map<String, dynamic>>()
        .map(DoctorAppointment.fromJson)
        .toList();
    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }

  static Future<void> saveAll(List<DoctorAppointment> appointments) async {
    final sorted = [...appointments]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _prefs.setString(
      _key,
      jsonEncode(sorted.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> add(DoctorAppointment appointment) async {
    final appointments = await load();
    await saveAll([appointment, ...appointments]);
  }

  static Future<void> delete(String id) async {
    final appointments = await load();
    await saveAll(appointments.where((item) => item.id != id).toList());
  }
}
