import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class SeizureLogScreen extends StatefulWidget {
  const SeizureLogScreen({super.key});

  @override
  State<SeizureLogScreen> createState() => _SeizureLogScreenState();
}

class _SeizureLogScreenState extends State<SeizureLogScreen> {
  String? selectedSeizureType = 'Tonik-Klonik';
  Map<String, bool> triggers = {
    'Uykusuzluk': false,
    'Stres': false,
    'Parlak Işık': false,
  };

  // Nöbetleri tutan liste
  final List<Map<String, dynamic>> savedLogs = [];

  void _saveLog() {
    // setState çağrısı ekranın yeniden çizilmesini sağlar
    setState(() {
      List<String> activeTriggers = triggers.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Yeni kaydı listenin en başına (index 0) ekle
      savedLogs.insert(0, {
        'type': selectedSeizureType,
        'date': DateTime.now(),
        'triggers': activeTriggers.isEmpty ? "Yok" : activeTriggers.join(", "),
      });

      // Kayıttan sonra checkboxları sıfırlayalım (isteğe bağlı)
      triggers.updateAll((key, value) => false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nöbet başarıyla listeye eklendi!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text("Nöbet Günlüğü"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KISIM: GİRİŞ FORMU
<<<<<<< HEAD
            Text(
              "Yeni Nöbet Girişi",
              style: textTheme.titleLarge?.copyWith(
                color: const Color(0xFFFFD700),
              ),
            ),
=======
            Text("Yeni Nöbet Girişi", style: textTheme.titleLarge?.copyWith(color: const Color(0xFFFFD700))),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: selectedSeizureType,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
<<<<<<< HEAD
                    items: ['Tonik-Klonik', 'Absans', 'Fokal']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedSeizureType = v),
                  ),
                  ...triggers.keys.map(
                    (key) => CheckboxListTile(
                      title: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      value: triggers[key],
                      onChanged: (v) => setState(() => triggers[key] = v!),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF80CBC4),
                    ),
                  ),
=======
                    items: ['Tonik-Klonik', 'Absans', 'Fokal'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedSeizureType = v),
                  ),
                  ...triggers.keys.map((key) => CheckboxListTile(
                        title: Text(key, style: const TextStyle(fontSize: 14, color: Colors.white)),
                        value: triggers[key],
                        onChanged: (v) => setState(() => triggers[key] = v!),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF80CBC4),
                      )),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _saveLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80CBC4),
                      minimumSize: const Size(double.infinity, 50),
<<<<<<< HEAD
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "KAYDET VE LİSTELE",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
=======
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("KAYDET VE LİSTELE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. KISIM: LİSTE BAŞLIĞI
<<<<<<< HEAD
            Text(
              "Geçmiş Nöbetler (${savedLogs.length})",
              style: textTheme.titleLarge,
            ),
=======
            Text("Geçmiş Nöbetler (${savedLogs.length})", style: textTheme.titleLarge),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
            const SizedBox(height: 10),

            // 3. KISIM: DİNAMİK LİSTE (Kaydı burada göreceksin)
            Expanded(
              child: savedLogs.isEmpty
<<<<<<< HEAD
                  ? const Center(
                      child: Text(
                        "Henüz bir nöbet kaydetmediniz.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
=======
                  ? const Center(child: Text("Henüz bir nöbet kaydetmediniz.", style: TextStyle(color: Colors.grey)))
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
                  : ListView.builder(
                      itemCount: savedLogs.length,
                      itemBuilder: (context, index) {
                        final log = savedLogs[index];
                        return Card(
                          color: AppColors.card,
                          margin: const EdgeInsets.only(bottom: 12),
<<<<<<< HEAD
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF80CBC4),
                              child: Icon(
                                Icons.access_time,
                                color: Colors.black,
                              ),
                            ),
                            title: Text(
                              log['type'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy - HH:mm',
                                'tr_TR',
                              ).format(log['date']),
=======
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF80CBC4),
                              child: Icon(Icons.access_time, color: Colors.black),
                            ),
                            title: Text(log['type'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy - HH:mm', 'tr_TR').format(log['date']),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
<<<<<<< HEAD
                                const Text(
                                  "Tetikleyici",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  log['triggers'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
=======
                                const Text("Tetikleyici", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(log['triggers'], style: const TextStyle(fontSize: 11, color: Colors.orangeAccent)),
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> de408701751cae7e5e23c4f3f5bba691d3828f01
