import 'package:flutter/material.dart';

import '../emergency/emergency_app_settings_store.dart';
import '../theme/app_theme.dart';
import 'emergency_settings_screen.dart';
import 'manual_sos_confirmation_screen.dart';
import 'medication_screen.dart';
import 'seizure_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSettingsChanged});

  final Future<void> Function()? onSettingsChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  EmergencyAppSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencySettingsScreen(
          onSaved: () async {
            await _loadSettings();
            await widget.onSettingsChanged?.call();
          },
        ),
      ),
    );
    await _loadSettings();
  }

  void _openManualSos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ManualSosConfirmationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final settings = _settings;
    if (settings == null || !settings.isReady) {
      return const Scaffold(
        body: Center(child: Text('Acil durum ayarları bekleniyor.')),
      );
    }

    final isPatient = settings.mode == EmergencyAppMode.patient;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSettings,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba ${settings.displayName},',
                          style: textTheme.displayMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPatient
                              ? 'Bugünkü güvenlik durumun burada.'
                              : 'Bağlı hastanın acil uyarıları burada görünür.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings),
                    tooltip: 'Ayarlar',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _StatusBand(settings: settings),
              const SizedBox(height: 18),
              if (isPatient) _PatientHero(onSosPressed: _openManualSos),
              if (!isPatient) _ResponderHero(code: settings.pairingCode),
              const SizedBox(height: 18),
              Text('Hızlı erişim', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              _QuickActionGrid(openSettings: _openSettings),
              const SizedBox(height: 18),
              _TodayPanel(isPatient: isPatient),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBand extends StatelessWidget {
  const _StatusBand({required this.settings});

  final EmergencyAppSettings settings;

  @override
  Widget build(BuildContext context) {
    final isPatient = settings.mode == EmergencyAppMode.patient;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (isPatient ? AppColors.success : AppColors.primary)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPatient ? Icons.shield_outlined : Icons.notifications_active,
              color: isPatient ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPatient ? 'Koruma aktif' : 'Uyarılar dinleniyor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Eşleşme kodu: ${settings.pairingCode}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientHero extends StatelessWidget {
  const _PatientHero({required this.onSosPressed});

  final VoidCallback onSosPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.emergency,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sos, color: Colors.white, size: 34),
          const SizedBox(height: 14),
          Text(
            'Acil yardıma ihtiyacın varsa bildirimi başlat.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white, height: 1.25),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSosPressed,
              icon: const Icon(Icons.warning_amber),
              label: const Text('SOS ekranını aç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.emergency,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponderHero extends StatelessWidget {
  const _ResponderHero({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$code koduna bağlı acil durum bildirimleri bu cihazda açılır.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.openSettings});

  final VoidCallback openSettings;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.event_note,
        color: AppColors.secondary,
        title: 'Nöbet Günlüğü',
        subtitle: 'Kayıt ekle',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SeizureLogScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.medication,
        color: AppColors.primary,
        title: 'İlaçlarım',
        subtitle: 'Takibi gör',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MedicationScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.psychology,
        color: const Color(0xFFC084FC),
        title: 'AI Asistan',
        subtitle: 'Yakında',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI Asistan yakında eklenecek.')),
          );
        },
      ),
      _QuickAction(
        icon: Icons.contact_emergency,
        color: const Color(0xFFFF9F43),
        title: 'Acil Ayarlar',
        subtitle: 'Rol ve kod',
        onTap: openSettings,
      ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionTile(action: action);
      },
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const Spacer(),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                action.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({required this.isPatient});

  final bool isPatient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPatient ? 'Bugünkü özet' : 'Acil kişi modu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: isPatient ? Icons.sensors : Icons.notifications,
            label: isPatient
                ? 'Hareket algılama arka planda izler.'
                : 'Uyarı geldiğinde bildirim ve ekran açılır.',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: isPatient
                ? 'SOS sırasında konum paylaşımı denenir.'
                : 'Hasta konum paylaşırsa harita bağlantısı görünür.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          ),
        ),
      ],
    );
  }
}
