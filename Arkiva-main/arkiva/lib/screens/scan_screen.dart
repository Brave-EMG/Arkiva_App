import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:arkiva/services/image_processing_service.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:arkiva/services/responsive_service.dart';
import 'package:arkiva/services/edge_detection_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final ImageProcessingService _imageProcessingService = ImageProcessingService();
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _isAutoResizeEnabled = true;
  bool _isDetectingEdges = false;
  
  // Animation pour le redimensionnement
  late AnimationController _resizeAnimationController;
  late Animation<double> _resizeAnimation;
  
  // Dimensions du cadre de scan
  double _frameWidth = 0.8;
  double _frameHeight = 0.6;
  double _frameX = 0.1;
  double _frameY = 0.2;

  // Paramètres de détection
  List<Map<String, double>> _recentDetections = [];
  Map<String, dynamic> _detectionParams = {};
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDetectionParams();
    
    // Ne pas initialiser la caméra sur le web
    if (!kIsWeb) {
      _initializeCamera();
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _initializeAnimations() {
    _resizeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _resizeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resizeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeDetectionParams() {
    _detectionParams = EdgeDetectionService.optimizeDetectionParameters(
      0.8, // Niveau de lumière simulé
      0.3, // Niveau de mouvement simulé
      ResponsiveService.isLandscape(context),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Demander les permissions
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Permission caméra refusée');
      }

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
      
      // Démarrer la détection automatique des bords
      if (!kIsWeb) {
        _startAutoEdgeDetection();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la caméra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation de la caméra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startAutoEdgeDetection() {
    if (!_isAutoResizeEnabled || kIsWeb) return;
    
    // Démarrer la détection périodique
    _detectionTimer = Timer.periodic(
      Duration(milliseconds: _detectionParams['updateInterval'] ?? 1000),
      (timer) {
        if (mounted && _isAutoResizeEnabled && !_isProcessing && !kIsWeb) {
          _performEdgeDetection();
        }
      },
    );
  }

  Future<void> _performEdgeDetection() async {
    if (_controller == null || !_isInitialized || kIsWeb) return;

    try {
      // Capturer une image pour l'analyse
      final image = await _controller!.takePicture();
      final imageFile = File(image.path);
      
      // Détecter les bords
      final edges = await EdgeDetectionService.detectDocumentEdges(imageFile);
      
      if (edges != null) {
        _recentDetections.add(edges);
        
        // Garder seulement les 5 dernières détections
        if (_recentDetections.length > 5) {
          _recentDetections.removeAt(0);
        }
        
        // Vérifier si l'image est stable
        if (EdgeDetectionService.isImageStable(_recentDetections)) {
          _adjustFrameBasedOnDetection(edges);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la détection de bords: $e');
    }
  }

  void _adjustFrameBasedOnDetection(Map<String, double> edges) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = ResponsiveService.isLandscape(context);
    
    // Calculer les dimensions optimales
    final optimalFrame = EdgeDetectionService.calculateOptimalFrame(
      edges,
      screenSize,
      isLandscape,
    );
    
    // Valider les dimensions
    if (!EdgeDetectionService.isValidFrame(optimalFrame)) {
      return;
    }
    
    // Animer le changement
    _resizeAnimationController.reset();
    _resizeAnimationController.forward();
    
    setState(() {
      _frameWidth = optimalFrame['width'] ?? _frameWidth;
      _frameHeight = optimalFrame['height'] ?? _frameHeight;
      _frameX = optimalFrame['x'] ?? _frameX;
      _frameY = optimalFrame['y'] ?? _frameY;
    });
    
    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cadre ajusté automatiquement (confiance: ${(edges['confidence'] ?? 0 * 100).toStringAsFixed(0)}%)'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleAutoResize() {
    setState(() {
      _isAutoResizeEnabled = !_isAutoResizeEnabled;
    });
    
    if (_isAutoResizeEnabled && !kIsWeb) {
      _startAutoEdgeDetection();
    } else {
      _detectionTimer?.cancel();
    }
  }

  void _resetFrame() {
    setState(() {
      _frameWidth = 0.8;
      _frameHeight = 0.6;
      _frameX = 0.1;
      _frameY = 0.2;
      _recentDetections.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cadre réinitialisé'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDetectionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Paramètres de détection',
          style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingRow('Sensibilité', _detectionParams['sensitivity'] ?? 0.7),
            _buildSettingRow('Intervalle (ms)', _detectionParams['updateInterval'] ?? 1000),
            _buildSettingRow('Seuil confiance', _detectionParams['confidenceThreshold'] ?? 0.7),
            _buildSettingRow('Ajustement max', _detectionParams['maxAdjustment'] ?? 0.2),
          ],
        ),
        actions: [
          ResponsiveService.responsiveButton(
            context: context,
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndProcess() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fonctionnalité de scan n\'est pas disponible sur le web'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      final processedImage = await _imageProcessingService.processImage(File(image.path));
      
      if (processedImage != null && mounted) {
        // TODO: Sauvegarder l'image traitée et naviguer vers l'écran suivant
        debugPrint('Image traitée sauvegardée: ${processedImage.path}');
        
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document scanné avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _toggleFlash() async {
    if (_controller == null || kIsWeb) return;
    
    try {
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch
      );
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Erreur lors du changement de flash: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _imageProcessingService.dispose();
    _resizeAnimationController.dispose();
    _detectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Scanner un document',
            style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 18)),
          ),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 100,
                color: Colors.grey[400],
              ),
              SizedBox(height: 24),
              Text(
                'Fonctionnalité non disponible sur le web',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Veuillez utiliser l\'application mobile pour scanner des documents',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ResponsiveService.responsiveButton(
                context: context,
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Retour',
                  style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Scanner un document',
            style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 18)),
          ),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Initialisation de la caméra...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Scanner un document',
          style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 18)),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              size: ResponsiveService.getIconSize(context),
            ),
          ),
          IconButton(
            onPressed: _toggleAutoResize,
            icon: Icon(
              _isAutoResizeEnabled ? Icons.auto_fix_high : Icons.auto_fix_normal,
              size: ResponsiveService.getIconSize(context),
              color: _isAutoResizeEnabled ? Colors.green : Colors.grey,
            ),
          ),
          IconButton(
            onPressed: _showDetectionSettings,
            icon: Icon(
              Icons.settings,
              size: ResponsiveService.getIconSize(context),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Prévisualisation de la caméra
          CameraPreview(_controller!),
          
          // Overlay de cadrage adaptatif avec animation
          AnimatedBuilder(
            animation: _resizeAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: DocumentOverlayPainter(
                  isMobile: ResponsiveService.isMobile(context),
                  frameWidth: _frameWidth,
                  frameHeight: _frameHeight,
                  frameX: _frameX,
                  frameY: _frameY,
                  isDetectingEdges: _isDetectingEdges,
                  detectionCount: _recentDetections.length,
                ),
              );
            },
          ),
          
          // Indicateur de chargement
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Indicateur de détection des bords
          if (_isDetectingEdges)
            Positioned(
              top: ResponsiveService.isMobile(context) ? 16 : 32,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(ResponsiveService.getPadding(context)),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Détection automatique des bords...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Contrôles de capture
          Positioned(
            bottom: ResponsiveService.isMobile(context) ? 32 : 64,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton retour
                ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: ResponsiveService.getIconSize(context),
                  ),
                ),
                
                // Bouton de capture principal
                GestureDetector(
                  onTap: _isProcessing ? null : _captureAndProcess,
                  child: Container(
                    width: ResponsiveService.isMobile(context) ? 80 : 100,
                    height: ResponsiveService.isMobile(context) ? 80 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? Colors.grey : Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      Icons.camera,
                      size: ResponsiveService.getIconSize(context) * 1.5,
                      color: _isProcessing ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
                
                // Bouton reset
                ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: _resetFrame,
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: ResponsiveService.getIconSize(context),
                  ),
                ),
              ],
            ),
          ),
          
          // Instructions en haut
          Positioned(
            top: ResponsiveService.isMobile(context) ? 16 : 32,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(ResponsiveService.getPadding(context)),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Placez le document dans le cadre et appuyez sur le bouton de capture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
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
  final bool isMobile;
  final double frameWidth;
  final double frameHeight;
  final double frameX;
  final double frameY;
  final bool isDetectingEdges;
  final int detectionCount;
  
  DocumentOverlayPainter({
    required this.isMobile,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameX,
    required this.frameY,
    required this.isDetectingEdges,
    this.detectionCount = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isMobile ? 2.0 : 3.0;

    // Calculer les dimensions du cadre selon les paramètres
    final width = size.width * frameWidth;
    final height = width * frameHeight;
    final left = size.width * frameX;
    final top = size.height * frameY;

    // Dessiner le rectangle de cadrage
    canvas.drawRect(
      Rect.fromLTWH(left, top, width, height),
      paint,
    );

    // Dessiner les coins avec une taille adaptative
    final cornerLength = width * (isMobile ? 0.08 : 0.1);
    final cornerPaint = Paint()
      ..color = isDetectingEdges ? Colors.blue : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isMobile ? 3.0 : 4.0;

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

    // Ajouter des indicateurs visuels pour la détection automatique
    if (isDetectingEdges || detectionCount > 0) {
      final indicatorPaint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      // Dessiner des points d'indicateur aux coins
      canvas.drawCircle(Offset(left, top), 4, indicatorPaint);
      canvas.drawCircle(Offset(left + width, top), 4, indicatorPaint);
      canvas.drawCircle(Offset(left, top + height), 4, indicatorPaint);
      canvas.drawCircle(Offset(left + width, top + height), 4, indicatorPaint);
      
      // Afficher le nombre de détections
      if (detectionCount > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$detectionCount',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(left + width - 20, top - 20));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 