import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_navigator.dart';
import 'incoming_emergency_alert.dart';

class IncomingAlertUi {
  IncomingAlertUi._();

  static bool _isDialogVisible = false;

  static Future<void> show(IncomingEmergencyAlert alert) async {
    final context = appNavigatorKey.currentContext;
    if (context == null || _isDialogVisible) {
      return;
    }

    _isDialogVisible = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0909),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(child: Text('Acil Durum Bildirimi')),
          ],
        ),
        content: Text(
          alert.hasLocation
              ? '${alert.patientName} acil yardım sinyali gönderdi.\n\nKonum hazır.'
              : '${alert.patientName} acil yardım sinyali gönderdi.\n\nKonum alınamadı.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (alert.mapsUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(alert.mapsUrl),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.map),
              label: const Text('Konumu Aç'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    _isDialogVisible = false;
  }
}
