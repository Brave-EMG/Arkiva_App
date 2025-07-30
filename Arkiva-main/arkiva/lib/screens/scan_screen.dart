import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arkiva/services/image_processing_service.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImageProcessingService _imageProcessingService = ImageProcessingService();
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _showOverlay = true;
  bool _autoResize = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Aucune caméra disponible');
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la caméra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'initialisation de la caméra'),
          ),
        );
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      
      // Traitement avec redimensionnement automatique si activé
      File? processedImage;
      if (_autoResize) {
        processedImage = await _imageProcessingService.processDocumentScan(File(image.path));
      } else {
        processedImage = await _imageProcessingService.processImage(File(image.path));
      }
      
      if (processedImage != null && mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_autoResize 
              ? 'Document scanné avec redimensionnement automatique !' 
              : 'Document scanné !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Naviguer vers l'écran de prévisualisation avec l'image traitée
        if (mounted) {
          await Navigator.pushNamed(
            context,
            '/document-preview',
            arguments: processedImage,
          );
        }
        
        debugPrint('Image traitée sauvegardée: ${processedImage.path}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la capture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _imageProcessingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation de la caméra...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner de document'),
        actions: [
          // Bouton pour activer/désactiver l'overlay
          IconButton(
            icon: Icon(_showOverlay ? Icons.crop_free : Icons.crop_free_outlined),
            onPressed: () {
              setState(() {
                _showOverlay = !_showOverlay;
              });
            },
            tooltip: 'Afficher/Masquer le guide',
          ),
          // Bouton pour activer/désactiver le redimensionnement automatique
          IconButton(
            icon: Icon(_autoResize ? Icons.auto_fix_high : Icons.auto_fix_normal),
            onPressed: () {
              setState(() {
                _autoResize = !_autoResize;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_autoResize 
                    ? 'Redimensionnement automatique activé' 
                    : 'Redimensionnement automatique désactivé'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Redimensionnement automatique',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Prévisualisation de la caméra
          CameraPreview(_controller!),
          
          // Overlay de guidage pour le document
          if (_showOverlay)
            CustomPaint(
              painter: DocumentOverlayPainter(),
              child: Container(),
            ),
          
          // Indicateur de traitement
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Contrôles en bas
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Indicateur de mode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _autoResize ? 'Mode: Redimensionnement automatique' : 'Mode: Scan simple',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Bouton de capture
                FloatingActionButton.large(
                  onPressed: _isProcessing ? null : _captureAndProcess,
                  backgroundColor: _isProcessing ? Colors.grey : Colors.white,
                  foregroundColor: Colors.black,
                  child: Icon(
                    _isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          
          // Instructions en haut
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Placez le document dans le cadre et appuyez sur le bouton pour scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final width = size.width * 0.8;
    final height = width * 1.4; // Ratio A4
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;

    // Dessiner le rectangle de cadrage
    canvas.drawRect(
      Rect.fromLTWH(left, top, width, height),
      paint,
    );

    // Dessiner les coins
    final cornerLength = width * 0.1;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Coin supérieur gauche
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );

    // Coin supérieur droit
    canvas.drawLine(
      Offset(left + width, top),
      Offset(left + width - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + width, top),
      Offset(left + width, top + cornerLength),
      cornerPaint,
    );

    // Coin inférieur gauche
    canvas.drawLine(
      Offset(left, top + height),
      Offset(left + cornerLength, top + height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + height),
      Offset(left, top + height - cornerLength),
      cornerPaint,
    );

    // Coin inférieur droit
    canvas.drawLine(
      Offset(left + width, top + height),
      Offset(left + width - cornerLength, top + height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + width, top + height),
      Offset(left + width, top + height - cornerLength),
      cornerPaint,
    );

    // Ajouter des instructions visuelles
    final textPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Texte d'instruction en haut
    final textSpan = TextSpan(
      text: 'Document',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(left + (width - textPainter.width) / 2, top - 30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 