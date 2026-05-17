// lib/screens/share_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dino.dart';
import '../providers/dino_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/share_card/ark_dino_card_exporter.dart';
import '../utils/save_image_helper.dart'; // ← import manquant qui causait l'erreur

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool _isExporting = false;
  String? _lastSavedPath;

  // ═══════════════════════════════════════════════
  // SAUVEGARDE — délègue tout à ArkDinoCardExporter
  // Format final PNG : 1080 × 1908 (ratio 242:428 = portrait 9:16)
  // identique à ta ArkDinoCard
  // ═══════════════════════════════════════════════

  Future<void> _saveDino(Dino dino) async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _lastSavedPath = null;
    });

    try {
      final exporter = ArkDinoCardExporter(dino: dino);
      await exporter.captureAndSave(context);

      if (!mounted) return;
      setState(() {
        _lastSavedPath =
            SaveImageHelper.generateFileName(dino.espece, dino.nom);
      });
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════

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
            _buildDinoGrid(context),
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
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.save_alt_rounded,
                  color: Color(0xFF4CAF50), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde DinoCards',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Sélectionnez un dino pour sauvegarder sa DinoCard',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_lastSavedPath != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dernière sauvegarde : ${_lastSavedPath!.split('/').last}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDinoGrid(BuildContext context) {
    return Consumer<DinoProvider>(
      builder: (context, provider, _) {
        if (provider.dinos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.pets_rounded,
                      color: Colors.white.withValues(alpha: 0.2), size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun dino enregistré',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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
                  'SÉLECTIONNEZ UN DINO',
                  style: TextStyle(
                    color: AppTheme.accentSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.dinos.length} dinos',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.dinos.length,
              itemBuilder: (ctx, i) {
                final dino = provider.dinos[i];
                return _buildDinoRow(dino);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDinoRow(Dino dino) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dino.roleColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dino.roleColor.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: dino.image != null && dino.image!.isNotEmpty
                    ? Image.file(
                        File(dino.image!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => DinoImageWidget(
                          species: dino.espece,
                          regionColors: dino.colorRegions,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          showColorBand: false,
                        ),
                      )
                    : DinoImageWidget(
                        species: dino.espece,
                        regionColors: dino.colorRegions,
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        showColorBand: false,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dino.nom.isEmpty ? dino.espece : dino.nom,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dino.espece,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: dino.roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: dino.roleColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Lvl ${dino.niveau}',
                          style: TextStyle(
                            color: dino.roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bouton sauvegarde unique
            _actionIcon(
              icon: Icons.save_alt_rounded,
              color: const Color(0xFF4CAF50),
              tooltip: 'Sauvegarder la DinoCard',
              onTap: _isExporting ? null : () => _saveDino(dino),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap != null ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: onTap != null ? 0.4 : 0.1),
          ),
        ),
        child: _isExporting
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: color, size: 18),
      ),
    );
  }
}
