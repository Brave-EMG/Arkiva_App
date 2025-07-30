import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arkiva/services/responsive_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un fichier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Implémenter l'upload des fichiers
      await Future.delayed(const Duration(seconds: 2)); // Simulation d'upload
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fichiers téléversés avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedFiles = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildDropZone() {
    return ResponsiveService.responsiveCard(
      context: context,
      child: Container(
        height: ResponsiveService.isMobile(context) ? 200 : 300,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(ResponsiveService.getBorderRadius(context)),
          color: Colors.blue[50],
        ),
        child: InkWell(
          onTap: _isUploading ? null : _pickFiles,
          borderRadius: BorderRadius.circular(ResponsiveService.getBorderRadius(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload,
                size: ResponsiveService.getIconSize(context) * 3,
                color: Colors.blue[600],
              ),
              SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
              Text(
                'Glissez vos fichiers ici ou cliquez pour sélectionner',
                style: TextStyle(
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 8)),
              Text(
                'Formats supportés: PDF, JPG, PNG, DOC, DOCX',
                style: TextStyle(
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return ResponsiveService.responsiveCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fichiers sélectionnés (${_selectedFiles.length})',
            style: TextStyle(
              fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
          ResponsiveService.responsiveBuilder(
            context: context,
            mobile: _buildMobileFilesList(),
            tablet: _buildTabletFilesList(),
            desktop: _buildDesktopFilesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        return ResponsiveService.responsiveCard(
          context: context,
          child: ListTile(
            leading: Icon(
              _getFileIcon(file.name),
              size: ResponsiveService.getIconSize(context),
              color: _getFileColor(file.name),
            ),
            title: Text(
              file.name,
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${(file.size / 1024).toStringAsFixed(2)} KB',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                color: Colors.grey[600],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveService.getIconSize(context),
                color: Colors.red[600],
              ),
              onPressed: () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletFilesList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 12),
        mainAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 12),
      ),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        return ResponsiveService.responsiveCard(
          context: context,
          child: ListTile(
            leading: Icon(
              _getFileIcon(file.name),
              size: ResponsiveService.getIconSize(context),
              color: _getFileColor(file.name),
            ),
            title: Text(
              file.name,
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${(file.size / 1024).toStringAsFixed(2)} KB',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                color: Colors.grey[600],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveService.getIconSize(context),
                color: Colors.red[600],
              ),
              onPressed: () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopFilesList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 16),
        mainAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 16),
      ),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        return ResponsiveService.responsiveCard(
          context: context,
          child: ListTile(
            leading: Icon(
              _getFileIcon(file.name),
              size: ResponsiveService.getIconSize(context),
              color: _getFileColor(file.name),
            ),
            title: Text(
              file.name,
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${(file.size / 1024).toStringAsFixed(2)} KB',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                color: Colors.grey[600],
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                size: ResponsiveService.getIconSize(context),
                color: Colors.red[600],
              ),
              onPressed: () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red[600]!;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green[600]!;
      case 'doc':
      case 'docx':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildActionButtons() {
    return ResponsiveService.responsiveBuilder(
      context: context,
      mobile: Column(
        children: [
          ResponsiveService.responsiveButton(
            context: context,
            onPressed: _isUploading ? null : _pickFiles,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: ResponsiveService.getIconSize(context)),
                SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                Text(
                  'Sélectionner des fichiers',
                  style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedFiles.isNotEmpty) ...[
            SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
            ResponsiveService.responsiveButton(
              context: context,
              onPressed: _isUploading ? null : _uploadFiles,
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isUploading)
                    SizedBox(
                      width: ResponsiveService.getIconSize(context),
                      height: ResponsiveService.getIconSize(context),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(Icons.upload, size: ResponsiveService.getIconSize(context)),
                  SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                  Text(
                    _isUploading ? 'Téléversement...' : 'Téléverser',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      tablet: Row(
        children: [
          Expanded(
            child: ResponsiveService.responsiveButton(
              context: context,
              onPressed: _isUploading ? null : _pickFiles,
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: ResponsiveService.getIconSize(context)),
                  SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                  Text(
                    'Sélectionner des fichiers',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedFiles.isNotEmpty) ...[
            SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 16)),
            Expanded(
              child: ResponsiveService.responsiveButton(
                context: context,
                onPressed: _isUploading ? null : _uploadFiles,
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      SizedBox(
                        width: ResponsiveService.getIconSize(context),
                        height: ResponsiveService.getIconSize(context),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Icon(Icons.upload, size: ResponsiveService.getIconSize(context)),
                    SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                    Text(
                      _isUploading ? 'Téléversement...' : 'Téléverser',
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
        ],
      ),
      desktop: Row(
        children: [
          Expanded(
            child: ResponsiveService.responsiveButton(
              context: context,
              onPressed: _isUploading ? null : _pickFiles,
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: ResponsiveService.getIconSize(context)),
                  SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                  Text(
                    'Sélectionner des fichiers',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedFiles.isNotEmpty) ...[
            SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 16)),
            Expanded(
              child: ResponsiveService.responsiveButton(
                context: context,
                onPressed: _isUploading ? null : _uploadFiles,
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isUploading)
                      SizedBox(
                        width: ResponsiveService.getIconSize(context),
                        height: ResponsiveService.getIconSize(context),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Icon(Icons.upload, size: ResponsiveService.getIconSize(context)),
                    SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                    Text(
                      _isUploading ? 'Téléversement...' : 'Téléverser',
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Téléverser des fichiers',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[50]!, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ResponsiveService.responsiveBuilder(
          context: context,
          mobile: SingleChildScrollView(
            padding: ResponsiveService.getScreenPadding(context),
            child: Column(
              children: [
                _buildDropZone(),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                _buildFilesList(),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                _buildActionButtons(),
              ],
            ),
          ),
          tablet: Padding(
            padding: ResponsiveService.getScreenPadding(context),
            child: Column(
              children: [
                _buildDropZone(),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                Expanded(child: _buildFilesList()),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                _buildActionButtons(),
              ],
            ),
          ),
          desktop: Padding(
            padding: ResponsiveService.getScreenPadding(context),
            child: Column(
              children: [
                _buildDropZone(),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                Expanded(child: _buildFilesList()),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 