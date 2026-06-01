import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import 'emergency_config.dart';

enum MotionTriggerKind { fall, violentShake }

class MotionTrigger {
  const MotionTrigger({
    required this.kind,
    required this.accelerationMagnitude,
    required this.userAccelerationMagnitude,
    required this.gyroscopeMagnitude,
    required this.detectedAt,
  });

  final MotionTriggerKind kind;
  final double accelerationMagnitude;
  final double userAccelerationMagnitude;
  final double gyroscopeMagnitude;
  final DateTime detectedAt;

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'acceleration': accelerationMagnitude,
    'userAcceleration': userAccelerationMagnitude,
    'gyroscope': gyroscopeMagnitude,
    'detectedAt': detectedAt.toIso8601String(),
  };
}

class _MotionBurstSample {
  const _MotionBurstSample(this.time, this.userAcceleration, this.gyroscope);

  final DateTime time;
  final double userAcceleration;
  final double gyroscope;
}

class MotionEmergencyDetector {
  MotionEmergencyDetector({required this.onTrigger});

  final FutureOr<void> Function(MotionTrigger trigger) onTrigger;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<_MotionBurstSample> _shakeSamples = [];

  DateTime? _freeFallStartedAt;
  DateTime? _lastTriggerAt;
  double _lastAccelerationMagnitude = 9.8;
  double _lastUserAccelerationMagnitude = 0;
  double _lastGyroscopeMagnitude = 0;
  bool _triggerInProgress = false;

  Future<void> start() async {
    const samplingPeriod = Duration(milliseconds: 50);

    _subscriptions
      ..add(
        accelerometerEventStream(
          samplingPeriod: samplingPeriod,
        ).listen(_handleAccelerometer),
      )
      ..add(
        userAccelerometerEventStream(
          samplingPeriod: samplingPeriod,
        ).listen(_handleUserAccelerometer),
      )
      ..add(
        gyroscopeEventStream(
          samplingPeriod: samplingPeriod,
        ).listen(_handleGyroscope),
      );
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _shakeSamples.clear();
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    _lastAccelerationMagnitude = _magnitude(event.x, event.y, event.z);
    final now = DateTime.now();

    if (_lastAccelerationMagnitude <= EmergencyConfig.freeFallAccelerationMs2) {
      _freeFallStartedAt ??= now;
      return;
    }

    final freeFallStartedAt = _freeFallStartedAt;
    if (freeFallStartedAt == null) {
      return;
    }

    final elapsed = now.difference(freeFallStartedAt);
    final impactMatched =
        elapsed <= EmergencyConfig.fallImpactWindow &&
        _lastAccelerationMagnitude >=
            EmergencyConfig.fallImpactAccelerationMs2 &&
        _lastGyroscopeMagnitude >= EmergencyConfig.fallGyroRads;

    if (impactMatched) {
      _fire(MotionTriggerKind.fall);
    }

    if (elapsed > EmergencyConfig.fallImpactWindow) {
      _freeFallStartedAt = null;
    }
  }

  void _handleUserAccelerometer(UserAccelerometerEvent event) {
    _lastUserAccelerationMagnitude = _magnitude(event.x, event.y, event.z);
    final now = DateTime.now();

    _shakeSamples.removeWhere(
      (sample) => now.difference(sample.time) > EmergencyConfig.shakeWindow,
    );

    if (_lastUserAccelerationMagnitude >=
            EmergencyConfig.shakeUserAccelerationMs2 &&
        _lastGyroscopeMagnitude >= EmergencyConfig.shakeGyroRads) {
      _shakeSamples.add(
        _MotionBurstSample(
          now,
          _lastUserAccelerationMagnitude,
          _lastGyroscopeMagnitude,
        ),
      );
    }

    if (_shakeSamples.length < EmergencyConfig.shakeRequiredSamples) {
      return;
    }

    final burstDuration = now.difference(_shakeSamples.first.time);
    final peakUserAcceleration = _shakeSamples
        .map((sample) => sample.userAcceleration)
        .reduce(max);
    final peakGyro = _shakeSamples
        .map((sample) => sample.gyroscope)
        .reduce(max);

    final sustainedViolentMotion =
        burstDuration >= const Duration(milliseconds: 700) &&
        peakUserAcceleration >= EmergencyConfig.shakeUserAccelerationMs2 &&
        peakGyro >= EmergencyConfig.shakeGyroRads;

    if (sustainedViolentMotion) {
      _fire(MotionTriggerKind.violentShake);
      _shakeSamples.clear();
    }
  }

  void _handleGyroscope(GyroscopeEvent event) {
    _lastGyroscopeMagnitude = _magnitude(event.x, event.y, event.z);
  }

  Future<void> _fire(MotionTriggerKind kind) async {
    final now = DateTime.now();
    if (_triggerInProgress) {
      return;
    }
    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < EmergencyConfig.triggerCooldown) {
      return;
    }

    _triggerInProgress = true;
    _lastTriggerAt = now;
    try {
      await onTrigger(
        MotionTrigger(
          kind: kind,
          accelerationMagnitude: _lastAccelerationMagnitude,
          userAccelerationMagnitude: _lastUserAccelerationMagnitude,
          gyroscopeMagnitude: _lastGyroscopeMagnitude,
          detectedAt: now,
        ),
      );
    } finally {
      _freeFallStartedAt = null;
      _triggerInProgress = false;
    }
  }

  double _magnitude(double x, double y, double z) {
    return sqrt((x * x) + (y * y) + (z * z));
  }
}
