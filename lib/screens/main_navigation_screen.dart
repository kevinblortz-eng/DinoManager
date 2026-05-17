import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dino_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'add_edit_dino_screen.dart';
import 'simulator_screen.dart';
import 'tracker/species_journal_home_screen.dart';
import 'orders_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Home au centre par défaut

  // Index : 0=Simulateur, 1=Bibliothèque, 2=Home, 3=Journal, 4=Commandes

  final List<Widget> _screens = [];
  bool _initialized = false;

  void _initScreens() {
    if (_initialized) return;
    _screens.addAll([
      const SimulatorScreen(),                    // 0
      const LibraryScreen(),                      // 1
      HomeScreen(onNavigateToTab: navigateToTab), // 2
      const SpeciesJournalHomeScreen(),           // 3
      const OrdersScreen(),                       // 4
    ]);
    _initialized = true;
  }

  void navigateToTab(int index) {
    if (index >= 0 && index <= 4) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _openAddScreen() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const AddEditDinoScreen(),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );

    if (mounted) {
      context.read<DinoProvider>().loadDinos();
    }
  }

  @override
  Widget build(BuildContext context) {
    _initScreens();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ArkBottomNavBar(
        currentIndex: _currentIndex,
        onTabChanged: (index) {
          navigateToTab(index);
        },
        onAddPressed: _openAddScreen,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM NAVIGATION BAR — 5 boutons
// ═══════════════════════════════════════════════════════════════
class _ArkBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAddPressed;

  const _ArkBottomNavBar({
    required this.currentIndex,
    required this.onTabChanged,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isHome = currentIndex == 2;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E2733), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: 8,
            bottom: bottomPadding > 0 ? 4 : 12,
            left: 8,
            right: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ── Simulateur ──
              _NavBarItem(
                icon: Icons.science_rounded,
                label: AppLocalizations.of(context)?.simulatorTitle ?? 'Simulator',
                isActive: currentIndex == 0,
                onTap: () => onTabChanged(0),
              ),

              // ── Bibliothèque ──
              _NavBarItem(
                icon: Icons.auto_stories_rounded,
                label: AppLocalizations.of(context)?.navLibrary ?? 'Library',
                isActive: currentIndex == 1,
                onTap: () => onTabChanged(1),
              ),

              // ── Bouton Dynamique au centre ──
              if (isHome)
                _NavBarCenterAddItem(
                  onTap: onAddPressed,
                )
              else
                _NavBarCenterHomeItem(
                  isActive: currentIndex == 2,
                  onTap: () => onTabChanged(2),
                ),

              // ── Journal ──
              _NavBarItem(
                icon: Icons.menu_book_rounded,
                label: AppLocalizations.of(context)?.speciesJournalTitle ?? 'Journal',
                isActive: currentIndex == 3,
                onTap: () => onTabChanged(3),
              ),

              // ── Commandes ──
              _NavBarItem(
                icon: Icons.shopping_cart_rounded,
                label: AppLocalizations.of(context)?.ordersTitle ?? 'Orders',
                isActive: currentIndex == 4,
                onTap: () => onTabChanged(4),
                accentColor: Colors.cyanAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ITEM STANDARD (Simulateur, Bibliothèque, Journal, Commandes)
// ─────────────────────────────────────────────────────────────
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? accentColor;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppTheme.accentPrimary;
    final color = isActive ? activeColor : const Color(0xFF6B7A8D);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: isActive ? 44 : 40,
              height: isActive ? 44 : 40,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [activeColor, activeColor.withValues(alpha: 0.7)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? null
                    : Border.all(color: const Color(0xFF2D3748), width: 1),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : color,
                size: isActive ? 22 : 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: color,
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOUTON CENTRE QUAND ON EST SUR HOME : "Ajouter"
// ─────────────────────────────────────────────────────────────
class _NavBarCenterAddItem extends StatelessWidget {
  final VoidCallback onTap;

  const _NavBarCenterAddItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGreen.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)?.libraryAddDino.split(' ').first ?? 'Add',
              style: GoogleFonts.exo2(
                color: AppTheme.accentGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOUTON CENTRE QUAND ON N'EST PAS SUR HOME : "Home"
// ─────────────────────────────────────────────────────────────
class _NavBarCenterHomeItem extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarCenterHomeItem({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2D3748), Color(0xFF1E2733)],
                      ),
                border: Border.all(
                  color: isActive
                      ? AppTheme.accentPrimary.withValues(alpha: 0.8)
                      : const Color(0xFF3D4A5C),
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.home_rounded,
                color: isActive ? Colors.white : const Color(0xFF6B7A8D),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Home',
              style: GoogleFonts.exo2(
                color: isActive
                    ? AppTheme.accentPrimary
                    : const Color(0xFF6B7A8D),
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
