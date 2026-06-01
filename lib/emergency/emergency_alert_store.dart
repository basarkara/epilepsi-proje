import 'package:shared_preferences/shared_preferences.dart';

class EmergencyAlertStore {
  EmergencyAlertStore._();

  static const _pendingIncidentIdKey = 'emergency_pending_incident_id';
  static const _cancelledIncidentIdKey = 'emergency_cancelled_incident_id';

  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static Future<void> markPending(String incidentId) async {
    await _prefs.setString(_pendingIncidentIdKey, incidentId);
    await _prefs.remove(_cancelledIncidentIdKey);
  }

  static Future<void> cancel(String incidentId) async {
    await _prefs.setString(_cancelledIncidentIdKey, incidentId);
  }

  static Future<bool> isCancelled(String incidentId) async {
    return await _prefs.getString(_cancelledIncidentIdKey) == incidentId;
  }

  static Future<bool> isPending(String incidentId) async {
    return await _prefs.getString(_pendingIncidentIdKey) == incidentId;
  }

  static Future<void> clear(String incidentId) async {
    if (await isPending(incidentId)) {
      await _prefs.remove(_pendingIncidentIdKey);
    }
  }
}
