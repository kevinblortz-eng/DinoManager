// lib/screens/dino_canva_multi_picker_screen.dart
//
// Sélection des dinos pour le Canva MULTI-ESPÈCES.
// Ouverture : Navigator.push<DinoCanvaMultiPickerResult>
// Fermeture : Navigator.pop(context, DinoCanvaMultiPickerResult(...))
//
// Diffère du picker mono-espèce sur 3 points :
//   1. Pas de filtre fixe par espèce → toutes les espèces sont listées.
//   2. Chips de filtre rapide PAR ESPÈCE en haut (en plus du filtre tag).
//   3. Garde-fou immédiat : impossible de sélectionner au-delà de 16,
//      toast affiché au moment de la tentative.

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../providers/dino_provider.dart';
import '../providers/role_theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dino_helpers.dart';
import '../widgets/dino_card_widget.dart';
import '../widgets/share/selectable_halo.dart';

/// Résultat retourné par le picker multi.
class DinoCanvaMultiPickerResult {
  final List<Dino> selected;
  final Dino? favorite;
  const DinoCanvaMultiPickerResult({
    required this.selected,
    this.favorite,
  });
}

class DinoCanvaMultiPickerScreen extends StatefulWidget {
  final List<Dino> initialSelection;
  final Dino? initialFavorite;

  const DinoCanvaMultiPickerScreen({
    super.key,
    this.initialSelection = const [],
    this.initialFavorite,
  });

  @override
  State<DinoCanvaMultiPickerScreen> createState() =>
      _DinoCanvaMultiPickerScreenState();
}

class _DinoCanvaMultiPickerScreenState
    extends State<DinoCanvaMultiPickerScreen> {
  static const int _maxCanva = 16;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTag = '';
  String _activeSpecies = ''; // '' = toutes espèces

  final Set<int> _selectedIds = <int>{};
  int? _favoriteId;

  @override
  void initState() {
    super.initState();
    for (final d in widget.initialSelection) {
      if (d.id != null) _selectedIds.add(d.id!);
    }
    _favoriteId = widget.initialFavorite?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DinoProvider>().loadDinos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────────────────

  /// Liste de toutes les espèces présentes, triées par effectif décroissant.
  List<String> _allSpecies(DinoProvider provider) {
    final counts = <String, int>{};
    for (final d in provider.allDinos) {
      counts[d.espece] = (counts[d.espece] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
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
          d.espece.toLowerCase().contains(q) ||
          d.tags.any((t) => t.toLowerCase().contains(q));
      final matchesTag = _activeTag.isEmpty || d.tags.contains(_activeTag);
      final matchesSpecies = _activeSpecies.isEmpty ||
          d.espece.toLowerCase() == _activeSpecies.toLowerCase();
      return matchesSearch && matchesTag && matchesSpecies;
    }).toList();
  }

  bool get _hasActiveFilter =>
      _searchQuery.isNotEmpty ||
      _activeTag.isNotEmpty ||
      _activeSpecies.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _activeTag = '';
      _activeSpecies = '';
    });
  }

  // ─── Selection ────────────────────────────────────────────────────────

  bool _allFilteredSelected(List<Dino> source) {
    final selectable = source.where((d) => d.id != null).map((d) => d.id!);
    if (selectable.isEmpty) return false;
    return selectable.every(_selectedIds.contains);
  }

  void _toggleAllOrNone(List<Dino> visible) {
    setState(() {
      if (_allFilteredSelected(visible)) {
        // Désélectionne uniquement les dinos visibles
        for (final d in visible) {
          if (d.id != null) _selectedIds.remove(d.id);
        }
        if (_favoriteId != null && !_selectedIds.contains(_favoriteId)) {
          _favoriteId = null;
        }
      } else {
        bool overflow = false;
        for (final d in visible) {
          if (d.id == null) continue;
          if (_selectedIds.contains(d.id)) continue;
          if (_selectedIds.length >= _maxCanva) {
            overflow = true;
            break;
          }
          _selectedIds.add(d.id!);
        }
        if (overflow) {
          _showCenterToast('Maximum $_maxCanva dinos atteint');
        }
      }
    });
  }

  void _toggleOne(int id) {
    if (_selectedIds.contains(id)) {
      setState(() {
        _selectedIds.remove(id);
        if (_favoriteId == id) _favoriteId = null;
      });
    } else {
      if (_selectedIds.length >= _maxCanva) {
        _showCenterToast('Maximum $_maxCanva dinos atteint');
        return;
      }
      setState(() {
        _selectedIds.add(id);
      });
    }
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (!_selectedIds.contains(id)) return;
      _favoriteId = (_favoriteId == id) ? null : id;
    });
  }

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
                color: AppTheme.danger.withValues(alpha: 0.6),
                width: 1.2,
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
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _validate(List<Dino> allDinos) {
    final count = _selectedIds.length;
    if (count == 0) return;
    if (count > _maxCanva) {
      _showCenterToast('Sélection limitée à $_maxCanva dinos');
      return;
    }

    final selectedDinos = allDinos
        .where((d) => d.id != null && _selectedIds.contains(d.id))
        .toList()
      // Tri : espèce puis nom (regroupe visuellement les espèces dans le canva)
      ..sort((a, b) {
        final s = a.espece.toLowerCase().compareTo(b.espece.toLowerCase());
        if (s != 0) return s;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });

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
      DinoCanvaMultiPickerResult(
        selected: selectedDinos,
        favorite: favorite,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Consumer2<DinoProvider, RoleThemeProvider>(
          builder: (context, dinoProvider, roleThemeProvider, _) {
            final allDinos = dinoProvider.allDinos;
            final allSpecies = _allSpecies(dinoProvider);
            // Tags top : calculés sur l'espèce active si filtrée, sinon global
            final tagSource = _activeSpecies.isEmpty
                ? allDinos
                : allDinos
                    .where((d) =>
                        d.espece.toLowerCase() ==
                        _activeSpecies.toLowerCase())
                    .toList();

            final filtered = _filtered(allDinos);
            final hiddenSelectedCount = _selectedIds.length -
                filtered
                    .where(
                        (d) => d.id != null && _selectedIds.contains(d.id))
                    .length;

            return Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildSpeciesChips(allSpecies),
                _buildTagChips(tagSource),
                if (_hasActiveFilter)
                  _buildClearFiltersBar(hiddenSelectedCount),
                _buildSelectionBar(filtered),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : _buildList(filtered, roleThemeProvider),
                ),
                _buildBottomActionBar(allDinos),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 4),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SÉLECTION',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'TOUTES ESPÈCES',
                  style: GoogleFonts.exo2(
                    fontSize: 11,
                    color: AppTheme.accentPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
            hintText: 'Rechercher (nom, espèce ou tag)...',
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

  Widget _buildSpeciesChips(List<String> allSpecies) {
    if (allSpecies.isEmpty) return const SizedBox.shrink();
    final chips = ['', ...allSpecies];

    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          itemBuilder: (context, i) {
            final val = chips[i];
            final label = val.isEmpty
                ? 'Toutes espèces'
                : DinoHelpers.toTitleCase(val);
            final isActive = _activeSpecies == val;
            return GestureDetector(
              onTap: () => setState(() => _activeSpecies = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(colors: [
                          Color(0xFF00BCD4),
                          Color(0xFF00E5FF),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (val.isEmpty)
                      Icon(
                        Icons.public_rounded,
                        size: 13,
                        color: isActive
                            ? Colors.black
                            : const Color(0xFF6B7A8D),
                      )
                    else
                      Icon(
                        Icons.pets_rounded,
                        size: 13,
                        color: isActive
                            ? Colors.black
                            : const Color(0xFF6B7A8D),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: GoogleFonts.exo2(
                        color: isActive
                            ? Colors.black
                            : const Color(0xFF6B7A8D),
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagChips(List<Dino> source) {
    final topTags = _getTopTags(source);
    if (topTags.isEmpty) return const SizedBox.shrink();
    final chips = ['', ...topTags];

    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          itemBuilder: (context, i) {
            final val = chips[i];
            final label = val.isEmpty ? 'Tous tags' : val;
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
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
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

  Widget _buildSelectionBar(List<Dino> visible) {
    final count = _selectedIds.length;
    final over = count > _maxCanva;
    final empty = count == 0;
    final atMax = count >= _maxCanva;
    final counterColor = over
        ? AppTheme.danger
        : (atMax
            ? const Color(0xFFFFD700)
            : (empty ? AppTheme.danger : AppTheme.accentPrimary));
    final allOn = _allFilteredSelected(visible);

    // Comptage des espèces représentées dans la sélection
    final speciesInSelection = <String>{};
    for (final d in visible) {
      if (d.id != null && _selectedIds.contains(d.id)) {
        speciesInSelection.add(d.espece);
      }
    }

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
            onTap: () => _toggleAllOrNone(visible),
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
                    allOn ? 'Aucun' : 'Tous (visibles)',
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
              '$count/$_maxCanva',
              style: GoogleFonts.exo2(
                color: counterColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (speciesInSelection.length > 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets_rounded,
                      color: Color(0xFF00E5FF), size: 12),
                  const SizedBox(width: 3),
                  Text(
                    '${speciesInSelection.length} esp.',
                    style: GoogleFonts.exo2(
                      color: const Color(0xFF00E5FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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

  Widget _buildList(
    List<Dino> filtered,
    RoleThemeProvider roleThemeProvider,
  ) {
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
                  : 'Aucun dino dans la bibliothèque',
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
                    color:
                        AppTheme.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentPrimary
                          .withValues(alpha: 0.4),
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

  Widget _buildBottomActionBar(List<Dino> allDinos) {
    final count = _selectedIds.length;
    final over = count > _maxCanva;
    final empty = count == 0;
    final disabled = over || empty;
    final systemBottom = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + systemBottom),
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
              onPressed: disabled ? null : () => _validate(allDinos),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: Text(
                over
                    ? 'Max $_maxCanva dépassé'
                    : empty
                        ? 'Aucun dino'
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
