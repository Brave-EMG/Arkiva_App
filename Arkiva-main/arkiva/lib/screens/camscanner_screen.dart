import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:arkiva/services/camscanner_service.dart';
import 'package:arkiva/services/upload_service.dart';
import 'package:arkiva/models/dossier.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CamScannerScreen extends StatefulWidget {
  final Dossier? dossier;
  
  const CamScannerScreen({
    super.key,
    this.dossier,
  });

  @override
  State<CamScannerScreen> createState() => _CamScannerScreenState();
}

class _CamScannerScreenState extends State<CamScannerScreen> {
  final CamScannerService _camScannerService = CamScannerService();
  final UploadService _uploadService = UploadService();
  
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCaptured = false;
  
  // Résultat du scan
  CamScannerResult? _scanResult;
  File? _capturedImage;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Demander les permissions
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        throw Exception('Permissions non accordées');
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
      }
    } catch (e) {
      debugPrint('Erreur initialisation caméra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur CamScanner: $e'),
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

  Future<bool> _requestPermissions() async {
    try {
      final cameraStatus = await Permission.camera.request();
      final storageStatus = await Permission.storage.request();
      
      return cameraStatus.isGranted && storageStatus.isGranted;
    } catch (e) {
      debugPrint('Erreur permissions: $e');
      return false;
    }
  }

  Future<void> _captureDocument() async {
    if (_controller == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capturer l'image
      final image = await _controller!.takePicture();
      final capturedFile = File(image.path);
      
      setState(() {
        _capturedImage = capturedFile;
        _isCaptured = true;
      });

      // Traiter avec CamScanner
      final result = await _camScannerService.processDocumentScan(capturedFile);
      
      if (mounted) {
        setState(() {
          _scanResult = result;
        });

        // Afficher le feedback
        _showScanFeedback(result);
      }
    } catch (e) {
      debugPrint('Erreur capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur capture: $e'),
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

  void _showScanFeedback(CamScannerResult result) {
    String message;
    Color backgroundColor;
    IconData icon;

    switch (result.quality) {
      case ScanQuality.excellent:
        message = 'Excellent scan ! Texte parfaitement détecté.';
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case ScanQuality.good:
        message = 'Bon scan ! Texte bien détecté.';
        backgroundColor = Colors.blue;
        icon = Icons.check_circle_outline;
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

  Future<void> _validateScan() async {
    if (_scanResult == null) return;

    try {
      final authState = Provider.of<AuthStateService>(context, listen: false);
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;

      if (token == null || entrepriseId == null) {
        throw Exception('Non authentifié');
      }

      // Upload du document traité
      await _uploadService.uploadScannedDocuments(
        token: token,
        files: [_scanResult!.processedImage],
        dossierId: widget.dossier?.dossierId,
        entrepriseId: entrepriseId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document CamScanner uploadé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retour à l'écran précédent
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Erreur upload: $e');
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

  void _retakePhoto() {
    setState(() {
      _isCaptured = false;
      _capturedImage = null;
      _scanResult = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CamScanner'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isInitialized) {
      return _buildLoadingView();
    }

    if (_isCaptured && _scanResult != null) {
      return _buildResultView();
    }

    return _buildCameraView();
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Initialisation CamScanner...',
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

    return Column(
      children: [
        // Vue caméra
        Expanded(
          child: Stack(
            children: [
              CameraPreview(_controller!),
              
              // Overlay CamScanner
              _buildCamScannerOverlay(),
            ],
          ),
        ),
        
        // Contrôles
        _buildControls(),
      ],
    );
  }

  Widget _buildCamScannerOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Placez le document dans le cadre\nAppuyez sur le bouton pour scanner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
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
          // Bouton capture CamScanner
          GestureDetector(
            onTap: _isProcessing ? null : _captureDocument,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isProcessing ? Colors.grey : Colors.blue[600],
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
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Column(
      children: [
        // Image traitée
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _scanResult!.processedImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        // Informations du scan
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Qualité du scan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getQualityColor(_scanResult!.quality),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Qualité: ${_getQualityText(_scanResult!.quality)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Texte détecté (aperçu)
              if (_scanResult!.ocrText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Texte détecté (aperçu):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _scanResult!.ocrText.length > 100 
                          ? '${_scanResult!.ocrText.substring(0, 100)}...'
                          : _scanResult!.ocrText,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Boutons d'action
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Bouton refaire
              Expanded(
                child: ElevatedButton(
                  onPressed: _retakePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Refaire'),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Bouton valider
              Expanded(
                child: ElevatedButton(
                  onPressed: _validateScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
        ),
      ],
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
} 