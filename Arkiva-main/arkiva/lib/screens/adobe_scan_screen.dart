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
  Rectangle? _detectedRectangle;
  
  // Animation pour le feedback visuel
  late AnimationController _pulseController;
  late AnimationController _scanLineController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _scanLineAnimation;
  
  // Liste des documents scannés
  final List<ScanResult> _scannedDocuments = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Animation de pulsation pour le cadre de détection
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Animation de la ligne de scan
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _scanLineAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));
    _scanLineController.repeat();
  }

  Future<void> _initializeCamera() async {
    try {
      // Demander les permissions avec une interface utilisateur claire
      final hasPermissions = await _requestPermissionsWithUI();
      if (!hasPermissions) {
        throw Exception('Permissions non accordées');
      }

      // Initialiser la caméra
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Aucune caméra disponible');
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Démarrer la détection automatique
      _startDocumentDetection();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la caméra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation: $e'),
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

  Future<bool> _requestPermissionsWithUI() async {
    // Vérifier d'abord les permissions actuelles
    final cameraStatus = await Permission.camera.status;
    final storageStatus = await Permission.storage.status;

    // Si les permissions sont déjà accordées
    if (cameraStatus.isGranted && storageStatus.isGranted) {
      return true;
    }

    // Afficher une boîte de dialogue pour expliquer pourquoi nous avons besoin des permissions
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Requises'),
        content: const Text(
          'Cette fonctionnalité nécessite l\'accès à la caméra et au stockage pour scanner des documents. '
          'Voulez-vous accorder ces permissions ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Autoriser'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) {
      return false;
    }

    // Demander les permissions
    final hasPermissions = await _adobeScanService.requestPermissions();
    
    if (!hasPermissions) {
      // Afficher un message d'erreur si les permissions sont refusées
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Refusées'),
            content: const Text(
              'Les permissions sont nécessaires pour utiliser cette fonctionnalité. '
              'Vous pouvez les activer dans les paramètres de l\'application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Paramètres'),
              ),
            ],
          ),
        );
      }
    }

    return hasPermissions;
  }

  void _startDocumentDetection() {
    if (_controller == null || !_isInitialized) return;

    _controller!.startImageStream((CameraImage image) {
      _detectDocumentInStream(image);
    });
  }

  void _detectDocumentInStream(CameraImage image) {
    if (_isProcessing) return;

    _adobeScanService.detectDocumentEdges(image).then((rectangle) {
      if (mounted) {
        setState(() {
          _detectedRectangle = rectangle;
          _isDocumentDetected = rectangle != null;
        });
      }
    });
  }

  Future<void> _captureDocument() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Arrêter le stream pour la capture
      await _controller!.stopImageStream();

      // Capturer l'image
      final image = await _controller!.takePicture();
      
      // Traiter avec Adobe Scan
      final scanResult = await _adobeScanService.processDocumentScan(File(image.path));
      
      if (mounted) {
        setState(() {
          _scannedDocuments.add(scanResult);
        });

        // Afficher le feedback
        _showScanFeedback(scanResult);
      }

      // Redémarrer la détection
      _startDocumentDetection();
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

  void _showScanFeedback(ScanResult scanResult) {
    String message;
    Color backgroundColor;
    IconData icon;

    switch (scanResult.scanQuality) {
      case ScanQuality.excellent:
        message = 'Scan excellent ! Texte parfaitement détecté.';
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case ScanQuality.good:
        message = 'Scan de bonne qualité.';
        backgroundColor = Colors.blue;
        icon = Icons.check;
        break;
      case ScanQuality.fair:
        message = 'Scan acceptable. Vérifiez la qualité.';
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case ScanQuality.poor:
        message = 'Scan de faible qualité. Recommencez.';
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

  Future<void> _uploadScannedDocuments() async {
    if (_scannedDocuments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun document à uploader'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authStateService = context.read<AuthStateService>();
      final token = authStateService.token;
      final entrepriseId = authStateService.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Token ou ID entreprise manquant');
      }

      // Uploader tous les documents scannés
      for (final scanResult in _scannedDocuments) {
        await _uploadService.uploadScannedDocuments(
          token: token,
          files: [scanResult.enhancedImage],
          dossierId: widget.dossier?.dossierId ?? 0,
          entrepriseId: entrepriseId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_scannedDocuments.length} documents uploadés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retourner à l'écran précédent
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adobe Scan'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          if (_scannedDocuments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: _isProcessing ? null : _uploadScannedDocuments,
              tooltip: 'Uploader les documents',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return Column(
      children: [
        // Vue caméra avec overlay Adobe Scan
        Expanded(
          child: _buildCameraView(),
        ),
        // Contrôles
        _buildControls(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
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

  Widget _buildCameraView() {
    if (_controller == null) {
      return Container(color: Colors.black);
    }

    return Stack(
      children: [
        // Vue caméra
        CameraPreview(_controller!),
        
        // Overlay Adobe Scan
        _buildAdobeScanOverlay(),
        
        // Ligne de scan animée
        if (_isDocumentDetected)
          _buildScanLine(),
      ],
    );
  }

  Widget _buildAdobeScanOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Stack(
        children: [
          // Zone de détection
          if (_detectedRectangle != null)
            Positioned(
              left: _detectedRectangle!.x.toDouble(),
              top: _detectedRectangle!.y.toDouble(),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: _detectedRectangle!.width.toDouble(),
                      height: _detectedRectangle!.height.toDouble(),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Instructions
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isDocumentDetected 
                    ? 'Document détecté ! Appuyez pour scanner'
                    : 'Placez un document dans le cadre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Compteur de documents
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_scannedDocuments.length} docs',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanLine() {
    return Positioned(
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _scanLineAnimation,
        child: Container(
          height: 2,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton de capture
          GestureDetector(
            onTap: _isProcessing ? null : _captureDocument,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isDocumentDetected ? Colors.green : Colors.grey,
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
          
          // Bouton de prévisualisation
          if (_scannedDocuments.isNotEmpty)
            IconButton(
              onPressed: () => _showScannedDocuments(),
              icon: const Icon(Icons.preview, size: 30),
              tooltip: 'Voir les documents scannés',
            ),
        ],
      ),
    );
  }

  void _showScannedDocuments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildScannedDocumentsSheet(),
    );
  }

  Widget _buildScannedDocumentsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents scannés (${_scannedDocuments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _scannedDocuments.length,
              itemBuilder: (context, index) {
                final scanResult = _scannedDocuments[index];
                return _buildScannedDocumentTile(scanResult, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedDocumentTile(ScanResult scanResult, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(scanResult.enhancedImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text('Document ${index + 1}'),
        subtitle: Text(
          'Qualité: ${_getQualityText(scanResult.scanQuality)}\n'
          'Texte détecté: ${scanResult.ocrText.length} caractères',
        ),
        trailing: Icon(
          _getQualityIcon(scanResult.scanQuality),
          color: _getQualityColor(scanResult.scanQuality),
        ),
      ),
    );
  }

  String _getQualityText(ScanQuality quality) {
    switch (quality) {
      case ScanQuality.excellent:
        return 'Excellent';
      case ScanQuality.good:
        return 'Bon';
      case ScanQuality.fair:
        return 'Acceptable';
      case ScanQuality.poor:
        return 'Faible';
    }
  }

  IconData _getQualityIcon(ScanQuality quality) {
    switch (quality) {
      case ScanQuality.excellent:
        return Icons.check_circle;
      case ScanQuality.good:
        return Icons.check;
      case ScanQuality.fair:
        return Icons.warning;
      case ScanQuality.poor:
        return Icons.error;
    }
  }

  Color _getQualityColor(ScanQuality quality) {
    switch (quality) {
      case ScanQuality.excellent:
        return Colors.green;
      case ScanQuality.good:
        return Colors.blue;
      case ScanQuality.fair:
        return Colors.orange;
      case ScanQuality.poor:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanLineController.dispose();
    _controller?.dispose();
    _adobeScanService.dispose();
    super.dispose();
  }
} 