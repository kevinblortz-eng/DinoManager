// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/dino_provider.dart';
import 'providers/tracker_provider.dart';
import 'providers/order_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/language_provider.dart';
import 'providers/tag_theme_provider.dart';
import 'providers/role_theme_provider.dart';
import 'providers/gemini_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';
import 'database/database_helper.dart';
import 'l10n/app_localizations.dart';

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

  // ✅ Charger les données AVANT de lancer l'app
  final dinoProvider = DinoProvider();
  await dinoProvider.loadDinos();

  final trackerProvider = TrackerProvider();
  await trackerProvider.loadTrackers();

  final orderProvider = OrderProvider();
  await orderProvider.loadOrders();

  final currencyProvider = CurrencyProvider();
  await currencyProvider.loadPreferences();

  // ✅ Langue : détection auto au premier lancement
  final languageProvider = LanguageProvider();
  await languageProvider.init();

  // ✅ Gemini OCR : charge la clé API depuis les prefs
  final geminiProvider = GeminiProvider();
  await geminiProvider.init();

  // ✅ UN SEUL runApp
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dinoProvider),
        ChangeNotifierProvider.value(value: trackerProvider),
        ChangeNotifierProvider.value(value: orderProvider),
        ChangeNotifierProvider.value(value: currencyProvider),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: geminiProvider),
        ChangeNotifierProvider(create: (_) => TagThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoleThemeProvider()),
      ],
      child: const DinoManagerApp(),
    ),
  );
}

class DinoManagerApp extends StatelessWidget {
  const DinoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'ARK Dino Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // ── Localisation ──────────────────────────────────────────────
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('it'),
        Locale('es'),
        Locale('pt'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ✅ localeResolutionCallback supprimé — c'est `locale: languageProvider.locale`
      // qui fait foi. Le callback écrasait le choix utilisateur avec la locale système.

      home: const MainNavigationScreen(),
    );
  }
}
