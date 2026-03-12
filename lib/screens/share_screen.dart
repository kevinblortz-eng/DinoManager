import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dino_provider.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_display_widget.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildModeCard(
              context,
              icon: Icons.person_outlined,
              title: 'Dino Unique',
              subtitle: 'Génère une image de présentation pour un seul dino',
              features: [
                '🦕 Silhouette recolorée',
                '📊 Stats complètes HP, Dégâts, Stamina...',
                '🎨 Régions de couleur affichées',
                '🏷️ Tag version + mutations',
                '📋 Nom, espèce, niveau',
              ],
              badge: 'Bientôt',
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1207), Color(0xFF2D1E0A)],
              ),
              accentColor: AppTheme.accentPrimary,
              onTap: () => _showComingSoon(context, 'Partage Dino Unique'),
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              context,
              icon: Icons.grid_view_outlined,
              title: 'Multi-Dinos',
              subtitle: 'Panneau comparatif avec plusieurs dinos côte à côte',
              features: [
                '🖼️ 2 à 4 dinos sur une même image',
                '🔲 Encadré central avec stats de base',
                '🦕 Miniatures recolorées pour chaque dino',
                '🏷️ Tags version visibles',
                '🎨 Templates 2x1, 2x2, 3x1...',
              ],
              badge: 'Bientôt',
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1A10), Color(0xFF112218)],
              ),
              accentColor: AppTheme.accentGreen,
              onTap: () => _showComingSoon(context, 'Partage Multi-Dinos'),
            ),
            const SizedBox(height: 24),
            _buildDinoSelector(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_outlined, color: AppTheme.accentPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partage & Export',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Génération d\'images en cours de développement',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accentSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accentSecondary, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ces fonctionnalités seront disponibles dans la prochaine version. '
                  'L\'architecture est déjà en place pour l\'intégration.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> features,
    required String badge,
    required Gradient gradient,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header de la carte
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: features.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(f, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDinoSelector(BuildContext context) {
    return Consumer<DinoProvider>(
      builder: (context, provider, _) {
        if (provider.dinos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'VOS DINOS (APERÇU)',
                  style: TextStyle(
                    color: AppTheme.accentSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.dinos.take(10).length,
                itemBuilder: (ctx, i) {
                  final dino = provider.dinos[i];
                  return _buildMiniDinoCard(dino);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniDinoCard(Dino dino) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dino.roleColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: DinoAvatarWidget(dino: dino, size: 110),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text(
                  dino.nom,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                ColorRegionsBar(dino: dino, dotSize: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🚧 '),
            Text('$feature — Bientôt disponible !'),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
