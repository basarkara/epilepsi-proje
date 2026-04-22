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