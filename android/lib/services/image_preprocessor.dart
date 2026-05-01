// lib/services/image_preprocessor.dart
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Rapport de qualité d'image
class ImageQualityReport {
  final double brightness;
  final double contrast;
  final int width;
  final int height;
  final bool isTooDark;
  final bool isTooBlurry;
  final bool isLowContrast;
  final bool isTooSmall;

  ImageQualityReport({
    required this.brightness,
    required this.contrast,
    required this.width,
    required this.height,
    required this.isTooDark,
    required this.isTooBlurry,
    required this.isLowContrast,
    required this.isTooSmall,
  });

  bool get isAcceptable =>
      !isTooDark && !isTooBlurry && !isLowContrast && !isTooSmall;
}

class ImagePreprocessor {

  // ── Luminance perceptuelle correcte (tous canaux RGB) ────────────────────
  // ✅ CORRIGÉ : l'ancienne version utilisait uniquement p.r (canal rouge)
  // ce qui sous-estimait la luminance des images bleues (jumelles Tek)
  static double _getLum(img.Pixel p) {
    return (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) / 255.0;
  }

  // ── Valeur grise d'un pixel déjà converti en grayscale ──────────────────
  static int _getGray(img.Image image, int x, int y) {
    final p = image.getPixel(x, y);
    return p.r.toInt(); // OK ici car l'image EST déjà en niveaux de gris
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VÉRIFICATION QUALITÉ
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<ImageQualityReport> checkQuality(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return ImageQualityReport(
        brightness: 0, contrast: 0, width: 0, height: 0,
        isTooDark: true, isTooBlurry: true,
        isLowContrast: true, isTooSmall: true,
      );
    }

    final int w = decoded.width;
    final int h = decoded.height;
    final int totalPixels = w * h;
    final int step = max(1, totalPixels ~/ 10000);

    double sumBrightness = 0;
    double sumSquares    = 0;
    int count = 0;

    for (int i = 0; i < totalPixels; i += step) {
      final int x = i % w;
      final int y = i ~/ w;
      if (y >= h) break;

      // ✅ CORRIGÉ : utiliser _getLum (luminance perceptuelle RGB complète)
      // au lieu de p.r seul → les images bleues ne sont plus détectées
      // comme "trop sombres" à tort
      final double lum = _getLum(decoded.getPixel(x, y));

      sumBrightness += lum;
      sumSquares    += lum * lum;
      count++;
    }

    final double avgBrightness = count > 0 ? sumBrightness / count : 0.0;
    final double variance       = count > 0
        ? (sumSquares / count) - (avgBrightness * avgBrightness)
        : 0.0;
    final double contrastVal = sqrt(max(0.0, variance));
    final double blurScore   = _estimateBlur(decoded);

    return ImageQualityReport(
      brightness:   avgBrightness,
      contrast:     contrastVal,
      width:        w,
      height:       h,
      // ✅ CORRIGÉ : seuils assouplis pour les interfaces ARK
      // qui ont naturellement des zones sombres (fond noir de l'UI)
      isTooDark:     avgBrightness < 0.10,  // était 0.15
      isTooBlurry:   blurScore < 8.0,       // était 15.0
      isLowContrast: contrastVal < 0.05,    // était 0.08
      isTooSmall:    w < 320 || h < 240,
    );
  }

  // ── Estimation netteté via variance du Laplacien ─────────────────────────
  static double _estimateBlur(img.Image image) {
    final img.Image small =
        image.width > 640 ? img.copyResize(image, width: 640) : image;
    final img.Image gray = img.grayscale(small);

    double sum   = 0;
    double sumSq = 0;
    int count    = 0;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final double center = _getGray(gray, x, y).toDouble();
        final double top    = _getGray(gray, x, y - 1).toDouble();
        final double bottom = _getGray(gray, x, y + 1).toDouble();
        final double left   = _getGray(gray, x - 1, y).toDouble();
        final double right  = _getGray(gray, x + 1, y).toDouble();

        final double laplacian = -4.0 * center + top + bottom + left + right;
        sum   += laplacian;
        sumSq += laplacian * laplacian;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final double mean     = sum / count;
    final double variance = (sumSq / count) - (mean * mean);
    return sqrt(max(0.0, variance));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PIPELINE PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<File> preprocess(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return imageFile;

    img.Image image = decoded;

    // ── ÉTAPE 0 : Upscale préventif AVANT tout traitement ──────────────────
    // ✅ CORRIGÉ : on monte en résolution D'ABORD pour que toutes les étapes
    // suivantes travaillent sur plus de pixels → meilleur résultat OCR
    if (image.width < 1200) {
      final double scale = (1200.0 / image.width).clamp(1.0, 3.0);
      image = img.copyResize(
        image,
        width:  (image.width  * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    // ── ÉTAPE 1 : Neutralisation de la dominante couleur ───────────────────
    // ✅ NOUVEAU : corrige la dominante bleue/cyan des jumelles Tek
    // avant la conversion en niveaux de gris
    image = _neutralizeColorCast(image);

    // ── ÉTAPE 2 : Conversion en niveaux de gris ────────────────────────────
    image = img.grayscale(image);

    // ── ÉTAPE 3 : Étirement d'histogramme ──────────────────────────────────
    // ✅ CORRIGÉ : clipPercent 0.02 au lieu de 0.01
    image = _stretchHistogram(image, clipPercent: 0.02);

    // ── ÉTAPE 4 : Flou gaussien léger APRÈS étirement ──────────────────────
    // ✅ DÉPLACÉ après l'étirement pour ne pas atténuer le contraste
    image = img.gaussianBlur(image, radius: 1);

    // ── ÉTAPE 5 : Binarisation adaptative double passe ─────────────────────
    // ✅ CORRIGÉ : double passe pour récupérer aussi le texte clair
    // sur fond clair (cases de couleur ARK = fond cyan + texte blanc "36")
    image = _adaptiveThresholdDoublePass(image, blockSize: 21, c: 15);

    // ── Sauvegarde ──
    final tempDir    = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.png';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodePng(image));

    return outputFile;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTRALISATION DE LA DOMINANTE COULEUR
  // ═══════════════════════════════════════════════════════════════════════════
  // Corrige la dominante bleue/cyan des jumelles Tek en équilibrant R/G/B
  // vers gris neutre avant la conversion grayscale.
  static img.Image _neutralizeColorCast(img.Image image) {
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;
    final int step = max(1, (image.width * image.height) ~/ 5000);

    for (int i = 0; i < image.width * image.height; i += step) {
      final int x = i % image.width;
      final int y = i ~/ image.width;
      if (y >= image.height) break;
      final p = image.getPixel(x, y);
      sumR += p.r;
      sumG += p.g;
      sumB += p.b;
      count++;
    }

    if (count == 0) return image;

    final double avgR    = sumR / count;
    final double avgG    = sumG / count;
    final double avgB    = sumB / count;
    final double avgGray = (avgR + avgG + avgB) / 3.0;

    // Si l'image est quasi-grise, pas besoin de corriger
    final double maxDeviation = [
      (avgR - avgGray).abs(),
      (avgG - avgGray).abs(),
      (avgB - avgGray).abs(),
    ].reduce(max);

    // Corriger seulement si dominante > 15 points sur 255
    if (maxDeviation < 15) return image;

    final double scaleR = avgR > 5 ? avgGray / avgR : 1.0;
    final double scaleG = avgG > 5 ? avgGray / avgG : 1.0;
    final double scaleB = avgB > 5 ? avgGray / avgB : 1.0;

    final img.Image result =
        img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final p   = image.getPixel(x, y);
        final int r = (p.r * scaleR).round().clamp(0, 255);
        final int g = (p.g * scaleG).round().clamp(0, 255);
        final int b = (p.b * scaleB).round().clamp(0, 255);
        result.setPixelRgb(x, y, r, g, b);
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ÉTIREMENT D'HISTOGRAMME
  // ═══════════════════════════════════════════════════════════════════════════
  static img.Image _stretchHistogram(img.Image image,
      {double clipPercent = 0.02}) {
    int minVal = 255;
    int maxVal = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int v = _getGray(image, x, y);
        if (v < minVal) minVal = v;
        if (v > maxVal) maxVal = v;
      }
    }

    if (maxVal <= minVal) return image;

    final int range = maxVal - minVal;
    final int low   = minVal + (range * clipPercent).round();
    final int high  = maxVal - (range * clipPercent).round();
    if (high <= low) return image;

    final img.Image result =
        img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int v         = _getGray(image, x, y);
        final int stretched = ((v - low) * 255 ~/ (high - low)).clamp(0, 255);
        result.setPixelRgb(x, y, stretched, stretched, stretched);
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BINARISATION ADAPTATIVE DOUBLE PASSE
  // ═══════════════════════════════════════════════════════════════════════════
  // Passe 1 : texte sombre sur fond clair (standard)
  // Passe 2 : texte clair sur fond clair (cases de couleur ARK = "36" blanc
  //           sur fond cyan clair)
  // Fusion OR : on garde le texte détecté par l'une OU l'autre passe
  static img.Image _adaptiveThresholdDoublePass(img.Image image,
      {int blockSize = 21, int c = 15}) {
    final int halfBlock = blockSize ~/ 2;
    final int w = image.width;
    final int h = image.height;

    // Image intégrale partagée entre les deux passes
    final List<List<int>> integral = List<List<int>>.generate(
      h + 1,
      (_) => List<int>.filled(w + 1, 0),
    );
    for (int y = 1; y <= h; y++) {
      int rowSum = 0;
      for (int x = 1; x <= w; x++) {
        rowSum += _getGray(image, x - 1, y - 1);
        integral[y][x] = integral[y - 1][x] + rowSum;
      }
    }

    final img.Image result = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int y1 = max(0, y - halfBlock);
        final int y2 = min(h - 1, y + halfBlock);
        final int x1 = max(0, x - halfBlock);
        final int x2 = min(w - 1, x + halfBlock);

        final int count     = (y2 - y1 + 1) * (x2 - x1 + 1);
        final int sum       = integral[y2 + 1][x2 + 1]
            - integral[y1][x2 + 1]
            - integral[y2 + 1][x1]
            + integral[y1][x1];

        final int localMean = sum ~/ count;
        final int v         = _getGray(image, x, y);

        // Passe 1 : texte sombre sur fond clair
        final bool isDarkText = v < localMean - c;

        // Passe 2 : texte clair sur fond clair
        // Condition : pixel plus clair que la moyenne locale ET zone globalement claire
        final bool isLightTextOnLightBg =
            v > localMean + (c ~/ 2) && localMean > 160;

        // Noir si texte détecté, blanc sinon
        final int out = (isDarkText || isLightTextOnLightBg) ? 0 : 255;
        result.setPixelRgb(x, y, out, out, out);
      }
    }

    return result;
  }
}
