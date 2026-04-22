import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  // Kontrolcüleri (Controller) veri almak için tanımlıyoruz
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // İlaç listesi (Başlangıçta boş veya örnek verili olabilir)
  final List<Map<String, dynamic>> medications = [
    {
      'name': 'Lamotrijin',
      'dosage': '100mg',
      'time': '08:00 AM',
      'isTaken': false,
    },
  ];

  // --- YENİ İLAÇ EKLEME PENCERESİ ---
  void _showAddMedicationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin formu kapatmaması için
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
              child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            const Text("Yeni İlaç Bilgileri", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(_nameController, "İlaç Adı", Icons.medication),
            _buildTextField(_dosageController, "Dozaj (örn: 100mg)", Icons.shutter_speed),
            _buildTextField(_timeController, "Zaman (örn: 08:00 AM)", Icons.access_time),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  setState(() {
                    medications.add({
                      'name': _nameController.text,
                      'dosage': _dosageController.text,
                      'time': _timeController.text,
                      'isTaken': false,
                    });
                  });
                  _nameController.clear();
                  _dosageController.clear();
                  _timeController.clear();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF80CBC4),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("KAYDET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF80CBC4)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF80CBC4))),
          filled: true,
          fillColor: Colors.black26,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int takenCount = medications.where((m) => m['isTaken']).length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text("İlaç Takibi"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: medications.isEmpty 
                ? const Center(child: Text("Henüz ilaç eklemediniz.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: medications.length,
                    itemBuilder: (context, index) => _buildMedCard(medications[index], index),
                  ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showAddMedicationSheet, // Pencereyi açan fonksiyon
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF80CBC4),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Yeni İlaç Ekle +", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            _buildSummaryBar(takenCount),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(int takenCount) {
    double progress = medications.isEmpty ? 0 : takenCount / medications.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Bugün Alınan: $takenCount/${medications.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(value: progress, backgroundColor: Colors.white10, color: const Color(0xFF80CBC4)),
          ),
        ],
      ),
    );
  }

Widget _buildMedCard(Map<String, dynamic> med, int index) {
    // Duruma göre ikon ve renk belirliyoruz
    final bool isTaken = med['isTaken'] ?? false;
    final Color statusColor = isTaken ? const Color(0xFF80CBC4) : const Color(0xFF4A90E2);
    final IconData statusIcon = isTaken ? Icons.medication_liquid : Icons.access_time;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Sol Taraf: İlaç Bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("İlaç Adı", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(med['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text("Dozaj • Zaman", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text("${med['dosage']} • ${med['time']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          
          // Sağ Taraf: Alındı/Bekleniyor Butonu ve Yazısı
          GestureDetector(
            onTap: () {
              setState(() {
                med['isTaken'] = !isTaken;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 48, color: statusColor),
                const SizedBox(height: 6),
                Text(
                  isTaken ? "Alındı" : "Bekleniyor",
                  style: TextStyle(
                    color: statusColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}