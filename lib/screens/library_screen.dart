import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/dino_provider.dart';
import '../providers/role_theme_provider.dart';
import '../models/dino.dart';
import '../widgets/ark_dino_card.dart';
import '../theme/app_theme.dart';
import 'dino_detail_screen.dart';
import 'add_edit_dino_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeRoleFilter = '';

  /// Calcule les 4 tags les plus utilisés dans la bibliothèque (max 4)
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DinoProvider>().loadDinos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildRoleFilterChips(),
            Expanded(child: _buildDinoList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditDinoScreen()),
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          context.read<DinoProvider>().loadDinos();
        },
        backgroundColor: AppTheme.accentPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    return Consumer<DinoProvider>(
      builder: (context, provider, _) {
        final total = provider.allDinos.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BIBLIOTHEQUE',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ARK Survival Ascended · $total dinos',
                      style: GoogleFonts.exo2(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsButton(provider: provider),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BARRE DE RECHERCHE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF21304A), width: 1.2),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.exo2(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un dino...',
                  hintStyle: GoogleFonts.exo2(
                    color: const Color(0xFF4A5568),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF4A5568),
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF4A5568), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<DinoProvider>()
                                .setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 4),
                ),
                onChanged: (v) {
                  context.read<DinoProvider>().setSearchQuery(v);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<DinoProvider>(
            builder: (_, provider, __) => GestureDetector(
              onTap: () => _showFilterSheet(context, provider),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: provider.hasActiveFilters
                      ? AppTheme.accentPrimary.withValues(alpha: 0.2)
                      : const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.hasActiveFilters
                        ? AppTheme.accentPrimary.withValues(alpha: 0.5)
                        : const Color(0xFF21304A),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: provider.hasActiveFilters
                      ? AppTheme.accentPrimary
                      : const Color(0xFF4A5568),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTER CHIPS — 4 tags les plus utilisés (dynamiques)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRoleFilterChips() {
    return Consumer<DinoProvider>(
      builder: (context, provider, _) {
        final topTags = _getTopTags(provider.allDinos);
        final chips = ['', ...topTags]; // '' = "Tous"

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
                final label = val.isEmpty ? 'Tous' : val;
                final isActive = _activeRoleFilter == val;
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeRoleFilter = val);
                    context.read<DinoProvider>().setFilterTag(val);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [
                              Color(0xFFFF6B00),
                              Color(0xFFFF9500)
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
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LISTE DES DINOS — roleThemeProvider lu via context ✅
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDinoList() {
    return Consumer2<DinoProvider, RoleThemeProvider>(
      builder: (context, provider, roleThemeProvider, _) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentPrimary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: GoogleFonts.exo2(
                    color: const Color(0xFF4A5568),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.dinos.isEmpty) {
          return _buildEmptyState(provider.hasActiveFilters, context);
        }

        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return RefreshIndicator(
          color: AppTheme.accentPrimary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: () => provider.loadDinos(),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14, 4, 14, 100 + bottomPadding),
            itemCount: provider.dinos.length,
            itemBuilder: (context, i) {
              final dino = provider.dinos[i];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ArkDinoCard(
                    dino: dino,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DinoDetailScreen(dino: dino)),
                    ).then((_) => provider.loadDinos()),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddEditDinoScreen(dino: dino)),
                    ).then((_) => provider.loadDinos()),
                    onDelete: () =>
                        _confirmDelete(context, provider, dino),
                    // ✅ Correctement lu depuis le Consumer2
                    roleTheme:
                        roleThemeProvider.themeForRole(dino.role),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool hasFilters, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🦕', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'Aucun résultat' : 'Aucun dino enregistré',
              style: GoogleFonts.cinzelDecorative(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Modifiez vos filtres'
                  : 'Appuyez sur + pour ajouter votre premier dino',
              style: GoogleFonts.exo2(
                color: const Color(0xFF4A5568),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddEditDinoScreen()),
                ).then((_) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  context.read<DinoProvider>().loadDinos();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B00)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Ajouter un dino',
                    style: GoogleFonts.exo2(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  void _showFilterSheet(BuildContext context, DinoProvider provider) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(provider: provider),
    );
  }

  void _confirmDelete(
      BuildContext context, DinoProvider provider, Dino dino) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Supprimer ${dino.nom} ?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (dino.id != null) {
                provider.deleteDino(dino.id!);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOUTON SETTINGS
// ══════════════════════════════════════════════════════════════════════════════
class _SettingsButton extends StatelessWidget {
  final DinoProvider provider;
  const _SettingsButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStatsDialog(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Icon(
          Icons.bar_chart_rounded,
          color: Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    final dinos = provider.allDinos;

    final tagStats = <String, int>{};
    for (final dino in dinos) {
      for (final tag in dino.tags) {
        tagStats[tag] = (tagStats[tag] ?? 0) + 1;
      }
    }

    const priorityTags = [
      'Boss', 'Breed', 'Solid', 'Farm', 'Volant', 'Aquatique'
    ];
    final sortedTags = [
      ...priorityTags.where((t) => tagStats.containsKey(t)),
      ...tagStats.keys
          .where((t) => !priorityTags.contains(t))
          .toList()
        ..sort()
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFFAA00)],
                    ).createShader(b),
                    child: Text(
                      'STATISTIQUES',
                      style: GoogleFonts.cinzelDecorative(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Fonctionnalité bientôt disponible')),
                    );
                  },
                  icon: const Icon(Icons.save_alt,
                      size: 16, color: AppTheme.accentSecondary),
                  label: const Text('Sauvegarder',
                      style: TextStyle(
                          color: AppTheme.accentSecondary,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _statTile('🦖', '${dinos.length}', 'Total',
                AppTheme.accentPrimary),
            const SizedBox(height: 4),
            if (sortedTags.isEmpty)
              const Text('Aucun tag utilisé',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 12))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedTags.map((tag) {
                  final count = tagStats[tag] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$count',
                            style: const TextStyle(
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            )),
                        const SizedBox(width: 5),
                        Text(tag,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statTile(
      String emoji, String count, String label, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(count,
            style: GoogleFonts.exo2(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET FILTRES
// ══════════════════════════════════════════════════════════════════════════════
class _FilterSheet extends StatelessWidget {
  final DinoProvider provider;
  const _FilterSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FILTRES',
            style: GoogleFonts.cinzelDecorative(
              color: AppTheme.accentSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _filterRow(
              context,
              'Sexe',
              ['', ...Dino.sexesDisponibles],
              provider.filterSexe,
              provider.setFilterSexe),
          const SizedBox(height: 12),
          _filterRow(
              context,
              'Espèce',
              ['', ...Dino.especesDisponibles.take(12)],
              provider.filterEspece,
              provider.setFilterEspece),
          const SizedBox(height: 12),
          _filterRowTags(context, provider),
          const SizedBox(height: 12),
          if (provider.hasActiveFilters) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                provider.clearFilters();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Réinitialiser les filtres',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo2(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterRowTags(BuildContext context, DinoProvider provider) {
    // Tous les tags présents dans la collection
    final usedTags = <String>{};
    for (final d in provider.allDinos) {
      usedTags.addAll(d.tags);
    }
    if (usedTags.isEmpty) return const SizedBox.shrink();

    final sortedTags = usedTags.toList()..sort();
    final opts = ['', ...sortedTags];
    final current = provider.filterTag;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tag',
            style: GoogleFonts.exo2(
              color: const Color(0xFF6B7A8D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: opts.map((opt) {
            final isActive = current == opt;
            return GestureDetector(
              onTap: () {
                provider.setFilterTag(isActive ? '' : opt);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(colors: [
                          Color(0xFFFF6B00),
                          Color(0xFFFF9500)
                        ])
                      : null,
                  color: isActive ? null : const Color(0xFF1C2333),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : const Color(0xFF2D3748),
                  ),
                ),
                child: Text(
                  opt.isEmpty ? 'Tous' : opt,
                  style: GoogleFonts.exo2(
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF6B7A8D),
                    fontSize: 12,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _filterRow(
    BuildContext context,
    String label,
    List<String> opts,
    String current,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.exo2(
              color: const Color(0xFF6B7A8D),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: opts.take(10).map((opt) {
            final isActive = current == opt;
            return GestureDetector(
              onTap: () {
                onChanged(isActive ? '' : opt);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(colors: [
                          Color(0xFFFF6B00),
                          Color(0xFFFF9500)
                        ])
                      : null,
                  color: isActive ? null : const Color(0xFF1C2333),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : const Color(0xFF2D3748),
                  ),
                ),
                child: Text(
                  opt.isEmpty ? 'Tous' : opt,
                  style: GoogleFonts.exo2(
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF6B7A8D),
                    fontSize: 12,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
