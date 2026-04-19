// lib/screens/dino_scan_screen.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../services/dino_ocr_service.dart';
import '../services/image_preprocessor.dart';
import '../widgets/scan_crop_overlay.dart';
import '../widgets/scan_result_review_sheet.dart';

// ─── Modes de source ──────────────────────────────────────────────────────────
enum ScanMode { camera, gallery }

// ─────────────────────────────────────────────────────────────────────────────
/// Écran principal de scan : caméra live + overlay de cadrage
/// Retourne un [DinoOcrResult] ou null si annulé
// ─────────────────────────────────────────────────────────────────────────────
class DinoScanScreen extends StatefulWidget {
  final ScanMode mode;

  const DinoScanScreen({super.key, this.mode = ScanMode.camera});

  @override
  State<DinoScanScreen> createState() => _DinoScanScreenState();
}

class _DinoScanScreenState extends State<DinoScanScreen>
    with WidgetsBindingObserver {

  // ── Caméra ─────────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  String? _cameraError;

  // ── Image galerie ──────────────────────────────────────────────────────────
  File? _galleryImage;
  // ignore: unused_field
  Size? _galleryImageSize;

  // ── Zone de recadrage (valeurs normalisées 0.0–1.0) ───────────────────────
  // Pour la caméra : zone sur le preview live
  // Pour la galerie : zone sur l'image affichée
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.2, 0.8, 0.6);

  // ── Scan en cours ──────────────────────────────────────────────────────────
  bool _processing = false;
  String _processingStep = '';

  // ── Type de source attendu ─────────────────────────────────────────────────
  OcrSourceType _expectedSource = OcrSourceType.unknown;

  // ── Zoom ──────────────────────────────────────────────────────────────────
  double _currentZoom = 1.0;
  double _minZoom    = 1.0;
  double _maxZoom    = 8.0;

  // ── Flash ─────────────────────────────────────────────────────────────────
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    if (widget.mode == ScanMode.camera) {
      _initCamera();
    }
    // mode galerie : l'image est passée via Navigator.push arguments
    // ou ouverte dès l'init
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INITIALISATION CAMÉRA
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = 'Aucune caméra disponible');
        return;
      }

      // Préférer la caméra arrière
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh, // haute résolution pour OCR
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = _minZoom;

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _cameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Erreur caméra : $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CAPTURE & TRAITEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /// Capture la photo, recadre selon _cropRect, prétraite et lance l'OCR
  Future<void> _captureAndScan() async {
    if (_processing) return;

    setState(() {
      _processing     = true;
      _processingStep = 'Capture en cours…';
    });

    try {
      File rawFile;

      if (widget.mode == ScanMode.camera) {
        // ── 1a. Prise de vue caméra ──
        final xFile = await _cameraController!.takePicture();
        rawFile = File(xFile.path);
      } else {
        // ── 1b. Image galerie déjà chargée ──
        if (_galleryImage == null) return;
        rawFile = _galleryImage!;
      }

      // ── 2. Vérification qualité ──
      setState(() => _processingStep = 'Analyse qualité…');
      final quality = await ImagePreprocessor.checkQuality(rawFile);

      if (!quality.isAcceptable && mounted) {
        final continueAnyway = await _showQualityWarning(quality);
        if (continueAnyway != true) {
          setState(() => _processing = false);
          return;
        }
      }

      // ── 3. Recadrage selon la zone sélectionnée ──
      setState(() => _processingStep = 'Recadrage de la zone…');
      final croppedFile = await _cropToRegion(rawFile);

      // ── 4. Prétraitement (grayscale → contraste → binarisation) ──
      setState(() => _processingStep = 'Amélioration de l\'image…');
      final processedFile = await ImagePreprocessor.preprocess(croppedFile);

      // ── 5. OCR ──
      setState(() => _processingStep = 'Lecture des données…');
      final ocrService = DinoOcrService();
      final result     = await ocrService.scanImage(processedFile);

      // Nettoyage fichiers temporaires
      _cleanTemp([croppedFile, processedFile], rawFile);

      if (!mounted) return;

      if (!result.hasData) {
        _showNoDataSnackBar();
        setState(() => _processing = false);
        return;
      }

      // ── 6. Afficher résultat pour confirmation ──
      setState(() => _processing = false);
      final confirmed = await showModalBottomSheet<DinoOcrResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ScanResultReviewSheet(
          result: result,
          onConfirm: (r) => Navigator.pop(context, r),
          onRetry:   () => Navigator.pop(context),
        ),
      );

      if (confirmed != null && mounted) {
        Navigator.of(context).pop(confirmed);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur scan : $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Recadre l'image selon [_cropRect] (coordonnées normalisées)
  Future<File> _cropToRegion(File source) async {
    final bytes   = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return source;

    final int iw = decoded.width;
    final int ih = decoded.height;

    // Conversion coordonnées normalisées → pixels
    final int x = (_cropRect.left   * iw).round().clamp(0, iw - 1);
    final int y = (_cropRect.top    * ih).round().clamp(0, ih - 1);
    int        w = (_cropRect.width  * iw).round().clamp(1, iw - x);
    int        h = (_cropRect.height * ih).round().clamp(1, ih - y);

    // Garantir une largeur minimum pour l'OCR
    if (w < 200) w = math.min(iw, 200);
    if (h < 100) h = math.min(ih, 100);

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);

    final tempDir   = await getTemporaryDirectory();
    final outPath   = '${tempDir.path}/scan_crop_${DateTime.now().millisecondsSinceEpoch}.png';
    final outFile   = File(outPath);
    await outFile.writeAsBytes(img.encodePng(cropped));
    return outFile;
  }

  void _cleanTemp(List<File> temps, File original) {
    for (final f in temps) {
      if (f.path != original.path) {
        f.delete().catchError((_) => f);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ZOOM
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _setZoom(double value) async {
    final clamped = value.clamp(_minZoom, _maxZoom);
    await _cameraController?.setZoomLevel(clamped);
    setState(() => _currentZoom = clamped);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FLASH
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _toggleFlash() async {
    final next = _flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;
    await _cameraController?.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGUES
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool?> _showQualityWarning(ImageQualityReport q) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade400, size: 22),
            const SizedBox(width: 8),
            const Text('Qualité insuffisante',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (q.isTooDark)    _issueRow(Icons.brightness_low,  'Trop sombre'),
            if (q.isTooBlurry)  _issueRow(Icons.blur_on,         'Image floue'),
            if (q.isLowContrast)_issueRow(Icons.contrast,        'Contraste faible'),
            if (q.isTooSmall)   _issueRow(Icons.zoom_in,         'Image trop petite'),
            const SizedBox(height: 8),
            Text('L\'OCR risque d\'être imprécis.',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reprendre', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Widget _issueRow(IconData icon, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange.shade300, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );

  void _showNoDataSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.white),
            SizedBox(width: 10),
            Text('Aucune donnée de dino détectée.\nAjustez le cadrage.'),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.mode == ScanMode.camera
          ? _buildCameraView()
          : _buildGalleryView(),
    );
  }

  // ── VUE CAMÉRA ─────────────────────────────────────────────────────────────
  Widget _buildCameraView() {
    if (_cameraError != null) return _buildErrorView(_cameraError!);
    if (!_cameraReady)        return _buildLoadingView();

    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Preview caméra ──
        _buildCameraPreview(size),

        // ── Overlay de cadrage interactif ──
        ScanCropOverlay(
          cropRect: _cropRect,
          onCropChanged: (r) => setState(() => _cropRect = r),
          expectedSource: _expectedSource,
        ),

        // ── Barre supérieure ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopBar(),
        ),

        // ── Contrôles inférieurs ──
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomControls(),
        ),

        // ── Overlay de traitement ──
        if (_processing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildCameraPreview(Size size) {
    final controller = _cameraController!;
    final previewSize = controller.value.previewSize!;
    final previewAspect = previewSize.height / previewSize.width;
    // ignore: unused_local_variable
    final screenAspect  = size.width / size.height;

    return OverflowBox(
      maxWidth:  size.width,
      maxHeight: size.height,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width:  size.width,
          height: size.width * previewAspect,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  // ── VUE GALERIE ────────────────────────────────────────────────────────────
  Widget _buildGalleryView() {
    if (_galleryImage == null) return _buildLoadingView();

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Image ──
        Image.file(_galleryImage!, fit: BoxFit.contain),

        // ── Overlay de cadrage ──
        ScanCropOverlay(
          cropRect: _cropRect,
          onCropChanged: (r) => setState(() => _cropRect = r),
          expectedSource: _expectedSource,
          showZoomHint: false,
        ),

        // ── Barre supérieure ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildTopBar(showFlash: false),
        ),

        // ── Bouton analyser ──
        Positioned(
          bottom: 32, left: 0, right: 0,
          child: Center(child: _buildScanButton(label: 'ANALYSER LA ZONE')),
        ),

        if (_processing) _buildProcessingOverlay(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS UI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar({bool showFlash = true}) {
    return Container(
      padding: EdgeInsets.only(
        top:    MediaQuery.of(context).padding.top + 8,
        left:   16,
        right:  16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Bouton retour
          _iconBtn(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanner le Dino',
                    style: GoogleFonts.exo2(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(
                  'Cadrez la fenêtre de stats ARK',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          // Sélecteur de type source
          _buildSourceTypeSelector(),
          if (showFlash) ...[
            const SizedBox(width: 8),
            _iconBtn(
              _flashMode == FlashMode.off
                  ? Icons.flash_off
                  : Icons.flash_on,
              _toggleFlash,
              color: _flashMode == FlashMode.torch
                  ? Colors.amberAccent
                  : Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sourceTypeBtn('TEK', OcrSourceType.tekBinoculars),
          _sourceTypeBtn('CRYO', OcrSourceType.cryopodTooltip),
          _sourceTypeBtn('AUTO', OcrSourceType.unknown),
        ],
      ),
    );
  }

  Widget _sourceTypeBtn(String label, OcrSourceType type) {
    final isActive = _expectedSource == type;
    return GestureDetector(
      onTap: () => setState(() => _expectedSource = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top:    20,
        left:   24,
        right:  24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end:   Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom slider
          if (widget.mode == ScanMode.camera)
            _buildZoomSlider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bouton reset cadrage
              _iconBtn(Icons.crop_free, _resetCrop,
                  tooltip: 'Réinitialiser le cadrage'),
              // Bouton capture principal
              _buildScanButton(),
              // Bouton tips
              _iconBtn(Icons.help_outline, _showTips,
                  tooltip: 'Aide'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoomSlider() {
    return Row(
      children: [
        Icon(Icons.zoom_out, color: Colors.white54, size: 18),
        Expanded(
          child: Slider(
            value:   _currentZoom,
            min:     _minZoom,
            max:     _maxZoom.clamp(_minZoom, _minZoom + 6),
            onChanged: _setZoom,
            activeColor:   const Color(0xFF00E5FF),
            inactiveColor: Colors.white24,
          ),
        ),
        Icon(Icons.zoom_in, color: Colors.white54, size: 18),
        SizedBox(
          width: 36,
          child: Text(
            '${_currentZoom.toStringAsFixed(1)}×',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton({String label = 'CAPTURER'}) {
    return GestureDetector(
      onTap: _processing ? null : _captureAndScan,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width:  80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _processing
              ? Colors.grey.shade700
              : const Color(0xFF00E5FF),
          boxShadow: _processing
              ? []
              : [
                  BoxShadow(
                    color:  const Color(0xFF00E5FF).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
        ),
        child: _processing
            ? const Center(
                child: SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner, color: Colors.black, size: 26),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF00E5FF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _processingStep,
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Analyse en cours…',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );

  Widget _buildErrorView(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white, String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIONS HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  void _resetCrop() {
    setState(() => _cropRect = const Rect.fromLTWH(0.1, 0.2, 0.8, 0.6));
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1E28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conseils de scan',
                style: GoogleFonts.exo2(
                  color: Colors.amberAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            _tipRow(Icons.crop_free,         'Cadrez uniquement la fenêtre de stats'),
            _tipRow(Icons.brightness_high,   'Maximisez la luminosité de l\'écran ARK'),
            _tipRow(Icons.zoom_in,           'Utilisez le zoom pour les petits textes'),
            _tipRow(Icons.flash_on,          'Activez la lampe torche si nécessaire'),
            _tipRow(Icons.stay_current_portrait, 'Tenez le téléphone droit, sans tremblement'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00E5FF), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mode TEK : fenêtre jumelles.\nMode CRYO : infobulle du cryopod.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
      );
}
