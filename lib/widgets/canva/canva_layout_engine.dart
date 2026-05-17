// lib/widgets/canva/canva_layout_engine.dart
//
// ╔════════════════════════════════════════════════════════════════════════╗
// ║ MOTEUR DE LAYOUT DU CANVA                                             ║
// ║                                                                        ║
// ║ Calcule la position de chaque bulle (dinos + stats optionnelle) dans  ║
// ║ une zone rectangulaire (4:5 ou 1080×1350).                            ║
// ║                                                                        ║
// ║ Règles :                                                              ║
// ║   - Recherche auto de la meilleure grille (cols × rows) qui maximise  ║
// ║     la surface de chaque bulle, avec ratio proche du carré.           ║
// ║   - Les lignes du HAUT sont les plus chargées.                        ║
// ║   - La bulle stats est TOUJOURS sur la dernière ligne et s'étire pour ║
// ║     combler toutes les colonnes restantes (min 2 colonnes).           ║
// ║   - Si la dernière ligne (sans stats) contient moins de dinos que la  ║
// ║     ligne du dessus → ces dinos sont centrés horizontalement.         ║
// ║                                                                        ║
// ║ Logique pure : aucune dépendance UI, juste dart:ui pour Rect/Size.    ║
// ╚════════════════════════════════════════════════════════════════════════╝
import 'dart:ui';

/// Résultat d'un calcul de placement.
class CanvaPlacements {
  /// Position de chaque bulle dino, dans l'ordre fourni par l'appelant.
  final List<Rect> dinoSlots;

  /// Position de la bulle stats (null si non demandée).
  final Rect? statsRect;

  const CanvaPlacements({
    required this.dinoSlots,
    this.statsRect,
  });
}

/// Forme d'une grille (utilitaire interne).
class GridShape {
  final int rows;
  final int cols;
  const GridShape(this.rows, this.cols);
}

/// Moteur statique de calcul de layout.
class CanvaLayout {
  /// Espace entre deux bulles (à exportScale = 1.0).
  static const double _baseGap = 6;

  /// Marge intérieure de la zone canva (à exportScale = 1.0).
  static const double _basePadding = 8;

  /// Taille minimale d'une cellule pour qu'elle soit considérée valide.
  static const double _minCellSize = 30;

  /// Borne haute sur le nombre de colonnes testées.
  static const int _maxColsToTry = 6;

  /// Calcule le placement des N bulles + la stats optionnelle.
  ///
  /// - [nDinos] : nombre de bulles dinos à placer (≥ 0).
  /// - [withStatsBubble] : true pour inclure la bulle stats (compte pour 2 cells).
  /// - [zoneSize] : taille totale disponible pour le canva.
  /// - [scale] : facteur d'échelle (1.0 écran, 2.5 export par ex.).
  static CanvaPlacements compute({
    required int nDinos,
    required bool withStatsBubble,
    required Size zoneSize,
    double scale = 1.0,
  }) {
    final gap = _baseGap * scale;
    final padding = _basePadding * scale;

    // Cas trivial : rien à placer
    if (nDinos == 0 && !withStatsBubble) {
      return const CanvaPlacements(dinoSlots: []);
    }

    // Zone utile (zone - padding)
    final area = Rect.fromLTWH(
      padding,
      padding,
      zoneSize.width - 2 * padding,
      zoneSize.height - 2 * padding,
    );

    if (area.width <= 0 || area.height <= 0) {
      return const CanvaPlacements(dinoSlots: []);
    }

    // ── Cas spécial : 1 dino + stats → split 50/50 horizontal ─────────
    if (nDinos == 1 && withStatsBubble) {
      final w = (area.width - gap) / 2;
      return CanvaPlacements(
        dinoSlots: [Rect.fromLTWH(area.left, area.top, w, area.height)],
        statsRect:
            Rect.fromLTWH(area.left + w + gap, area.top, w, area.height),
      );
    }

    // ── Cas spécial : 0 dino + stats seul → stats remplit toute la zone
    if (nDinos == 0 && withStatsBubble) {
      return CanvaPlacements(
        dinoSlots: const [],
        statsRect: area,
      );
    }

    // ── Cas général : recherche de la meilleure grille ────────────────
    final best = _findBestLayout(
      nDinos: nDinos,
      withStatsBubble: withStatsBubble,
      area: area,
      gap: gap,
    );

    if (best == null) {
      return const CanvaPlacements(dinoSlots: []);
    }

    return _buildPlacements(
      shape: best,
      nDinos: nDinos,
      withStatsBubble: withStatsBubble,
      area: area,
      gap: gap,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Recherche auto de la meilleure grille
  // ─────────────────────────────────────────────────────────────────────

  /// Cherche la grille (cols × rows) qui maximise la surface des bulles
  /// dinos tout en gardant un ratio cellule proche du carré.
  ///
  /// Score = surface_cellule / pénalité_ratio / pénalité_remplissage
  static GridShape? _findBestLayout({
    required int nDinos,
    required bool withStatsBubble,
    required Rect area,
    required double gap,
  }) {
    final statsUnits = withStatsBubble ? 2 : 0;
    final totalUnits = nDinos + statsUnits;

    GridShape? best;
    double bestScore = double.negativeInfinity;

    final maxCols = totalUnits.clamp(1, _maxColsToTry);

    for (int cols = 1; cols <= maxCols; cols++) {
      final rows = (totalUnits / cols).ceil();
      final cellW = (area.width - gap * (cols - 1)) / cols;
      final cellH = (area.height - gap * (rows - 1)) / rows;

      // Cellule trop petite → on ignore cette config
      if (cellW <= _minCellSize || cellH <= _minCellSize) continue;

      // La stats occupe 2 cellules adjacentes → cols ≥ 2 requis
      if (withStatsBubble && cols < 2) continue;

      // Il faut au moins nDinos cellules libres après la stats
      final dinoCellsAvailable = rows * cols - statsUnits;
      if (dinoCellsAvailable < nDinos) continue;

      final cellArea = cellW * cellH;
      final cellRatio = cellW / cellH;
      final ratioPenalty = cellRatio > 1 ? cellRatio : 1 / cellRatio;

      final emptyCells = (rows * cols) - totalUnits;
      final fillPenalty = 1 + emptyCells * 0.05;

      final score = (cellArea / ratioPenalty) / fillPenalty;

      if (score > bestScore) {
        bestScore = score;
        best = GridShape(rows, cols);
      }
    }
    return best;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Construction effective des rectangles
  // ─────────────────────────────────────────────────────────────────────

  /// Place les dinos et la stats dans la grille choisie.
  ///
  ///  - lignes du haut chargées (max dinos par ligne du haut)
  ///  - dernière ligne avec stats : stats s'étire pour combler la ligne
  ///  - dernière ligne sans stats incomplète : dinos centrés horizontalement
  ///    (par rapport à la ligne du dessus, pas par rapport à cols)
  static CanvaPlacements _buildPlacements({
    required GridShape shape,
    required int nDinos,
    required bool withStatsBubble,
    required Rect area,
    required double gap,
  }) {
    final cols = shape.cols;
    final rows = shape.rows;
    final cellW = (area.width - gap * (cols - 1)) / cols;
    final cellH = (area.height - gap * (rows - 1)) / rows;

    final dinoSlots = <Rect>[];
    Rect? statsRect;

    // ── Sans stats : placement simple + centrage dernière ligne ───────
    if (!withStatsBubble) {
      _placeDinosLineByLine(
        nDinos: nDinos,
        cols: cols,
        rows: rows,
        cellW: cellW,
        cellH: cellH,
        gap: gap,
        area: area,
        out: dinoSlots,
      );
      return CanvaPlacements(dinoSlots: dinoSlots);
    }

    // ── Avec stats : la stats est sur la DERNIÈRE ligne ───────────────
    final fullRows = rows - 1;
    final dinosOnFullRows = (fullRows * cols).clamp(0, nDinos);
    final dinosOnLastRow = nDinos - dinosOnFullRows;

    // Lignes pleines au-dessus
    int placed = 0;
    for (int r = 0; r < fullRows; r++) {
      final dinosThisRow = (nDinos - placed).clamp(0, cols);
      for (int c = 0; c < dinosThisRow; c++) {
        final x = area.left + c * (cellW + gap);
        final y = area.top + r * (cellH + gap);
        dinoSlots.add(Rect.fromLTWH(x, y, cellW, cellH));
        placed++;
      }
    }

    // Dernière ligne : [dinos] + [stats étirée sur les colonnes restantes]
    final statsColStart = dinosOnLastRow;
    final statsSpan = cols - dinosOnLastRow;

    if (statsSpan < 2) {
      // Sécurité défensive : findBestLayout évite normalement ce cas.
      // On retire un dino de la dernière ligne pour donner 2 cells à stats.
      final lastRow = rows - 1;
      final adjustedStart = cols - 2;
      for (int c = dinosOnLastRow; c < adjustedStart && c < cols; c++) {
        final x = area.left + c * (cellW + gap);
        final y = area.top + lastRow * (cellH + gap);
        dinoSlots.add(Rect.fromLTWH(x, y, cellW, cellH));
      }
      final x = area.left + adjustedStart * (cellW + gap);
      final y = area.top + lastRow * (cellH + gap);
      statsRect = Rect.fromLTWH(x, y, cellW * 2 + gap, cellH);
    } else {
      // Cas normal : dinos puis stats étirée
      final lastRow = rows - 1;
      for (int c = 0; c < dinosOnLastRow; c++) {
        final x = area.left + c * (cellW + gap);
        final y = area.top + lastRow * (cellH + gap);
        dinoSlots.add(Rect.fromLTWH(x, y, cellW, cellH));
      }
      final sx = area.left + statsColStart * (cellW + gap);
      final sy = area.top + lastRow * (cellH + gap);
      statsRect = Rect.fromLTWH(
        sx,
        sy,
        cellW * statsSpan + gap * (statsSpan - 1),
        cellH,
      );
    }

    return CanvaPlacements(dinoSlots: dinoSlots, statsRect: statsRect);
  }

  /// Place les dinos ligne par ligne (lignes du haut chargées en premier).
  ///
  /// Si la dernière ligne contient strictement moins de dinos que la ligne
  /// du dessus, ses bulles sont centrées horizontalement par rapport à
  /// cette ligne de référence (et non par rapport à `cols`).
  static void _placeDinosLineByLine({
    required int nDinos,
    required int cols,
    required int rows,
    required double cellW,
    required double cellH,
    required double gap,
    required Rect area,
    required List<Rect> out,
  }) {
    // Pré-calcule combien de dinos sur chaque ligne
    final dinosPerRow = <int>[];
    int remaining = nDinos;
    for (int r = 0; r < rows; r++) {
      final n = remaining.clamp(0, cols);
      dinosPerRow.add(n);
      remaining -= n;
    }

    for (int r = 0; r < rows; r++) {
      final dinosThisRow = dinosPerRow[r];
      if (dinosThisRow == 0) continue;

      // Référence pour le centrage : ligne précédente (ou cols si r=0)
      final referenceRow = r == 0 ? cols : dinosPerRow[r - 1];
      final isIncomplete = dinosThisRow < referenceRow;

      double xOffset = 0;
      if (isIncomplete) {
        final usedW = dinosThisRow * cellW + (dinosThisRow - 1) * gap;
        final refW = referenceRow * cellW + (referenceRow - 1) * gap;
        xOffset = (refW - usedW) / 2;
      }

      for (int c = 0; c < dinosThisRow; c++) {
        final x = area.left + xOffset + c * (cellW + gap);
        final y = area.top + r * (cellH + gap);
        out.add(Rect.fromLTWH(x, y, cellW, cellH));
      }
    }
  }
}
