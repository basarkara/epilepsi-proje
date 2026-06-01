<<<<<<< HEAD
import 'package:flutter/material.dart';

import '../emergency/app_to_app_alert_service.dart';
import '../emergency/emergency_app_settings_store.dart';
import '../emergency/emergency_background_service.dart';
import '../theme/app_theme.dart';

class EmergencySettingsScreen extends StatefulWidget {
  const EmergencySettingsScreen({super.key, this.onSaved});

  final Future<void> Function()? onSaved;

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
    } else {
      await AppToAppAlertService.stopResponderListener();
      await initializeEmergencyBackgroundService();
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
                  ],
                ),
              ),
            ),
    );
  }
}
=======
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmergencySettingsScreen extends StatelessWidget {
  const EmergencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Acil Durum Bilgileri"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. BÖLÜM: KİŞİSEL BİLGİLER (Profil Kartı) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFFFD700),
                    child: Icon(Icons.person, size: 50, color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  Text("Ceren", style: textTheme.displayMedium),
                  const Divider(color: Colors.grey, height: 32),
                  _buildProfileRow(Icons.bloodtype, "Kan Grubu", "0 Rh+"),
                  _buildProfileRow(Icons.medical_services, "Hastalık", "Epilepsi"),
                  _buildProfileRow(Icons.warning, "Alerji", "Yok"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. BÖLÜM: ACİL DURUM KİŞİLERİ ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Acil Durum Kişileri", style: textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFFFD700), size: 30),
                  onPressed: () => _showAddContactDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Manuel Eklenen Kişi Örneği
            _buildContactCard("Annem", "0555 XXX XX XX"),
            _buildContactCard("Babam", "0544 XXX XX XX"),
          ],
        ),
      ),
    );
  }

  // Profil satırı oluşturucu
  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFFD700)),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Kişi kartı oluşturucu
  Widget _buildContactCard(String name, String phone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_phone, color: Color(0xFF4A90E2)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(phone, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.edit, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  // Kişi Ekleme Penceresi (Manuel Giriş)
  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text("Yeni Kişi Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: "İsim")),
            TextField(decoration: InputDecoration(labelText: "Telefon Numarası")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Kaydet")),
        ],
      ),
    );
  }
}
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
