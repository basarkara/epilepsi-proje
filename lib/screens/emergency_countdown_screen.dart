import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../emergency/emergency_alert_store.dart';
import '../emergency/emergency_config.dart';

class EmergencyCountdownScreen extends StatefulWidget {
  const EmergencyCountdownScreen({
    required this.incidentId,
    required this.triggerLabel,
    super.key,
  });

  final String incidentId;
  final String triggerLabel;

  @override
  State<EmergencyCountdownScreen> createState() =>
      _EmergencyCountdownScreenState();
}

class _EmergencyCountdownScreenState extends State<EmergencyCountdownScreen> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = EmergencyConfig.countdownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }

      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).maybePop();
        return;
      }

      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancelEmergency() async {
    await EmergencyAlertStore.cancel(widget.incidentId);
    FlutterBackgroundService().invoke('cancelEmergency', {
      'incidentId': widget.incidentId,
    });

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Emergency alert cancelled.')));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0505),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 92,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.triggerLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Emergency notification will be sent in',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_secondsLeft',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 96,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cancelEmergency,
                    icon: const Icon(Icons.close),
                    label: const Text('I am OK - Cancel Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
