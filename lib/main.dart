import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. BU İMPORT ŞART
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'providers/sos_provider.dart';

// main fonksiyonunu async yaptık
void main() async {
  // 2. Flutter motorunun hazır olduğundan emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Türkçe dil verilerini yüklüyoruz (O kırmızı hatayı çözen satır)
  await initializeDateFormatting('tr_TR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SOSProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epilepsi Takip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme, 
      home: const HomeScreen(),
    );
  }
}