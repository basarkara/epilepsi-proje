import 'package:flutter/material.dart';

import '../auth/app_auth_service.dart';
import '../emergency/app_to_app_alert_service.dart';
import '../emergency/emergency_app_settings_store.dart';
import '../emergency/emergency_background_service.dart';
import '../theme/app_theme.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key, this.onSaved, this.onSignedOut});

  final Future<void> Function()? onSaved;
  final Future<void> Function()? onSignedOut;

  @override
  State<EmergencySettingsScreen> createState() =>
      _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  final _displayNameController = TextEditingController();
  final _pairingCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  EmergencyAppMode _mode = EmergencyAppMode.patient;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _pairingCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await EmergencyAppSettingsStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _mode = settings.mode;
      _displayNameController.text = settings.displayName;
      _pairingCodeController.text = settings.pairingCode;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await EmergencyAppSettingsStore.save(
      EmergencyAppSettings(
        mode: _mode,
        displayName: _displayNameController.text,
        pairingCode: _pairingCodeController.text,
      ),
    );

    if (_mode == EmergencyAppMode.responder) {
      await AppToAppAlertService.startResponderListener();
      await restartEmergencyBackgroundService();
    } else {
      await AppToAppAlertService.stopResponderListener();
      await restartEmergencyBackgroundService();
    }

    if (!mounted) {
      return;
    }
    await widget.onSaved?.call();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Acil durum ayarları kaydedildi.")),
    );
  }

  Future<void> _signOut() async {
    await AppToAppAlertService.stopResponderListener();
    await AppAuthService.signOut();
    await widget.onSignedOut?.call();

    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Acil Durum Ayarları")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uygulamanın bu cihazda nasıl çalışacağını belirle.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Uygulama Rolü", style: textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            'Hasta ve acil kişi aynı uygulamayı kullanır.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<EmergencyAppMode>(
                            segments: const [
                              ButtonSegment(
                                value: EmergencyAppMode.patient,
                                icon: Icon(Icons.personal_injury),
                                label: Text("Hasta"),
                              ),
                              ButtonSegment(
                                value: EmergencyAppMode.responder,
                                icon: Icon(Icons.health_and_safety),
                                label: Text("Acil Kişi"),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (selection) {
                              setState(() => _mode = selection.first);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.badge_outlined),
                        labelText: _mode == EmergencyAppMode.patient
                            ? "Hasta adı"
                            : "Acil kişi adı",
                        hintText: _mode == EmergencyAppMode.patient
                            ? "Ceren"
                            : "Annem",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "İsim gerekli";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pairingCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.link),
                        labelText: "Eşleşme kodu",
                        hintText: "CEREN2026",
                      ),
                      validator: (value) {
                        final code = (value ?? "")
                            .trim()
                            .toUpperCase()
                            .replaceAll(RegExp(r'[^A-Z0-9]'), '');
                        if (code.length < 4) {
                          return "En az 4 karakterlik kod gir";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _mode == EmergencyAppMode.patient
                                  ? "Bu kodu acil durum kişilerinle paylaş. Acil durumda uygulama bu koda bağlı kişilere bildirim gönderir."
                                  : "Hasta ile aynı eşleşme kodunu gir. Uygulama açıkken veya arka planda canlıyken acil durum bildirimlerini alırsın.",
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.grey,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text("Kaydet"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text("Hesaptan çık"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
