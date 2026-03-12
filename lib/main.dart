import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/dino_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/add_edit_dino_screen.dart';
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
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DinoProvider()),
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

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // 0=Bibliothèque, 1=Add(modal), 2=Menu/Home

  final List<Widget> _screens = const [
    LibraryScreen(),
    HomeScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 1) {
      // Bouton central "+" → ouvrir l'écran d'ajout
      final provider = context.read<DinoProvider>();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEditDinoScreen()),
      ).then((_) {
        // Rafraîchir après ajout
        provider.loadDinos();
      });
      return;
    }
    // Remapper : 0=Bibliothèque, 2=Menu(Home) → index interne 0 ou 1
    setState(() {
      _currentIndex = index == 0 ? 0 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ArkBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

/// Barre de navigation ARK style — 3 boutons : Library | + | Menu
class _ArkBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ArkBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(
          top: BorderSide(color: Color(0xFF1E2D3D), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Library ──────────────────────────────────────────────────
            Expanded(child: _NavItem(
              icon: Icons.auto_stories_rounded,
              label: 'Bibliothèque',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            )),
            // ── Bouton + central ─────────────────────────────────────────
            _AddButton(onTap: () => onTap(1)),
            // ── Menu ─────────────────────────────────────────────────────
            Expanded(child: _NavItem(
              icon: Icons.menu_book_rounded,
              label: 'Stats',
              isActive: currentIndex == 1,
              onTap: () => onTap(2),
            )),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 42 : 36,
              height: isActive ? 42 : 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive ? AppTheme.accentPrimary : const Color(0xFF4A5568),
                size: isActive ? 22 : 20,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: isActive ? AppTheme.accentPrimary : const Color(0xFF4A5568),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
