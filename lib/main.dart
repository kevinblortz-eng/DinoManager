// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/dino_provider.dart';
import 'providers/tracker_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await DatabaseHelper().init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Charger les données AVANT de lancer l'app
  final dinoProvider = DinoProvider();
  await dinoProvider.loadDinos();

  final trackerProvider = TrackerProvider();
  await trackerProvider.loadTrackers();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dinoProvider),
        ChangeNotifierProvider.value(value: trackerProvider),
      ],
      child: const DinoManagerApp(),
    ),
  );
}

class DinoManagerApp extends StatelessWidget {
  const DinoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavigationScreen(),
    );
  }
}
