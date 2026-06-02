import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SeizureLog {
  const SeizureLog({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.triggers,
    required this.durationMinutes,
    required this.notes,
  });

  final String id;
  final String type;
  final DateTime occurredAt;
  final List<String> triggers;
  final int durationMinutes;
  final String notes;

  String get triggerLabel => triggers.isEmpty ? 'Yok' : triggers.join(', ');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'occurredAt': occurredAt.toIso8601String(),
      'triggers': triggers,
      'durationMinutes': durationMinutes,
      'notes': notes,
    };
  }

  factory SeizureLog.fromJson(Map<String, dynamic> json) {
    final rawTriggers = json['triggers'];
    final triggers = rawTriggers is List
        ? rawTriggers.map((item) => item.toString()).toList()
        : rawTriggers is String && rawTriggers != 'Yok'
        ? rawTriggers.split(',').map((item) => item.trim()).toList()
        : <String>[];

    return SeizureLog(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: json['type'] as String? ?? 'Belirtilmedi',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.now(),
      triggers: triggers.where((item) => item.isNotEmpty).toList(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class SeizureLogStore {
  SeizureLogStore._();

  static const _key = 'seizure_logs_v1';
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<List<SeizureLog>> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final logs = decoded
        .whereType<Map<String, dynamic>>()
        .map(SeizureLog.fromJson)
        .toList();
    logs.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return logs;
  }

  static Future<void> saveAll(List<SeizureLog> logs) async {
    final sorted = [...logs]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    await _prefs.setString(
      _key,
      jsonEncode(sorted.map((log) => log.toJson()).toList()),
    );
  }

  static Future<void> add(SeizureLog log) async {
    final logs = await load();
    await saveAll([log, ...logs]);
  }

  static Future<void> delete(String id) async {
    final logs = await load();
    await saveAll(logs.where((log) => log.id != id).toList());
  }
}
