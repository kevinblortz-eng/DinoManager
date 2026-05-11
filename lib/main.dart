<<<<<<< HEAD
// lib/main.dart
=======
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/dino_provider.dart';
import 'providers/tracker_provider.dart';
<<<<<<< HEAD
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'database/database_helper.dart';
=======
import 'providers/order_provider.dart';
import 'providers/currency_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'database/database_helper.dart';
import '../providers/tag_theme_provider.dart';
import '../providers/role_theme_provider.dart';
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

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

<<<<<<< HEAD
  // Charger les données AVANT de lancer l'app
=======
  // ✅ Charger les données AVANT de lancer l'app
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  final dinoProvider = DinoProvider();
  await dinoProvider.loadDinos();

  final trackerProvider = TrackerProvider();
  await trackerProvider.loadTrackers();

<<<<<<< HEAD
=======
  final orderProvider = OrderProvider();
  await orderProvider.loadOrders();

  final currencyProvider = CurrencyProvider();
  await currencyProvider.loadPreferences();

  // ✅ UN SEUL runApp
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dinoProvider),
        ChangeNotifierProvider.value(value: trackerProvider),
<<<<<<< HEAD
=======
        ChangeNotifierProvider.value(value: orderProvider),
        ChangeNotifierProvider.value(value: currencyProvider),
        ChangeNotifierProvider(create: (_) => TagThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoleThemeProvider()),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
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
