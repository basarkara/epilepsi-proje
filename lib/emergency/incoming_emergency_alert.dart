class IncomingEmergencyAlert {
  const IncomingEmergencyAlert({
    required this.patientName,
    required this.mapsUrl,
    required this.hasLocation,
    required this.locationError,
  });

  final String patientName;
  final String mapsUrl;
  final bool hasLocation;
  final String locationError;

  factory IncomingEmergencyAlert.fromMap(Map<String, dynamic> data) {
    return IncomingEmergencyAlert(
      patientName: data['patientName'] as String? ?? 'Hasta',
      mapsUrl: data['mapsUrl'] as String? ?? '',
      hasLocation: data['hasLocation'] as bool? ?? false,
      locationError: data['locationError'] as String? ?? '',
    );
  }
}
