import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../services/backup_merge_service.dart';
import '../services/excel_backup_service.dart';
import '../theme/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isExportingJson = false;
  bool _isImportingJson = false;
  bool _isExportingExcel = false;
  bool _isImportingExcel = false;

  Future<void> _exportJson() async {
    if (_isExportingJson) return;

    setState(() => _isExportingJson = true);

    try {
      final dinoProvider = context.read<DinoProvider>();
      final trackerProvider = context.read<TrackerProvider>();

      final error = await BackupService.exportData(
        dinos: dinoProvider.allDinos,
        customTags: dinoProvider.allTags,
        trackers: trackerProvider.trackers,
      );

      if (!mounted) return;

      if (error != null) {
        _showSnack(error, isError: true);
      } else {
        _showSnack(
          'Sauvegarde JSON exportée avec succès.\n'
          '${dinoProvider.allDinos.length} dinos • ${trackerProvider.trackers.length} trackers',
          isError: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur export JSON : $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isExportingJson = false);
      }
    }
  }

  Future<void> _importJson() async {
    if (_isImportingJson) return;

    final dinoProvider = context.read<DinoProvider>();
    final trackerProvider = context.read<TrackerProvider>();

    final hasExistingData =
        dinoProvider.allDinos.isNotEmpty || trackerProvider.trackers.isNotEmpty;

    if (hasExistingData) {
      final confirm = await _showConfirmDialog(
        title: 'Importer une sauvegarde JSON',
        message:
            'Les données importées seront fusionnées avec les données existantes.\n\n'
            '• Dinos : remplacement par ID si présent\n'
            '• Tags : fusion sans doublons\n'
            '• Trackers : fusion par ID\n\n'
            'Continuer ?',
        confirmLabel: 'Importer',
        confirmColor: AppTheme.accentSecondary,
      );

      if (confirm != true) return;
    }

    setState(() => _isImportingJson = true);

    try {
      final result = await BackupService.importData();

      if (!mounted) return;

      if (result.cancelled) {
        return;
      }

      if (!result.success) {
        _showSnack(result.error ?? 'Erreur inconnue lors de l’import JSON', isError: true);
        return;
      }

      final confirm = await _showJsonPreviewDialog(result);
      if (confirm != true) return;

      final merged = BackupMergeService.mergeAll(
        existingDinos: dinoProvider.allDinos,
        importedDinos: result.dinos,
        existingTags: dinoProvider.allTags,
        importedTags: result.customTags,
        existingTrackers: trackerProvider.trackers,
        importedTrackers: result.trackers,
      );

      await dinoProvider.replaceAllData(
        dinos: merged.dinos,
        customTags: merged.customTags,
      );

      await trackerProvider.replaceAllTrackers(merged.trackers);

      if (!mounted) return;

      final warningText = result.warnings.isNotEmpty
          ? '\n⚠️ ${result.warnings.length} avertissement(s)'
          : '';

      _showSnack(
        'Import JSON réussi.\n'
        '${merged.dinos.length} dinos • ${merged.trackers.length} trackers$warningText',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur import JSON : $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isImportingJson = false);
      }
    }
  }

  Future<void> _exportExcel() async {
    if (_isExportingExcel) return;

    setState(() => _isExportingExcel = true);

    try {
      final dinoProvider = context.read<DinoProvider>();
      final trackerProvider = context.read<TrackerProvider>();

      if (dinoProvider.allDinos.isEmpty && trackerProvider.trackers.isEmpty) {
        _showSnack('Aucune donnée à exporter.', isError: true);
        return;
      }

      await ExcelBackupService().exportAndShareFullBackup(
        dinos: dinoProvider.allDinos,
        customTags: dinoProvider.allTags,
        trackers: trackerProvider.trackers,
      );

      if (!mounted) return;

      _showSnack(
        'Export Excel réussi.\n'
        '${dinoProvider.allDinos.length} dinos • ${trackerProvider.trackers.length} trackers',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur export Excel : $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isExportingExcel = false);
      }
    }
  }

  Future<void> _importExcel() async {
    if (_isImportingExcel) return;

    final dinoProvider = context.read<DinoProvider>();
    final trackerProvider = context.read<TrackerProvider>();

    final hasExistingData =
        dinoProvider.allDinos.isNotEmpty || trackerProvider.trackers.isNotEmpty;

    if (hasExistingData) {
      final confirm = await _showConfirmDialog(
        title: 'Importer depuis Excel',
        message:
            'Les données Excel seront fusionnées avec les données existantes.\n\n'
            '• Dinos : update / ajout\n'
            '• Tags : fusion\n'
            '• Trackers : fusion\n\n'
            'Continuer ?',
        confirmLabel: 'Importer Excel',
        confirmColor: const Color(0xFF107C41),
      );

      if (confirm != true) return;
    }

    setState(() => _isImportingExcel = true);

    try {
      final result = await ExcelBackupService().importFullBackupFromPicker(
        existingDinos: dinoProvider.allDinos,
      );

      if (!mounted) return;

      if (!result.success) {
        final error = result.errors.isNotEmpty
            ? result.errors.join('\n')
            : 'Erreur inconnue lors de l’import Excel';
        _showSnack(error, isError: true);
        return;
      }

      final confirm = await _showExcelPreviewDialog(result);
      if (confirm != true) return;

      final merged = BackupMergeService.mergeAll(
        existingDinos: dinoProvider.allDinos,
        importedDinos: result.importedDinos,
        existingTags: dinoProvider.allTags,
        importedTags: result.customTags,
        existingTrackers: trackerProvider.trackers,
        importedTrackers: result.importedTrackers,
      );

      await dinoProvider.replaceAllData(
        dinos: merged.dinos,
        customTags: merged.customTags,
      );

      await trackerProvider.replaceAllTrackers(merged.trackers);

      if (!mounted) return;

      final warningText = result.warnings.isNotEmpty
          ? '\n⚠️ ${result.warnings.length} avertissement(s)'
          : '';

      _showSnack(
        'Import Excel réussi.\n'
        '${merged.dinos.length} dinos • ${merged.trackers.length} trackers$warningText',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur import Excel : $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isImportingExcel = false);
      }
    }
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
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showJsonPreviewDialog(BackupImportResult result) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Aperçu JSON',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: _buildPreviewContent(
          dinos: result.dinos.length,
          tags: result.customTags.length,
          trackers: result.trackers.length,
          warnings: result.warnings,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentSecondary,
            ),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExcelPreviewDialog(FullExcelImportResult result) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Row(
          children: [
            const Text('📊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Aperçu Excel',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: _buildPreviewContent(
          dinos: result.importedDinos.length,
          tags: result.customTags.length,
          trackers: result.importedTrackers.length,
          warnings: result.warnings,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107C41),
            ),
            child: const Text(
              'Importer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent({
    required int dinos,
    required int tags,
    required int trackers,
    required List<String> warnings,
  }) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewLine('🦖', '$dinos dinosaure(s)'),
          _previewLine('🏷️', '$tags tag(s)'),
          _previewLine('🧪', '$trackers tracker(s)'),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '⚠️ AVERTISSEMENTS',
              style: TextStyle(
                color: AppTheme.warning,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: warnings
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $w',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dinoProvider = context.watch<DinoProvider>();
    final trackerProvider = context.watch<TrackerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        title: const Text('Sauvegarde & Restauration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              dinoProvider.allDinos.length,
              trackerProvider.trackers.length,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Exporter', Icons.upload_rounded),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'Export JSON',
              subtitle: 'Sauvegarde officielle complète',
              buttonLabel: _isExportingJson ? 'Export...' : 'Exporter en JSON',
              buttonColor: AppTheme.accentGreen,
              buttonTextColor: Colors.black,
              loading: _isExportingJson,
              iconBg: AppTheme.accentGreen.withOpacity(0.1),
              icon: const Icon(Icons.code, color: AppTheme.accentGreen),
              onPressed: _exportJson,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Export Excel',
              subtitle: 'Export manuel lisible/modifiable',
              buttonLabel: _isExportingExcel ? 'Export...' : 'Exporter en Excel',
              buttonColor: const Color(0xFF107C41),
              buttonTextColor: Colors.white,
              loading: _isExportingExcel,
              iconBg: const Color(0xFF107C41).withOpacity(0.15),
              icon: const Icon(Icons.table_chart, color: Color(0xFF107C41)),
              onPressed: _exportExcel,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Importer / Restaurer', Icons.download_rounded),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'Import JSON',
              subtitle: 'Fusion depuis la sauvegarde officielle',
              buttonLabel: _isImportingJson ? 'Import...' : 'Choisir fichier .json',
              buttonColor: AppTheme.accentSecondary,
              buttonTextColor: Colors.white,
              loading: _isImportingJson,
              iconBg: AppTheme.accentSecondary.withOpacity(0.1),
              icon: const Icon(Icons.code, color: AppTheme.accentSecondary),
              onPressed: _importJson,
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Import Excel',
              subtitle: 'Fusion depuis un tableur complet',
              buttonLabel: _isImportingExcel ? 'Import...' : 'Choisir fichier .xlsx',
              buttonColor: const Color(0xFF107C41),
              buttonTextColor: Colors.white,
              loading: _isImportingExcel,
              iconBg: const Color(0xFF107C41).withOpacity(0.15),
              icon: const Icon(Icons.table_chart, color: Color(0xFF107C41)),
              onPressed: _importExcel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(int dinoCount, int trackerCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0D00), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentPrimary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Text('🦖', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dinoCount dinosaure(s) • $trackerCount tracker(s)',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sauvegardez régulièrement vos données',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
          style: const TextStyle(
            color: AppTheme.accentSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required Color iconBg,
    required Widget icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required bool loading,
    required VoidCallback onPressed,
  }) {
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
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
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
