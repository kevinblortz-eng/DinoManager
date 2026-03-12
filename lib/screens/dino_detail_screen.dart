import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dino.dart';
import '../models/ark_color_palette.dart';
import '../theme/app_theme.dart';
import '../providers/dino_provider.dart';
import '../widgets/dino_image_widget.dart';
import 'add_edit_dino_screen.dart';

class DinoDetailScreen extends StatefulWidget {
  final Dino dino;
  const DinoDetailScreen({super.key, required this.dino});

  @override
  State<DinoDetailScreen> createState() => _DinoDetailScreenState();
}

class _DinoDetailScreenState extends State<DinoDetailScreen> {
  late Dino _dino;

  @override
  void initState() {
    super.initState();
    _dino = widget.dino;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          _dino.espece,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          // Modifier
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppTheme.accentSecondary),
            tooltip: 'Modifier',
            onPressed: _editDino,
          ),
          // Dupliquer
          IconButton(
            icon: Icon(Icons.copy_all_rounded, color: AppTheme.accentGreen),
            tooltip: 'Dupliquer',
            onPressed: _duplicateDino,
          ),
          // Supprimer
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
            tooltip: 'Supprimer',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDinoCard(),
            const SizedBox(height: 16),
            if (_dino.notes.isNotEmpty) _buildNotesCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CARTE PRINCIPALE DINO (format "partage")
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDinoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.bgCard,
            AppTheme.bgSecondary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _dino.roleColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _dino.roleColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne 1 : Espèce (adaptative) ──────────────────────────────
          _buildSpeciesHeader(),
          // ── Ligne 2 : Nom personnel ─────────────────────────────────────
          _buildNameRow(),
          // ── Ligne 3 : Image + Couleurs régionales ───────────────────────
          _buildImageAndColors(),
          // ── Ligne 4 : Stats ─────────────────────────────────────────────
          _buildStatsSection(),
          // ── Boutons d'action ────────────────────────────────────────────
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ── Espèce (première ligne, taille adaptative) ──────────────────────────
  Widget _buildSpeciesHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _dino.roleColor.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          // Espèce — taille de police qui s'adapte
          Expanded(
            child: Text(
              _dino.espece,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // FittedBox adapte la taille de police pour tenir sur 1 ligne
            ),
          ),
          const SizedBox(width: 8),
          // Niveau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Lvl ${_dino.niveau}',
              style: TextStyle(
                color: AppTheme.accentPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Rôle badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _dino.roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _dino.roleColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              _dino.role,
              style: TextStyle(
                color: _dino.roleColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Sexe
          if (_dino.sexe != 'Inconnu') ...[
            const SizedBox(width: 6),
            Text(
              _dino.sexeSymbol,
              style: TextStyle(
                color: _dino.sexeColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Nom personnel ──────────────────────────────────────────────────────
  Widget _buildNameRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        _dino.nom,
        style: TextStyle(
          color: AppTheme.accentSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Image + Couleurs régionales côte à côte ──────────────────────────
  Widget _buildImageAndColors() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du dino avec couleurs dynamiques
          Expanded(
            flex: 5,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: DinoImageWidget(
                species: _dino.espece,
                regionColors: _dino.colorRegions,
                width: double.infinity,
                height: 160,
                showColorBand: false,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Couleurs régionales avec numéros ARK
          Expanded(
            flex: 4,
            child: _buildColorRegions(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRegions() {
    final regionLabels = ['Corps', 'Tête', 'Dos', 'Ventre', 'Pattes', 'Queue'];
    final ids = _dino.colorIds;
    final hexes = _dino.colorRegions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(6, (i) {
        final id = i < ids.length ? ids[i] : 0;
        final hex = i < hexes.length ? hexes[i] : null;
        final isActive = id > 0 && hex != null && hex != '#808080' && hex != '#7F7F7F';
        final arkColor = isActive ? ArkColorPalette.fromId(id) : null;
        final color = isActive ? _parseHex(hex) : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? color!.withValues(alpha: 0.12)
                : AppTheme.bgPrimary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isActive
                  ? color!.withValues(alpha: 0.5)
                  : AppTheme.borderColor.withValues(alpha: 0.2),
              width: isActive ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            children: [
              // Carré de couleur
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: isActive ? color : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive
                        ? color!.withValues(alpha: 0.8)
                        : AppTheme.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: isActive
                    ? null
                    : Icon(Icons.block, size: 10, color: AppTheme.textMuted.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 6),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      regionLabels[i],
                      style: TextStyle(
                        color: isActive ? AppTheme.textSecondary : AppTheme.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isActive)
                      Text(
                        '#$id${arkColor != null ? ' · ${arkColor.name}' : ''}',
                        style: TextStyle(
                          color: color!.withValues(alpha: 0.9),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Inactif',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre section
            Text(
              'STATS',
              style: TextStyle(
                color: AppTheme.accentSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            // Grid 2 colonnes – toutes les 7 stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche : HP, Énergie, Nourriture, Vitesse
                Expanded(
                  child: Column(
                    children: [
                      _statRow('❤️', 'Vie', _dino.hp, _dino.hpPoints, AppTheme.danger),
                      const SizedBox(height: 6),
                      _statRow('⚡', 'Stamina', _dino.stamina, _dino.staminaPoints, const Color(0xFFFFD700)),
                      const SizedBox(height: 6),
                      _statRow('🍗', 'Nourriture', _dino.nourriture, _dino.nourriturePoints, const Color(0xFF8BC34A)),
                      const SizedBox(height: 6),
                      _statRowDouble('💨', 'Vitesse', _dino.vitesse, _dino.vitessePoints, const Color(0xFF00E5FF), suffix: '%'),
                    ],
                  ),
                ),
                Container(width: 1, height: 110, color: AppTheme.borderColor.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 10)),
                // Colonne droite : Attaque, Poids, Oxygène
                Expanded(
                  child: Column(
                    children: [
                      _statRowDouble('⚔️', 'Attaque', _dino.degats, _dino.degatsPoints, AppTheme.danger, suffix: '%'),
                      const SizedBox(height: 6),
                      _statRow('🎒', 'Poids', _dino.poids, _dino.poidsPoints, const Color(0xFF2196F3)),
                      const SizedBox(height: 6),
                      _statRow('🌊', 'Oxygène', _dino.oxygene, _dino.oxygenePoints, const Color(0xFF00BCD4)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String icon, String label, int value, int points, Color color) {
    return _buildStatLine(icon, label, '$value', points, color);
  }

  Widget _statRowDouble(String icon, String label, double value, int points, Color color, {String suffix = ''}) {
    return _buildStatLine(icon, label, '${value.toStringAsFixed(1)}$suffix', points, color);
  }

  Widget _buildStatLine(String icon, String label, String value, int points, Color color) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Points investis – toujours affichés
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: points > 0
                          ? AppTheme.accentGreen.withValues(alpha: 0.12)
                          : AppTheme.borderColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: points > 0
                            ? AppTheme.accentGreen.withValues(alpha: 0.25)
                            : AppTheme.borderColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${points}pts',
                      style: TextStyle(
                        color: points > 0 ? AppTheme.accentGreen : AppTheme.textMuted,
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
      ],
    );
  }

  // ── Boutons d'action ──────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Row(
        children: [
          // Modifier
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editDino,
              icon: Icon(Icons.edit_rounded, size: 16, color: AppTheme.accentSecondary),
              label: Text(
                'Modifier',
                style: TextStyle(color: AppTheme.accentSecondary, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.accentSecondary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Dupliquer
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _duplicateDino,
              icon: Icon(Icons.copy_all_rounded, size: 16, color: AppTheme.accentGreen),
              label: Text(
                'Dupliquer',
                style: TextStyle(color: AppTheme.accentGreen, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Partager (placeholder)
          OutlinedButton(
            onPressed: () => _showComingSoon(context, 'Partage'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.accentPrimary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Icon(Icons.share_rounded, size: 18, color: AppTheme.accentPrimary),
          ),
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────
  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 14, color: AppTheme.accentSecondary),
              const SizedBox(width: 6),
              Text(
                'NOTES',
                style: TextStyle(
                  color: AppTheme.accentSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dino.notes,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _editDino() async {
    final updated = await Navigator.push<Dino>(
      context,
      MaterialPageRoute(builder: (_) => AddEditDinoScreen(dino: _dino)),
    );
    if (updated != null && mounted) {
      setState(() => _dino = updated);
    }
  }

  Future<void> _duplicateDino() async {
    // Crée une copie sans ID (nouveau dino) avec nom modifié
    final copy = _dino.copyWith(
      id: null,
      nom: '${_dino.nom} (copie)',
      dateAjout: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditDinoScreen(dino: copy, isDuplicate: true)),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Supprimer ${_dino.nom}?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Cette action est irréversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (_dino.id != null) {
        await Provider.of<DinoProvider>(context, listen: false).deleteDino(_dino.id!);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — Disponible prochainement'),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return null;
  }
}
