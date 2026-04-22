import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/sos_provider.dart';
import 'emergency_settings_screen.dart';
import 'seizure_log_screen.dart';
import 'medication_screen.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Kart Oluşturucu Fonksiyon
    Widget buildCard(Color iconColor, IconData icon, String label, {VoidCallback? onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 42, color: iconColor),
                const SizedBox(height: 12),
                Text(label, style: textTheme.titleMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Merhaba Ceren,', 
                style: textTheme.displayMedium?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Bugün nasıl hissediyorsun?', 
                style: textTheme.bodyMedium?.copyWith(color: AppColors.grey)),
              const SizedBox(height: 16),

              // SOS Butonu
              GestureDetector(
                onTap: () {
                  Provider.of<SOSProvider>(context, listen: false).sendSOS();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SOS Sinyali ve Konum Gönderiliyor...'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'ACİL YARDIM (SOS)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4 KARTLIK SİMETRİK IZGARA (Raporlar Kaldırıldı)
              Expanded(
                child: GridView.builder(
                  // physics: const NeverScrollableScrollPhysics(), // Ekran sığmazsa kaydırmayı açabilirsin
                  itemCount: 4, // 5'ten 4'e düşürdük
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
  return buildCard(const Color(0xFFFFD700), Icons.event_note, 'Nöbet\nGünlüğü', 
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SeizureLogScreen()),
      );
    });
                      case 1:
  return buildCard(const Color(0xFF4A90E2), Icons.medication, 'İlaçlarım', 
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MedicationScreen()),
      );
    });
                      case 2:
                        return buildCard(const Color(0xFF9B59B6), Icons.psychology, 'AI\nAsistan', 
                          onTap: () => debugPrint("AI Asistan tıklandı"));
                      case 3:
                        // Raporlar yerine Acil Durum Ayarları geldi
                        return buildCard(Colors.orangeAccent, Icons.contact_emergency, 'Acil Durum\nAyarları', 
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EmergencySettingsScreen()),
                            );
                          });
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}