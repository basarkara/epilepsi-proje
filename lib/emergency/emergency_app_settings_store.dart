import 'package:shared_preferences/shared_preferences.dart';

enum EmergencyAppMode { patient, responder }

class EmergencyAppSettings {
  const EmergencyAppSettings({
    required this.mode,
    required this.pairingCode,
    required this.displayName,
  });

  final EmergencyAppMode mode;
  final String pairingCode;
  final String displayName;

  bool get isReady => pairingCode.isNotEmpty && displayName.isNotEmpty;
}

class EmergencyAppSettingsStore {
  EmergencyAppSettingsStore._();

  static const _modeKey = 'emergency_app_mode';
  static const _pairingCodeKey = 'emergency_pairing_code';
  static const _displayNameKey = 'emergency_display_name';

  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<EmergencyAppSettings> load() async {
    final modeName = await _prefs.getString(_modeKey);
    final mode = EmergencyAppMode.values.firstWhere(
      (value) => value.name == modeName,
      orElse: () => EmergencyAppMode.patient,
    );

    return EmergencyAppSettings(
      mode: mode,
      pairingCode: await _prefs.getString(_pairingCodeKey) ?? '',
      displayName: await _prefs.getString(_displayNameKey) ?? '',
    );
  }

  static Future<void> save(EmergencyAppSettings settings) async {
    await _prefs.setString(_modeKey, settings.mode.name);
    await _prefs.setString(
      _pairingCodeKey,
      _normalizePairingCode(settings.pairingCode),
    );
    await _prefs.setString(_displayNameKey, settings.displayName.trim());
  }

  static String _normalizePairingCode(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}
