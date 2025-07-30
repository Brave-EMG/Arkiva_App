import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:arkiva/services/adobe_scan_service.dart';
import 'package:arkiva/services/responsive_service.dart';
import 'package:arkiva/services/upload_service.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async'; // Added for Timer

class AdobeScanScreen extends StatefulWidget {
  final Dossier? dossier;
  
  const AdobeScanScreen({
    super.key,
    this.dossier,
  });

  @override
  State<AdobeScanScreen> createState() => _AdobeScanScreenState();
}

class _AdobeScanScreenState extends State<AdobeScanScreen> with TickerProviderStateMixin {
  final AdobeScanService _adobeScanService = AdobeScanService();
  final UploadService _uploadService = UploadService();
  
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isDocumentDetected = false;
  bool _isAutoCaptureEnabled = true;
  Rectangle? _detectedRectangle;
  
  // Animations Adobe Scan exactes
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late AnimationController _autoCaptureController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _scanLineAnimation;
  late Animation<double> _autoCaptureAnimation;
  
  // Liste des documents scannés Adobe style
  final List<AdobeScanResult> _scannedDocuments = [];
  
  // Auto-capture timer
  Timer? _autoCaptureTimer;
  int _stableDetectionCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeAdobeAnimations();
    _initializeCamera();
  }

  void _initializeAdobeAnimations() {
    // Animation de pulsation Adobe
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animation ligne de scan Adobe
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scanLineAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));

    // Animation auto-capture Adobe
    _autoCaptureController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _autoCaptureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _autoCaptureController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations
    _pulseController.repeat(reverse: true);
    _scanLineController.repeat();
  }

  Future<void> _initializeCamera() async {
    try {
      // Demander les permissions Adobe style
      final hasPermissions = await _requestAdobePermissions();
      if (!hasPermissions) {
        throw Exception('Permissions Adobe non accordées');
      }

      // Initialiser la caméra
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Aucune caméra disponible');
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Démarrer la détection Adobe
        _startAdobeDetection();
      }
    } catch (e) {
      debugPrint('Erreur initialisation Adobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Adobe Scan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () => _initializeCamera(),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _requestAdobePermissions() async {
    try {
      // Vérifier les permissions actuelles
      final cameraStatus = await Permission.camera.status;
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;

      final hasCamera = cameraStatus.isGranted;
      final hasStorage = storageStatus.isGranted || photosStatus.isGranted;

      if (hasCamera && hasStorage) {
        return true;
      }

      // Demander les permissions Adobe style
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Adobe Scan - Permissions'),
          content: const Text(
            'Adobe Scan nécessite l\'accès à la caméra et au stockage pour scanner vos documents.\n\n'
            '• Caméra : Détection automatique des documents\n'
            '• Stockage : Sauvegarde des scans\n\n'
            'Voulez-vous autoriser Adobe Scan ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Autoriser Adobe Scan'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) {
        return false;
      }

      return await _adobeScanService.requestAdobePermissions();
    } catch (e) {
      debugPrint('Erreur permissions Adobe: $e');
      return false;
    }
  }

  void _startAdobeDetection() {
    if (_controller == null || !_isInitialized) return;

    _controller!.startImageStream((image) {
      _detectAdobeDocument(image);
    });
  }

  void _detectAdobeDocument(CameraImage image) {
    if (_isProcessing) return;

    _adobeScanService.detectDocumentEdgesRealTime(image).then((rectangle) {
      if (mounted) {
        setState(() {
          _detectedRectangle = rectangle;
          final wasDetected = _isDocumentDetected;
          _isDocumentDetected = rectangle != null;
          
          // Gestion auto-capture Adobe
          if (_isDocumentDetected && !wasDetected) {
            _stableDetectionCount++;
            if (_stableDetectionCount >= 3 && _isAutoCaptureEnabled) {
              _startAutoCapture();
            }
          } else if (!_isDocumentDetected) {
            _stableDetectionCount = 0;
            _cancelAutoCapture();
          }
        });
      }
    });
  }

  void _startAutoCapture() {
    _cancelAutoCapture();
    _autoCaptureTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isDocumentDetected && !_isProcessing) {
        _captureAdobeDocument();
      }
    });
    _autoCaptureController.forward();
  }

  void _cancelAutoCapture() {
    _autoCaptureTimer?.cancel();
    _autoCaptureController.reverse();
  }

  Future<void> _captureAdobeDocument() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Arrêter le stream pour la capture
      await _controller!.stopImageStream();

      // Capturer l'image Adobe style
      final image = await _controller!.takePicture();
      
      // Traiter avec Adobe Scan
      final scanResult = await _adobeScanService.processAdobeScan(
        File(image.path),
        _detectedRectangle,
      );
      
      if (mounted) {
        setState(() {
          _scannedDocuments.add(scanResult);
        });

        // Feedback Adobe style
        _showAdobeFeedback(scanResult);
      }

      // Redémarrer la détection Adobe
      _startAdobeDetection();
    } catch (e) {
      debugPrint('Erreur capture Adobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Adobe Scan: $e'),
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

  void _showAdobeFeedback(AdobeScanResult scanResult) {
    String message;
    Color backgroundColor;
    IconData icon;

    switch (scanResult.quality) {
      case ScanQuality.excellent:
        message = 'Excellent scan !';
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case ScanQuality.good:
        message = 'Bon scan !';
        backgroundColor = Colors.blue;
        icon = Icons.check_circle_outline;
        break;
      case ScanQuality.fair:
        message = 'Scan acceptable';
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case ScanQuality.poor:
        message = 'Scan de faible qualité';
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _uploadAdobeDocuments() async {
    if (_scannedDocuments.isEmpty) return;

    try {
      final authState = Provider.of<AuthStateService>(context, listen: false);
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Non authentifié');
      }

      // Upload Adobe style
      await _uploadService.uploadScannedDocuments(
        token: token,
        files: _scannedDocuments.map((doc) => doc.processedImage).toList(),
        dossierId: widget.dossier?.dossierId,
        entrepriseId: entrepriseId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents Adobe Scan uploadés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retour à l'écran précédent
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Erreur upload Adobe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleAutoCapture() {
    setState(() {
      _isAutoCaptureEnabled = !_isAutoCaptureEnabled;
    });
  }

  void _testAdobePermissions() async {
    final hasPermissions = await _requestAdobePermissions();
    if (hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions Adobe Scan accordées !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions Adobe Scan refusées'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    _autoCaptureController.dispose();
    _autoCaptureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adobe Scan'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          // Bouton auto-capture Adobe
          IconButton(
            icon: Icon(_isAutoCaptureEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined),
            onPressed: _toggleAutoCapture,
            tooltip: 'Auto-capture Adobe',
          ),
          // Bouton permissions Adobe
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _testAdobePermissions,
            tooltip: 'Permissions Adobe',
          ),
          // Bouton upload Adobe
          if (_scannedDocuments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: _isProcessing ? null : _uploadAdobeDocuments,
              tooltip: 'Upload Adobe Scan',
            ),
        ],
      ),
      body: _buildAdobeBody(),
    );
  }

  Widget _buildAdobeBody() {
    if (!_isInitialized) {
      return _buildAdobeLoadingView();
    }

    return Column(
      children: [
        // Vue caméra Adobe
        Expanded(
          child: _buildAdobeCameraView(),
        ),
        // Contrôles Adobe
        _buildAdobeControls(),
      ],
    );
  }

  Widget _buildAdobeLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Initialisation Adobe Scan...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdobeCameraView() {
    if (_controller == null) {
      return Container(color: Colors.black);
    }

    return Stack(
      children: [
        // Vue caméra
        CameraPreview(_controller!),
        
        // Overlay Adobe Scan
        _buildAdobeOverlay(),
        
        // Ligne de scan Adobe
        if (_isDocumentDetected)
          _buildAdobeScanLine(),
        
        // Auto-capture indicator
        if (_isAutoCaptureEnabled && _isDocumentDetected)
          _buildAdobeAutoCaptureIndicator(),
      ],
    );
  }

  Widget _buildAdobeOverlay() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: AdobeScanOverlayPainter(
            detectedRectangle: _detectedRectangle,
            isDocumentDetected: _isDocumentDetected,
            pulseScale: _pulseAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildAdobeScanLine() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _scanLineAnimation,
          child: Container(
            height: 2,
            color: Colors.green,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.transparent, Colors.green],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdobeAutoCaptureIndicator() {
    return AnimatedBuilder(
      animation: _autoCaptureAnimation,
      builder: (context, child) {
        return Positioned(
          top: 50,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(_autoCaptureAnimation.value),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdobeControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton capture Adobe
          GestureDetector(
            onTap: _isProcessing ? null : _captureAdobeDocument,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isProcessing ? Colors.grey : Colors.green[600],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                _isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          
          // Compteur Adobe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_scannedDocuments.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour l'overlay Adobe Scan
class AdobeScanOverlayPainter extends CustomPainter {
  final Rectangle? detectedRectangle;
  final bool isDocumentDetected;
  final double pulseScale;

  AdobeScanOverlayPainter({
    this.detectedRectangle,
    required this.isDocumentDetected,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detectedRectangle == null) return;

    final paint = Paint()
      ..color = isDocumentDetected ? Colors.green : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * pulseScale;

    final rect = Rect.fromLTWH(
      detectedRectangle!.x.toDouble(),
      detectedRectangle!.y.toDouble(),
      detectedRectangle!.width.toDouble(),
      detectedRectangle!.height.toDouble(),
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(AdobeScanOverlayPainter oldDelegate) {
    return oldDelegate.detectedRectangle != detectedRectangle ||
           oldDelegate.isDocumentDetected != isDocumentDetected ||
           oldDelegate.pulseScale != pulseScale;
  }
} 