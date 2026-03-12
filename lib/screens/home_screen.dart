import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dino_provider.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import 'dino_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Consumer<DinoProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, provider),
              SliverToBoxAdapter(child: _buildStatsGrid(provider)),
              SliverToBoxAdapter(child: _buildRecentSection(context, provider)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIVER HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverHeader(BuildContext context, DinoProvider provider) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0D1117),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A0A00),
                Color(0xFF0D1117),
                Color(0xFF0A1628),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFF9500), Color(0xFFFF4500)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🦖', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Color(0xFFFF6B00), Color(0xFFFFAA00)],
                          ).createShader(bounds),
                          child: Text(
                            'STATISTIQUES',
                            style: GoogleFonts.cinzelDecorative(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vue d\'ensemble de votre collection',
                          style: GoogleFonts.exo2(
                            color: const Color(0xFF6B7A8D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GRILLE DE STATS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid(DinoProvider provider) {
    final dinos = provider.allDinos;
    final boss = dinos.where((d) => d.tags.contains('Boss')).length;
    final breed = dinos.where((d) => d.tags.contains('Breed')).length;
    final pvp = dinos.where((d) => d.tags.contains('PvP')).length;
    final farm = dinos.where((d) => d.tags.contains('Farm')).length;
    final volant = dinos.where((d) => d.tags.contains('Volant')).length;
    final aquatique = dinos.where((d) => d.tags.contains('Aquatique')).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total grande carte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A0D00), Color(0xFF111827)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🦖', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dinos.length}',
                      style: GoogleFonts.cinzelDecorative(
                        color: AppTheme.accentPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'dinos enregistrés',
                      style: GoogleFonts.exo2(
                        color: const Color(0xFF6B7A8D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (dinos.isNotEmpty)
                  Column(
                    children: [
                      const Text('🏷️', style: TextStyle(fontSize: 24)),
                      Text(
                        '${dinos.where((d) => d.tags.isNotEmpty).length} tagués',
                        style: GoogleFonts.exo2(
                          color: AppTheme.accentSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Grille 2x3
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _statCard('👑', '$boss', 'Boss', const Color(0xFFFF4444)),
              _statCard('🧬', '$breed', 'Breed', const Color(0xFF4CAF50)),
              _statCard('⚔️', '$pvp', 'PvP', const Color(0xFFFF6B00)),
              _statCard('🌾', '$farm', 'Farm', const Color(0xFFFFD700)),
              _statCard('🦅', '$volant', 'Volants', const Color(0xFF4FC3F7)),
              _statCard('💧', '$aquatique', 'Aquatiques', AppTheme.accentSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String emoji, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.exo2(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.exo2(
              color: const Color(0xFF4A5568),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION DINOS RÉCENTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentSection(BuildContext context, DinoProvider provider) {
    final dinos = provider.allDinos.take(5).toList();
    if (dinos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'RÉCEMMENT AJOUTÉS',
                style: GoogleFonts.exo2(
                  color: const Color(0xFF6B7A8D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Liste horizontale
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: dinos.length,
              itemBuilder: (context, i) {
                return _recentDinoCard(context, dinos[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentDinoCard(BuildContext context, Dino dino) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DinoDetailScreen(dino: dino)),
      ),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dino.roleColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: Container(
                height: 72,
                color: Colors.black.withValues(alpha: 0.2),
                child: DinoImageWidget(
                  species: dino.espece,
                  regionColors: dino.colorRegions,
                  width: 110,
                  height: 72,
                  fit: BoxFit.contain,
                  showColorBand: false,
                  alignment: Alignment.center,
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dino.nom,
                      style: GoogleFonts.exo2(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Lvl ${dino.niveau}',
                      style: GoogleFonts.exo2(
                        color: dino.roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
