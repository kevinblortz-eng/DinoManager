import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dino_provider.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

/// Écran de gestion des sauvegardes.
/// Permet d'exporter les données en JSON et de les importer.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportData() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final provider = context.read<DinoProvider>();
    final dinos = provider.allDinos;
    final tags = provider.allTags;

    final error = await BackupService.exportDinos(
      dinos: dinos,
      customTags: tags,
    );

    if (!mounted) return;
    setState(() => _isExporting = false);

    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack(
        '${dinos.length} dino(s) exporté(s) avec succès !',
        isError: false,
      );
    }
  }

  Future<void> _importData() async {
    if (_isImporting) return;

    // Demander confirmation si des données existent déjà
    final provider = context.read<DinoProvider>();
    if (provider.allDinos.isNotEmpty) {
      final confirm = await _showConfirmDialog(
        title: 'Importer une sauvegarde',
        message:
            'Vous avez déjà ${provider.allDinos.length} dino(s) enregistré(s).\n\n'
            'L\'import FUSIONNERA les données importées avec vos dinos existants '
            '(les doublons seront ignorés).\n\n'
            'Continuer ?',
        confirmLabel: 'Importer',
        confirmColor: AppTheme.accentSecondary,
      );
      if (confirm != true) return;
    }

    setState(() => _isImporting = true);

    final result = await BackupService.importDinos();

    if (!mounted) return;
    setState(() => _isImporting = false);

    if (result.cancelled) return;

    if (!result.success) {
      _showSnack(result.error ?? 'Erreur inconnue', isError: true);
      return;
    }

    // Afficher un aperçu de ce qui va être importé
    final confirm = await _showImportPreviewDialog(result);
    if (confirm != true) return;

    // Effectuer l'import (fusion)
    int added = 0;
    int skipped = 0;
    for (final dino in result.dinos) {
      final existing = provider.allDinos.any((d) => d.id == dino.id);
      if (!existing) {
        await provider.addDino(dino);
        added++;
      } else {
        skipped++;
      }
    }

    // Ajouter les tags personnalisés manquants
    for (final tag in result.customTags) {
      if (!provider.allTags.contains(tag)) {
        await provider.addCustomTag(tag);
      }
    }

    if (!mounted) return;
    _showSnack(
      '$added dino(s) importé(s)${skipped > 0 ? ', $skipped ignoré(s) (déjà présents)' : ''}.',
      isError: false,
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(title, style: TextStyle(color: AppTheme.textPrimary)),
        content:
            Text(message, style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showImportPreviewDialog(BackupResult result) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Aperçu de l\'import',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _previewLine('🦖', '${result.dinos.length} dino(s) trouvé(s)'),
            _previewLine(
                '🏷️', '${result.customTags.length} tag(s) personnalisé(s)'),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ ${result.warnings.length} avertissement(s)',
                style: TextStyle(color: AppTheme.warning, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentSecondary),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
  }

  Widget _previewLine(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DinoProvider>();
    final dinoCount = provider.allDinos.length;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Sauvegarde & Restauration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info globale ──────────────────────────────────────────
            _buildInfoCard(dinoCount),
            const SizedBox(height: 20),

            // ── Export ───────────────────────────────────────────────
            _buildSectionTitle('Exporter', Icons.upload_rounded),
            const SizedBox(height: 8),
            _buildExportCard(),
            const SizedBox(height: 20),

            // ── Import ───────────────────────────────────────────────
            _buildSectionTitle('Importer / Restaurer', Icons.download_rounded),
            const SizedBox(height: 8),
            _buildImportCard(),
            const SizedBox(height: 20),

            // ── Guide ─────────────────────────────────────────────────
            _buildGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0D00), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('🦖', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count dino(s) dans votre collection',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sauvegardez pour ne rien perdre',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentSecondary, size: 18),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppTheme.accentSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.ios_share,
                    color: AppTheme.accentGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exporter en JSON',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Partager via Google Drive, Email, etc.',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportData,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload, size: 18),
              label: Text(_isExporting ? 'Export en cours...' : 'Exporter mes dinos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder_open,
                    color: AppTheme.accentSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importer depuis un fichier',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Restaurer ou transférer vos dinos',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importData,
              icon: _isImporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(_isImporting ? 'Import en cours...' : 'Choisir un fichier .json'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentSecondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.info, size: 18),
              const SizedBox(width: 8),
              Text(
                'Comment transférer sur un autre appareil ?',
                style: TextStyle(
                  color: AppTheme.info,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._steps.map((step) => _buildStep(step.$1, step.$2)),
        ],
      ),
    );
  }

  static const List<(String, String)> _steps = [
    ('1️⃣', 'Sur l\'appareil source → Exporter → partager vers Google Drive'),
    ('2️⃣', 'Sur le nouvel appareil → installer ARK Dino Manager'),
    ('3️⃣', 'Ouvrir Google Drive → télécharger le fichier .json'),
    ('4️⃣', 'Retour dans l\'app → Importer → sélectionner le fichier'),
    ('5️⃣', 'Vos dinos sont restaurés ! 🎉'),
  ];

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
