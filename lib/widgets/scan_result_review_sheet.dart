// lib/widgets/scan_result_review_sheet.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dino_ocr_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Bottom sheet de confirmation du résultat OCR avant transfert sur la DinoCard
// ─────────────────────────────────────────────────────────────────────────────
class ScanResultReviewSheet extends StatefulWidget {
  final DinoOcrResult            result;
  final ValueChanged<DinoOcrResult> onConfirm;
  final VoidCallback             onRetry;

  const ScanResultReviewSheet({
    super.key,
    required this.result,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  State<ScanResultReviewSheet> createState() => _ScanResultReviewSheetState();
}

class _ScanResultReviewSheetState extends State<ScanResultReviewSheet> {
  // Résultat potentiellement édité localement
  late DinoOcrResult _result;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1E28),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Poignée ──
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── En-tête ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _sourceColor(_result.sourceType).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _sourceColor(_result.sourceType).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _result.sourceType.label.toUpperCase(),
                      style: TextStyle(
                        color: _sourceColor(_result.sourceType),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Résultats du scan',
                      style: GoogleFonts.exo2(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: widget.onRetry,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            // ── Contenu scrollable ──
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _buildIdentitySection(),
                  const SizedBox(height: 16),
                  _buildStatsSection(),
                  const SizedBox(height: 16),
                  _buildColorsSection(),
                  if (_result.mutationsMale != null ||
                      _result.mutationsFemale != null) ...[
                    const SizedBox(height: 16),
                    _buildMutationsSection(),
                  ],
                  if ((_result.imprintPercent ?? 0) > 0) ...[
                    const SizedBox(height: 16),
                    _buildImprintSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildRawTextSection(),
                ],
              ),
            ),
            // ── Boutons ──
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildIdentitySection() {
    return _card(
      title: 'Identification',
      icon:  Icons.pets,
      children: [
        _row('Espèce',  _result.species   ?? '—'),
        _row('Niveau',  _result.level?.toString() ?? '—'),
        _row('Sexe',    _result.sex       ?? '—'),
        _row('Statut',  _result.status    ?? '—'),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      ('HP',       _result.hp),
      ('Stamina',  _result.stamina),
      ('Oxygène',  _result.oxygen),
      ('Nourriture', _result.food),
      ('Poids',    _result.weight),
      ('Mêlée',    _result.melee),
    ];

    return _card(
      title: 'Statistiques',
      icon:  Icons.bar_chart,
      children: stats.map((s) {
        final stat = s.$2;
        if (stat == null) return const SizedBox.shrink();
        final valueStr = stat.isPercent
            ? '${stat.maxValue?.toStringAsFixed(1)}%'
            : stat.maxValue?.toStringAsFixed(0) ?? '—';
        final ptsStr = stat.totalPoints > 0
            ? '  (${stat.pointsDisplay} pts)'
            : '';
        return _row(s.$1, '$valueStr$ptsStr');
      }).toList(),
    );
  }

  Widget _buildColorsSection() {
    return _card(
      title: 'Couleurs ARK',
      icon:  Icons.palette,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_result.colorIds.length, (i) {
            final id = _result.colorIds[i];
            return _colorChip(i, id);
          }),
        ),
      ],
    );
  }

  Widget _colorChip(int index, int colorId) {
    final bool hasColor = colorId > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasColor ? Colors.white38 : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          Text('R$index',
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
          const SizedBox(height: 2),
          Text(
            hasColor ? 'ID $colorId' : 'Aucune',
            style: TextStyle(
              color: hasColor ? Colors.white : Colors.white24,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutationsSection() {
    return _card(
      title: 'Mutations',
      icon:  Icons.science,
      children: [
        _row('♂ Mâle',   _result.mutationsMale?.toString()   ?? '—'),
        _row('♀ Femelle', _result.mutationsFemale?.toString() ?? '—'),
      ],
    );
  }

  Widget _buildImprintSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.child_care, color: Colors.orange.shade300, size: 16),
              const SizedBox(width: 6),
              Text('Imprint détecté',
                  style: TextStyle(
                      color: Colors.orange.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          _row('Pourcentage',
              '${_result.imprintPercent?.toStringAsFixed(1)}%'),
          if (_result.imprinter != null)
            _row('Par', _result.imprinter!),
          const SizedBox(height: 4),
          Text(
            '⚠️ Les stats HP/Stamina/Poids/Mêlée ont été corrigées à 0% imprint.',
            style: TextStyle(color: Colors.orange.shade200, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildRawTextSection() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      iconColor:   Colors.white38,
      title: Text('Texte brut OCR',
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            _result.rawText.isEmpty ? '(aucun texte détecté)' : _result.rawText,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BARRE D'ACTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.only(
        left:   20,
        right:  20,
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
        color: Color(0xFF1A1E28),
      ),
      child: Row(
        children: [
          // Bouton reprendre
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onRetry,
              icon:  const Icon(Icons.camera_alt, size: 16),
              label: const Text('Reprendre'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side:            const BorderSide(color: Colors.white24),
                padding:         const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bouton confirmer
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => widget.onConfirm(_result),
              icon:  const Icon(Icons.check, size: 18),
              label: const Text(
                'TRANSFÉRER SUR LA DINOCARD',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                padding:         const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS UI
  // ─────────────────────────────────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00E5FF), size: 15),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.exo2(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _sourceColor(OcrSourceType t) {
    return switch (t) {
      OcrSourceType.tekBinoculars  => const Color(0xFF00E5FF),
      OcrSourceType.cryopodTooltip => const Color(0xFF64B5F6),
      _                            => Colors.white54,
    };
  }
}
