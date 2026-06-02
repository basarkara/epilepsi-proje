import 'package:flutter/material.dart';

import '../emergency/emergency_app_settings_store.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({
    super.key,
    required this.onConfigured,
    this.onSignedOut,
  });

  final Future<void> Function() onConfigured;
  final Future<void> Function()? onSignedOut;

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  EmergencyAppMode _mode = EmergencyAppMode.patient;
  bool _isLoading = true;
  bool _isSaving = false;
  EmergencyAppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await EmergencyAppSettingsStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    final settings = EmergencyAppSettings(
      mode: _mode,
      displayName: _nameController.text,
      pairingCode: _codeController.text,
    );

    await EmergencyAppSettingsStore.save(settings);
    await widget.onConfigured();

    if (!mounted) {
      return;
    }
    final savedSettings = await EmergencyAppSettingsStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = savedSettings;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_settings?.isReady ?? false) {
      return HomeScreen(
        onSettingsChanged: _loadSettings,
        onSignedOut: widget.onSignedOut,
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 22),
                Text('Epilepsi Takip', style: textTheme.displayLarge),
                const SizedBox(height: 10),
                Text(
                  'Uygulamayı hasta veya acil durum kişisi olarak kullanabilirsin. Aynı eşleşme kodunu giren kişiler birbirine bağlanır.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.grey,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Rolünü seç', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                SegmentedButton<EmergencyAppMode>(
                  segments: const [
                    ButtonSegment(
                      value: EmergencyAppMode.patient,
                      icon: Icon(Icons.personal_injury),
                      label: Text('Hastayım'),
                    ),
                    ButtonSegment(
                      value: EmergencyAppMode.responder,
                      icon: Icon(Icons.volunteer_activism),
                      label: Text('Acil kişiyim'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined),
                    labelText: _mode == EmergencyAppMode.patient
                        ? 'Hasta adı'
                        : 'Adın',
                    hintText: _mode == EmergencyAppMode.patient
                        ? 'Örn. Ceren'
                        : 'Örn. Annem',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'İsim gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.link),
                    labelText: 'Eşleşme kodu',
                    hintText: 'Örn. CEREN2026',
                  ),
                  validator: (value) {
                    final code = (value ?? '').trim().toUpperCase().replaceAll(
                      RegExp(r'[^A-Z0-9]'),
                      '',
                    );
                    if (code.length < 4) {
                      return 'En az 4 karakterlik kod gir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _InfoPanel(mode: _mode),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Başla'),
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

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.mode});

  final EmergencyAppMode mode;

  @override
  Widget build(BuildContext context) {
    final text = mode == EmergencyAppMode.patient
        ? 'SOS ve otomatik algılama uyarıları bu koda bağlı acil kişilere uygulama bildirimi olarak gönderilir.'
        : 'Hasta ile aynı kodu girersen acil durum uyarıları bu cihazda bildirim ve ekranda uyarı olarak görünür.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.grey,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
