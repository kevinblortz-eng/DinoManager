import 'dart:async';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../models/ark_species_data.dart';
import '../models/ark_species_color_regions.dart';
import '../models/dino.dart';


/// Widget affichant le dino PNG officiel ARK avec coloration régionale correcte.
///
/// Algorithme identique à ARKStatsExtractor (CreatureColored.cs) :
///   - Encodage du masque :
///       Région 0 → o = max(0, R − G − B) / 255
///       Région 1 → o = max(0, G − R − B) / 255
///       Région 2 → o = max(0, B − R − G) / 255
///       Région 3 → o = min(G, B) / 255
///       Région 4 → o = min(R, G) / 255
///       Région 5 → o = min(R, B) / 255
///   - Fusion : "grain merge" → out = clamp(base + tint − 128, 0, 255)
///     colorisé proportionnellement à o.
class DinoImageWidget extends StatefulWidget {
  final String species;
  final List<String?> regionColors;
  final double width;
  final double height;
  final BoxFit fit;
  final bool showColorBand;
  final Alignment alignment;

  const DinoImageWidget({
    super.key,
    required this.species,
    required this.regionColors,
    this.width = 200,
    this.height = 150,
    this.fit = BoxFit.contain,
    this.showColorBand = true,
    this.alignment = Alignment.center,
  });

  @override
  State<DinoImageWidget> createState() => _DinoImageWidgetState();
}

class _DinoImageWidgetState extends State<DinoImageWidget> {
  /// Cache mémoire : image déjà colorée, clé = espèce + couleurs de régions.
  /// Évite de refaire décodage + grain merge à chaque reconstruction
  /// (supprime le flash du carré noir à l'ouverture / actualisation).
  /// LinkedHashMap = ordre d'insertion → éviction FIFO simple.
  static final Map<String, ui.Image> _cache = <String, ui.Image>{};
  static const int _cacheMaxEntries = 24;

  ui.Image? _coloredImage;
  bool _loading = true;
  List<String?> _lastColors = [];

  String get _cacheKey =>
      '${widget.species}|${widget.regionColors.join(",")}';

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void didUpdateWidget(DinoImageWidget old) {
    super.didUpdateWidget(old);
    final colorsChanged = !_listEquals(widget.regionColors, _lastColors);
    if (old.species != widget.species || colorsChanged) {
      _processImage(forceLoading: old.species != widget.species);
    }
  }

  bool _listEquals(List<String?> a, List<String?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _processImage({bool forceLoading = false}) async {
    if (!mounted) return;

    _lastColors = List.from(widget.regionColors);

    // Cache hit → affichage immédiat, aucun placeholder.
    final cached = _cache[_cacheKey];
    if (cached != null) {
      setState(() {
        _coloredImage = cached;
        _loading = false;
      });
      return;
    }

    // Gapless : si une image est déjà affichée (changement de couleurs
    // uniquement), on la garde à l'écran pendant le recalcul au lieu du
    // carré noir. forceLoading=true (changement d'espèce) → placeholder.
    if (forceLoading || _coloredImage == null) {
      setState(() => _loading = true);
    }

    final basePath = ArkSpeciesData.getImageAssetPath(widget.species);
    if (basePath == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // Charger image de base
      final baseBytes = await rootBundle.load(basePath);
      final baseCodec = await ui.instantiateImageCodec(
          baseBytes.buffer.asUint8List());
      final baseFrame = await baseCodec.getNextFrame();
      final baseImg = baseFrame.image;

      // Vérifier si un masque est disponible
      final maskPath = ArkSpeciesData.getMaskAssetPath(widget.species);
      ui.Image? maskImg;
      if (maskPath != null) {
        try {
          final maskBytes = await rootBundle.load(maskPath);
          final maskCodec = await ui.instantiateImageCodec(
              maskBytes.buffer.asUint8List());
          final maskFrame = await maskCodec.getNextFrame();
          maskImg = maskFrame.image;
        } catch (_) {}
      }

      // Construire les couleurs actives
      final activeColors = <int, _RGB>{};
      for (int i = 0; i < 6 && i < widget.regionColors.length; i++) {
        final hex = widget.regionColors[i];
        if (hex == null || hex.isEmpty) continue;
        final hn = hex.toUpperCase().replaceAll('#', '');
        if (hn == '808080' || hn == '7F7F7F') continue;
        final c = _parseHexRGB(hex);
        if (c != null) activeColors[i] = c;
      }

      ui.Image result;
      if (maskImg != null && activeColors.isNotEmpty) {
        result = await _applyGrainMerge(baseImg, maskImg, activeColors);
      } else {
        result = baseImg;
      }

      if (mounted) {
        if (!_cache.containsKey(_cacheKey)) {
          if (_cache.length >= _cacheMaxEntries) {
            // Retrait FIFO sans dispose() : l'image peut encore être
            // affichée par une autre instance du widget. Le finalizer
            // natif de ui.Image libérera la mémoire.
            _cache.remove(_cache.keys.first);
          }
          _cache[_cacheKey] = result;
        }
        setState(() {
          _coloredImage = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Applique l'algorithme grain merge pixel-par-pixel (identique ARKStatsExtractor).
  /// Traitement en Dart pur sur ByteData RGBA.
  Future<ui.Image> _applyGrainMerge(
      ui.Image base, ui.Image mask, Map<int, _RGB> colors) async {
    final w = base.width;
    final h = base.height;

    // Obtenir les bytes RGBA des deux images
    final baseByteData =
        await base.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (baseByteData == null) return base;

    // Redimensionner le masque à la taille de l'image de base si nécessaire
    final Uint8List maskBytes;
    if (mask.width != w || mask.height != h) {
      // Redessiner le masque à la bonne taille
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder,
          Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
      final paint = Paint()..filterQuality = FilterQuality.medium;
      canvas.drawImageRect(
        mask,
        Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        paint,
      );
      final picture = recorder.endRecording();
      final resizedMask = await picture.toImage(w, h);
      final resizedData =
          await resizedMask.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (resizedData == null) return base;
      maskBytes = resizedData.buffer.asUint8List();
    } else {
      final maskByteData =
          await mask.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (maskByteData == null) return base;
      maskBytes = maskByteData.buffer.asUint8List();
    }

    // Copie modifiable des pixels RGBA de l'image de base
    final pixels = Uint8List.fromList(baseByteData.buffer.asUint8List());

    final pixCount = w * h;

    for (int idx = 0; idx < pixCount; idx++) {
      final offset = idx * 4;

      // RGBA de l'image de base
      final bgR = pixels[offset];
      final bgG = pixels[offset + 1];
      final bgB = pixels[offset + 2];
      final bgA = pixels[offset + 3];

      // Pixels transparents → ignorer
      if (bgA == 0) continue;

      // RGBA du masque (R=rouge, G=vert, B=bleu)
      final mR = maskBytes[offset];
      final mG = maskBytes[offset + 1];
      final mB = maskBytes[offset + 2];

      int finalR = bgR;
      int finalG = bgG;
      int finalB = bgB;

      // Appliquer chaque région active
      for (final entry in colors.entries) {
        final m = entry.key;
        final tint = entry.value;

        // Calcul de l'opacité selon la région (algorithme officiel)
        double o;
        switch (m) {
          case 0:
            o = (mR - mG - mB).clamp(0, 255) / 255.0;
            break;
          case 1:
            o = (mG - mR - mB).clamp(0, 255) / 255.0;
            break;
          case 2:
            o = (mB - mR - mG).clamp(0, 255) / 255.0;
            break;
          case 3:
            o = mG < mB ? mG / 255.0 : mB / 255.0;
            break;
          case 4:
            o = mR < mG ? mR / 255.0 : mG / 255.0;
            break;
          case 5:
            o = mR < mB ? mR / 255.0 : mB / 255.0;
            break;
          default:
            continue;
        }

        if (o <= 0.001) continue;

        // Grain merge : out = clamp(base + tint - 128, 0, 255)
        int rMix = (finalR + tint.r - 128).clamp(0, 255);
        int gMix = (finalG + tint.g - 128).clamp(0, 255);
        int bMix = (finalB + tint.b - 128).clamp(0, 255);

        // Mélange proportionnel à o
        finalR = (o * rMix + (1 - o) * finalR).round().clamp(0, 255);
        finalG = (o * gMix + (1 - o) * finalG).round().clamp(0, 255);
        finalB = (o * bMix + (1 - o) * finalB).round().clamp(0, 255);
      }

      pixels[offset] = finalR;
      pixels[offset + 1] = finalG;
      pixels[offset + 2] = finalB;
      // Alpha inchangé
    }

    // Recréer l'image ui.Image depuis les pixels modifiés
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, w, h, ui.PixelFormat.rgba8888,
        (img) => completer.complete(img));
    return completer.future;
  }

  _RGB? _parseHexRGB(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) {
        final val = int.parse(h, radix: 16);
        return _RGB(
          (val >> 16) & 0xFF,
          (val >> 8) & 0xFF,
          val & 0xFF,
        );
      }
    } catch (_) {}
    return null;
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return null;
  }

  @override
@override
Widget build(BuildContext context) {
  // Si on demande "infinity" en largeur/hauteur, on s'adapte aux contraintes
  // du parent au lieu d'imposer une SizedBox de taille infinie (qui devient 0
  // dans une Column ou un Stack non contraint).
  final bool wInf = widget.width  == double.infinity;
  final bool hInf = widget.height == double.infinity;

  final Widget content = _buildContent();

  Widget sized;
  if (wInf || hInf) {
    sized = LayoutBuilder(
      builder: (context, constraints) {
        final w = wInf
            ? (constraints.hasBoundedWidth  ? constraints.maxWidth  : 200.0)
            : widget.width;
        final h = hInf
            ? (constraints.hasBoundedHeight ? constraints.maxHeight : 150.0)
            : widget.height;
        return SizedBox(width: w, height: h, child: content);
      },
    );
  } else {
    sized = SizedBox(
      width:  widget.width,
      height: widget.height,
      child:  content,
    );
  }

  if (!widget.showColorBand) return sized;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [sized, _buildColorBand()],
  );
}

 Widget _buildContent() {
  if (_loading) {
    return Container(
      color: const Color(0xFF0D1117),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFF6B00),
          ),
        ),
      ),
    );
  }

  if (_coloredImage == null) return _buildFallback();

  // ⚠️ On ne passe PLUS widget.width/height ici — le parent SizedBox
  // s'occupe déjà du dimensionnement. RawImage prendra le BoxFit.
  return Center(
    child: RawImage(
      image:         _coloredImage,
      fit:           widget.fit,
      alignment:     Alignment.center,
      filterQuality: FilterQuality.high,
    ),
  );
}

  Widget _buildFallback() {
    final emoji = _getEmoji(widget.species);
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFF1C2333), Color(0xFF0D1117)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: widget.height * 0.42)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              widget.species,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: (widget.height * 0.1).clamp(8.0, 11.0),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBand() {
    final visibility = ArkSpeciesColorRegions.visibilityFor(widget.species);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final isActive = i < visibility.length ? visibility[i] : true;
          final hex =
              i < widget.regionColors.length ? widget.regionColors[i] : null;
          final isGray = hex == null ||
              hex.toUpperCase().replaceAll('#', '') == '808080' ||
              hex.toUpperCase().replaceAll('#', '') == '7F7F7F';

          // Région inactive : case barrée (transparente + motif)
          if (!isActive) {
            return Expanded(
              child: Container(
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
            );
          }

          final color = isGray
              ? Colors.grey.withValues(alpha: 0.25)
              : (_parseHexColor(hex) ?? Colors.grey.withValues(alpha: 0.25));
          return Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getEmoji(String name) {
    final l = name.toLowerCase();
    if (l.contains('rex') || l.contains('giga')) return '🦖';
    if (l.contains('wyvern') || l.contains('dragon')) return '🐉';
    if (l.contains('raptor') || l.contains('deinonychus')) return '🦕';
    if (l.contains('pteranodon') ||
        l.contains('argentavis') ||
        l.contains('quetz') ||
        l.contains('ptero')) {
      return '🦅';
    }
    if (l.contains('ankylo') || l.contains('stego')) return '🪨';
    if (l.contains('megalodon') || l.contains('shark')) return '🦈';
    if (l.contains('mammoth') || l.contains('woolly')) return '🦣';
    if (l.contains('bear') || l.contains('dire')) return '🐻';
    if (l.contains('wolf')) return '🐺';
    if (l.contains('spider') || l.contains('araneo')) return '🕷️';
    if (l.contains('turtle') || l.contains('carbo')) return '🐢';
    if (l.contains('spino')) return '🦕';
    return '🦖';
  }
}

/// Données RGB simples
class _RGB {
  final int r, g, b;
  const _RGB(this.r, this.g, this.b);
}

/// Version carte pour la bibliothèque
class DinoCardImage extends StatelessWidget {
  final Dino dino;
  final double size;
  final Alignment alignment;

  const DinoCardImage({
    super.key,
    required this.dino,
    this.size = 120,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return DinoImageWidget(
      species: dino.espece,
      regionColors: dino.colorRegions,
      width: size,
      height: size * 0.75,
      showColorBand: false,
      alignment: Alignment.center,
    );
  }
}
