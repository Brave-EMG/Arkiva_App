import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:arkiva/services/image_processing_service.dart';
import 'package:arkiva/services/responsive_service.dart';

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

  void _launchAdobeScan() {
    // TODO: Passer le dossier actuel
    Navigator.pushNamed(context, '/adobe-scan', arguments: null);
  }

  Widget _buildMobileLayout() {
    return ResponsiveService.responsiveCard(
      context: context,
      child: Column(
        children: [
          // Interface caméra adaptée mobile
          Expanded(
            child: _buildCameraPreview(),
          ),
          // Contrôles adaptés
          _buildMobileControls(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Prévisualisation caméra
        Expanded(
          flex: 2,
          child: _buildCameraPreview(),
        ),
        // Panneau de contrôle
        Expanded(
          flex: 1,
          child: _buildTabletControls(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Prévisualisation caméra
        Expanded(
          flex: 3,
          child: _buildCameraPreview(),
        ),
        // Panneau de contrôle
        Expanded(
          flex: 1,
          child: _buildDesktopControls(),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
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

    return Stack(
      children: [
        // Prévisualisation de la caméra
        CameraPreview(_controller!),
        
        // Overlay de cadrage si activé
        if (_showOverlay)
          CustomPaint(
            painter: DocumentOverlayPainter(),
            size: Size.infinite,
          ),
      ],
    );
  }

  Widget _buildMobileControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Bouton de capture
          GestureDetector(
            onTap: _isProcessing ? null : _captureAndProcess,
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
          
          // Bouton Adobe Scan
          GestureDetector(
            onTap: _launchAdobeScan,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green[600],
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
                Icons.auto_awesome,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletControls() {
    return ResponsiveService.responsiveCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: TextStyle(
              fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
          Text(
            '1. Placez le document dans le cadre de cadrage\n'
            '2. Assurez-vous que le document est bien éclairé\n'
            '3. Cliquez sur "Scanner" pour capturer l\'image\n'
            '4. Ajustez les filtres si nécessaire',
            style: TextStyle(
              fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
              color: Colors.grey[700],
            ),
          ),
          
          SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
          
          // Options de scan
          ResponsiveService.responsiveCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options de scan',
                  style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                
                // Switch pour le redimensionnement automatique
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Redimensionnement automatique',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                        ),
                      ),
                    ),
                    Switch(
                      value: _autoResize,
                      onChanged: (value) {
                        setState(() {
                          _autoResize = value;
                        });
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                
                // Switch pour l'overlay
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Afficher le cadre de cadrage',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                        ),
                      ),
                    ),
                    Switch(
                      value: _showOverlay,
                      onChanged: (value) {
                        setState(() {
                          _showOverlay = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
          
          // Boutons de scan
          Row(
            children: [
              Expanded(
                child: ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: _isProcessing ? null : _captureAndProcess,
                  backgroundColor: _isProcessing ? Colors.grey : Colors.blue[600],
                  foregroundColor: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
                        size: ResponsiveService.getIconSize(context),
                      ),
                      SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                      Text(
                        _isProcessing ? 'Traitement...' : 'Scanner le document',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 12)),
              Expanded(
                child: ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: _launchAdobeScan,
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: ResponsiveService.getIconSize(context),
                      ),
                      SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                      Text(
                        'Adobe Scan',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopControls() {
    return _buildTabletControls();
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
        title: Text(
          'Scanner un document',
          style: TextStyle(
            fontSize: ResponsiveService.getFontSize(context, baseSize: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[900]!, Colors.blue[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ResponsiveService.responsiveBuilder(
        context: context,
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
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