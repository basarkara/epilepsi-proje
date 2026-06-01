class EmergencyConfig {
  const EmergencyConfig._();

  static const int countdownSeconds = 10;

  static const double freeFallAccelerationMs2 = 3.0;
  static const double fallImpactAccelerationMs2 = 32.0;
  static const double fallGyroRads = 6.0;
  static const Duration fallImpactWindow = Duration(milliseconds: 1200);

  static const double shakeUserAccelerationMs2 = 16.0;
  static const double shakeGyroRads = 5.5;
  static const int shakeRequiredSamples = 10;
  static const Duration shakeWindow = Duration(milliseconds: 2200);

  static const Duration triggerCooldown = Duration(seconds: 45);
}
