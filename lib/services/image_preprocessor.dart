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
  /// Extraire le canal rouge en int 0-255
  static int _getGray(img.Image image, int x, int y) {
    final p = image.getPixel(x, y);
    return p.r.toInt();
  }

  /// ── Vérification qualité ──
  static Future<ImageQualityReport> checkQuality(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return ImageQualityReport(
        brightness: 0,
        contrast: 0,
        width: 0,
        height: 0,
        isTooDark: true,
        isTooBlurry: true,
        isLowContrast: true,
        isTooSmall: true,
      );
    }

    final int w = decoded.width;
    final int h = decoded.height;
    final int totalPixels = w * h;
    final int step = max(1, totalPixels ~/ 10000);

    double sumBrightness = 0;
    double sumSquares = 0;
    int count = 0;

    for (int i = 0; i < totalPixels; i += step) {
      final int x = i % w;
      final int y = i ~/ w;
      if (y >= h) break;

      final p = decoded.getPixel(x, y);
      final double r = p.r.toDouble();
      final double g = p.g.toDouble();
      final double b = p.b.toDouble();
      final double lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

      sumBrightness += lum;
      sumSquares += lum * lum;
      count++;
    }

    final double avgBrightness = count > 0 ? sumBrightness / count : 0.0;
    final double variance = count > 0
        ? (sumSquares / count) - (avgBrightness * avgBrightness)
        : 0.0;
    final double contrastVal = sqrt(max(0.0, variance));
    final double blurScore = _estimateBlur(decoded);

    return ImageQualityReport(
      brightness: avgBrightness,
      contrast: contrastVal,
      width: w,
      height: h,
      isTooDark: avgBrightness < 0.15,
      isTooBlurry: blurScore < 15.0,
      isLowContrast: contrastVal < 0.08,
      isTooSmall: w < 320 || h < 240,
    );
  }

  /// Estimation netteté via variance du Laplacien
  static double _estimateBlur(img.Image image) {
    final img.Image small =
        image.width > 640 ? img.copyResize(image, width: 640) : image;
    final img.Image gray = img.grayscale(small);

    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final double center = _getGray(gray, x, y).toDouble();
        final double top = _getGray(gray, x, y - 1).toDouble();
        final double bottom = _getGray(gray, x, y + 1).toDouble();
        final double left = _getGray(gray, x - 1, y).toDouble();
        final double right = _getGray(gray, x + 1, y).toDouble();

        final double laplacian = -4.0 * center + top + bottom + left + right;
        sum += laplacian;
        sumSq += laplacian * laplacian;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final double mean = sum / count;
    final double variance = (sumSq / count) - (mean * mean);
    return sqrt(max(0.0, variance));
  }

  /// ── Pipeline léger pour Gemini : N&B + contraste (sans binarisation dure) ──
  /// Gemini lit mieux une image nette N&B qu'une image couleur floue ou sombre.
  /// On évite l'adaptive threshold qui détruit la structure pour les modèles IA.
  static Future<File> preprocessForGemini(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return imageFile;

    img.Image image = decoded;

    // ── 1. Grayscale ──
    image = img.grayscale(image);

    // ── 2. Réduction de bruit légère ──
    image = img.gaussianBlur(image, radius: 1);

    // ── 3. Étirement d'histogramme (contraste max) ──
    image = _stretchHistogram(image);

    // ── 4. Upscale si trop petit (meilleure lecture IA) ──
    if (image.width < 800) {
      final double scale = (800.0 / image.width.toDouble()).clamp(1.0, 2.5);
      image = img.copyResize(
        image,
        width: (image.width.toDouble() * scale).round(),
        height: (image.height.toDouble() * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    // ── Sauvegarder ──
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/gemini_preprocessed_${DateTime.now().millisecondsSinceEpoch}.png';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodePng(image));
    return outputFile;
  }

  /// ── Pipeline de prétraitement complet ──
  static Future<File> preprocess(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) return imageFile;

    img.Image image = decoded;

    // ── 1. Grayscale ──
    image = img.grayscale(image);

    // ── 2. Flou gaussien léger (réduction bruit) ──
    image = img.gaussianBlur(image, radius: 1);

    // ── 3. Histogram stretch (contraste) ──
    image = _stretchHistogram(image);

    // ── 4. Binarisation adaptative ──
    image = _adaptiveThreshold(image, blockSize: 31, c: 10);

    // ── 5. Upscale si trop petit ──
    if (image.width < 640 || image.height < 480) {
      final double scale =
          max(640.0 / image.width.toDouble(), 480.0 / image.height.toDouble())
              .clamp(1.0, 3.0);
      image = img.copyResize(
        image,
        width: (image.width.toDouble() * scale).round(),
        height: (image.height.toDouble() * scale).round(),
        interpolation: img.Interpolation.cubic,
      );
    }

    // ── Sauvegarder ──
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.png';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodePng(image));

    return outputFile;
  }

  /// Étirement d'histogramme
  static img.Image _stretchHistogram(img.Image image) {
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
    final int low = minVal + (range * 0.01).round();
    final int high = maxVal - (range * 0.01).round();
    if (high <= low) return image;

    final img.Image result =
        img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int v = _getGray(image, x, y);
        final int stretched =
            ((v - low) * 255 ~/ (high - low)).clamp(0, 255);
        result.setPixelRgb(x, y, stretched, stretched, stretched);
      }
    }

    return result;
  }

  /// Binarisation adaptative via image intégrale
  static img.Image _adaptiveThreshold(img.Image image,
      {int blockSize = 31, int c = 10}) {
    final int halfBlock = blockSize ~/ 2;
    final int w = image.width;
    final int h = image.height;
    final img.Image result = img.Image(width: w, height: h);

    // Image intégrale — tout en int
    // integral[y][x] = somme de tous les pixels dans le rectangle (0,0)→(x-1,y-1)
    final List<List<int>> integral = List<List<int>>.generate(
      h + 1,
      (_) => List<int>.filled(w + 1, 0),
    );

    for (int y = 1; y <= h; y++) {
      int rowSum = 0;
      for (int x = 1; x <= w; x++) {
        final int pixelVal = _getGray(image, x - 1, y - 1);
        rowSum = rowSum + pixelVal;
        integral[y][x] = integral[y - 1][x] + rowSum;
      }
    }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int y1 = max(0, y - halfBlock);
        final int y2 = min(h - 1, y + halfBlock);
        final int x1 = max(0, x - halfBlock);
        final int x2 = min(w - 1, x + halfBlock);

        final int count = (y2 - y1 + 1) * (x2 - x1 + 1);
        final int sum = integral[y2 + 1][x2 + 1] -
            integral[y1][x2 + 1] -
            integral[y2 + 1][x1] +
            integral[y1][x1];

        final int threshold = (sum ~/ count) - c;
        final int v = _getGray(image, x, y);

        final int out = v > threshold ? 255 : 0;
        result.setPixelRgb(x, y, out, out, out);
      }
    }

    return result;
  }
}
