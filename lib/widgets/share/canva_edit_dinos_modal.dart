// lib/widgets/share/canva_edit_dinos_modal.dart
//
// Modal "Modifier les dinos" appelée depuis l'écran Canva.
//
// - Pré-coche les dinos déjà présents dans le canvas
// - Recherche par nom OU tag
// - Chips top 4 tags de l'espèce
// - Bouton "Effacer filtres" + compteur "N cachés"
// - Bouton "Tous/Aucun" + compteur X/16 (toast si > 16 au moment de valider)
// - Halo de sélection + ⭐ favori (1 max parmi cochés)
// - Bouton Valider → retourne CanvaEditResult au canvas appelant
//
// Le filtre n'efface JAMAIS les sélections : un dino coché qui sort du
// filtre reste dans _selectedIds, juste masqué de la liste affichée.

import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/dino.dart';
import '../../providers/dino_provider.dart';
import '../../providers/role_theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dino_card_widget.dart';
import 'selectable_halo.dart';

/// Résultat retourné par la modal au canvas appelant.
class CanvaEditResult {
  final List<Dino> selected;
  final Dino? favorite;
  const CanvaEditResult({required this.selected, this.favorite});
}

class CanvaEditDinosModal extends StatefulWidget {
  final String species;
  final List<Dino> initialSelection;
  final Dino? initialFavorite;
  final int maxSelection;

  const CanvaEditDinosModal({
    super.key,
    required this.species,
    this.initialSelection = const [],
    this.initialFavorite,
    this.maxSelection = 16,
  });

  /// Helper pour ouvrir la modal en bottom sheet plein écran.
  static Future<CanvaEditResult?> show({
    required BuildContext context,
    required String species,
    List<Dino> initialSelection = const [],
    Dino? initialFavorite,
    int maxSelection = 16,
  }) {
    return showModalBottomSheet<CanvaEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: CanvaEditDinosModal(
          species: species,
          initialSelection: initialSelection,
          initialFavorite: initialFavorite,
          maxSelection: maxSelection,
        ),
      ),
    );
  }

  @override
  State<CanvaEditDinosModal> createState() => _CanvaEditDinosModalState();
}

class _CanvaEditDinosModalState extends State<CanvaEditDinosModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTag = '';

  final Set<int> _selectedIds = <int>{};
  int? _favoriteId;

  @override
  void initState() {
    super.initState();
    for (final d in widget.initialSelection) {
      if (d.id != null) _selectedIds.add(d.id!);
    }
    if (widget.initialFavorite?.id != null) {
      _favoriteId = widget.initialFavorite!.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Filtrage ──────────────────────────────────────────────────────────
  List<Dino> _allOfSpecies(DinoProvider provider) {
    return provider.allDinos
        .where((d) =>
            d.espece.toLowerCase() == widget.species.toLowerCase())
        .toList();
  }

  List<String> _getTopTags(List<Dino> dinos) {
    final counts = <String, int>{};
    for (final d in dinos) {
      for (final tag in d.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return [];
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) => e.key).toList();
  }

  List<Dino> _filtered(List<Dino> source) {
    final q = _searchQuery.trim().toLowerCase();
    return source.where((d) {
      final matchesSearch = q.isEmpty ||
          d.nom.toLowerCase().contains(q) ||
          d.tags.any((t) => t.toLowerCase().contains(q));
      final matchesTag = _activeTag.isEmpty || d.tags.contains(_activeTag);
      return matchesSearch && matchesTag;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _searchQuery.isNotEmpty || _activeTag.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _activeTag = '';
    });
  }

  // ─── Sélection ─────────────────────────────────────────────────────────
  bool _allSelected(List<Dino> source) {
    final selectable = source.where((d) => d.id != null).map((d) => d.id!);
    if (selectable.isEmpty) return false;
    return selectable.every(_selectedIds.contains);
  }

  void _toggleAllOrNone(List<Dino> source) {
    setState(() {
      if (_allSelected(source)) {
        _selectedIds.clear();
        _favoriteId = null;
      } else {
        for (final d in source) {
          if (d.id != null) _selectedIds.add(d.id!);
        }
      }
    });
  }

  void _toggleOne(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_favoriteId == id) _favoriteId = null;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (!_selectedIds.contains(id)) return;
      _favoriteId = (_favoriteId == id) ? null : id;
    });
  }

  // ─── Toast 1s ──────────────────────────────────────────────────────────
  void _showCenterToast(String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              message,
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 1), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ─── Validation ────────────────────────────────────────────────────────
  void _validate(List<Dino> allOfSpecies) {
    final count = _selectedIds.length;
    if (count > widget.maxSelection) {
      _showCenterToast(
          'Sélection limitée à ${widget.maxSelection} dinos pour le Canva');
      return;
    }

    final selectedDinos = allOfSpecies
        .where((d) => d.id != null && _selectedIds.contains(d.id))
        .toList();

    Dino? favorite;
    if (_favoriteId != null) {
      for (final d in selectedDinos) {
        if (d.id == _favoriteId) {
          favorite = d;
          break;
        }
      }
    }

    Navigator.pop(
      context,
      CanvaEditResult(selected: selectedDinos, favorite: favorite),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, RoleThemeProvider>(
      builder: (context, dinoProvider, roleThemeProvider, _) {
        final allOfSpecies = _allOfSpecies(dinoProvider);
        final filtered = _filtered(allOfSpecies);
        final hiddenSelectedCount = _selectedIds.length -
            filtered
                .where(
                    (d) => d.id != null && _selectedIds.contains(d.id))
                .length;

        return Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            _buildSearchBar(),
            _buildTagChips(allOfSpecies),
            if (_hasActiveFilter)
              _buildClearFiltersBar(hiddenSelectedCount),
            _buildSelectionBar(allOfSpecies),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : _buildList(filtered, roleThemeProvider),
            ),
            _buildBottomActionBar(allOfSpecies),
          ],
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded,
              color: AppTheme.accentPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODIFIER LES DINOS',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.species.toUpperCase(),
                  style: GoogleFonts.exo2(
                    fontSize: 10,
                    color: AppTheme.accentPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF21304A), width: 1.2),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.exo2(
              color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Rechercher (nom ou tag)...',
            hintStyle: GoogleFonts.exo2(
                color: const Color(0xFF4A5568), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Color(0xFF4A5568), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF4A5568), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  Widget _buildTagChips(List<Dino> source) {
    final topTags = _getTopTags(source);
    if (topTags.isEmpty) return const SizedBox.shrink();
    final chips = ['', ...topTags];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          itemBuilder: (context, i) {
            final val = chips[i];
            final label = val.isEmpty ? 'Tous' : val;
            final isActive = _activeTag == val;
            return GestureDetector(
              onTap: () => setState(() => _activeTag = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(colors: [
                          Color(0xFFFF6B00),
                          Color(0xFFFF9500),
                        ])
                      : null,
                  color: isActive ? null : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : const Color(0xFF21304A),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.exo2(
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF6B7A8D),
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClearFiltersBar(int hiddenSelectedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          if (hiddenSelectedCount > 0) ...[
            Icon(Icons.visibility_off_rounded,
                color: AppTheme.accentPrimary.withValues(alpha: 0.7),
                size: 14),
            const SizedBox(width: 4),
            Text(
              '+$hiddenSelectedCount caché${hiddenSelectedCount > 1 ? 's' : ''} par le filtre',
              style: GoogleFonts.exo2(
                color: AppTheme.accentPrimary.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: _clearFilters,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_off_rounded,
                      color: AppTheme.danger, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Effacer filtres',
                    style: GoogleFonts.exo2(
                      color: AppTheme.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(List<Dino> allOfSpecies) {
    final count = _selectedIds.length;
    final over = count > widget.maxSelection;
    final counterColor =
        over ? AppTheme.danger : AppTheme.accentPrimary;
    final allOn = _allSelected(allOfSpecies);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleAllOrNone(allOfSpecies),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: allOn
                    ? AppTheme.accentPrimary.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: allOn
                      ? AppTheme.accentPrimary
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allOn
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: allOn
                        ? AppTheme.accentPrimary
                        : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    allOn ? 'Aucun' : 'Tous',
                    style: GoogleFonts.exo2(
                      color:
                          allOn ? AppTheme.accentPrimary : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: counterColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: counterColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              '$count/${widget.maxSelection}',
              style: GoogleFonts.exo2(
                color: counterColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          if (_favoriteId != null) ...[
            const Icon(Icons.star_rounded,
                color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 3),
            Text(
              'Favori défini',
              style: GoogleFonts.exo2(
                color: const Color(0xFFFFD700),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(List<Dino> filtered, RoleThemeProvider roleThemeProvider) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final dino = filtered[i];
        final isSelected =
            dino.id != null && _selectedIds.contains(dino.id);
        final isFav = dino.id != null && _favoriteId == dino.id;

        final tile = DinoCardWidget(
          dino: dino,
          onTap: () {},
          onEdit: () {},
          onDelete: () {},
          roleTheme: roleThemeProvider.themeForRole(dino.role),
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SelectableHalo(
              isSelected: isSelected,
              selectionMode: true,
              showFavoriteToggle: isSelected,
              isFavorite: isFav,
              onFavoriteTap: dino.id == null
                  ? null
                  : () => _toggleFavorite(dino.id!),
              onTap: () {
                if (dino.id != null) _toggleOne(dino.id!);
              },
              onLongPress: null,
              child: tile,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              _hasActiveFilter
                  ? 'Aucun résultat avec ces filtres'
                  : 'Aucun dino pour cette espèce',
              style: GoogleFonts.exo2(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          AppTheme.accentPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Effacer les filtres',
                    style: GoogleFonts.exo2(
                      color: AppTheme.accentPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(List<Dino> allOfSpecies) {
    final count = _selectedIds.length;
    final over = count > widget.maxSelection;
    final disabled = over;

    return Container(
      color: AppTheme.bgSecondary,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: disabled ? null : () => _validate(allOfSpecies),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(
                over
                    ? 'Max ${widget.maxSelection} dépassé'
                    : 'Valider ($count)',
                style: GoogleFonts.exo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                disabledBackgroundColor:
                    AppTheme.accentPrimary.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
