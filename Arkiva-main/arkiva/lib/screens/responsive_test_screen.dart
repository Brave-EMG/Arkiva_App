import 'package:flutter/material.dart';
import 'package:arkiva/services/responsive_service.dart';

class ResponsiveTestScreen extends StatelessWidget {
  const ResponsiveTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test Responsive',
          style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 18)),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: ResponsiveService.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations sur l'écran
            ResponsiveService.responsiveCard(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations de l\'écran',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveService.getPadding(context)),
                  _buildInfoRow('Largeur', '${ResponsiveService.getScreenWidth(context).toStringAsFixed(0)}px'),
                  _buildInfoRow('Hauteur', '${ResponsiveService.getScreenHeight(context).toStringAsFixed(0)}px'),
                  _buildInfoRow('Type d\'appareil', ResponsiveService.isMobile(context) ? 'Mobile' : 
                    ResponsiveService.isTablet(context) ? 'Tablette' : 'Desktop'),
                  _buildInfoRow('Orientation', ResponsiveService.isLandscape(context) ? 'Paysage' : 'Portrait'),
                  _buildInfoRow('Padding', '${ResponsiveService.getPadding(context)}px'),
                  _buildInfoRow('Taille d\'icône', '${ResponsiveService.getIconSize(context)}px'),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            // Test de grille responsive
            Text(
              'Test de grille responsive',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            ResponsiveService.responsiveGrid(
              context: context,
              children: List.generate(6, (index) => _buildTestCard('Card ${index + 1}')),
              mobileCrossAxisCount: 1,
              tabletCrossAxisCount: 2,
              desktopCrossAxisCount: 3,
            ),
            
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            // Test de boutons
            Text(
              'Test de boutons',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            ResponsiveService.responsiveButton(
              context: context,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bouton responsive cliqué !')),
                );
              },
              child: Text(
                'Bouton Responsive',
                style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
              ),
            ),
            
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            // Test de champs de texte
            Text(
              'Test de champs de texte',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            ResponsiveService.responsiveTextField(
              context: context,
              controller: TextEditingController(),
              labelText: 'Champ de texte responsive',
              hintText: 'Entrez du texte ici...',
              prefixIcon: Icon(Icons.edit),
            ),
            
            SizedBox(height: ResponsiveService.getPadding(context)),
            
            // Test de dialogue
            ResponsiveService.responsiveButton(
              context: context,
              onPressed: () => _showResponsiveDialog(context),
              child: Text(
                'Ouvrir dialogue responsive',
                style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(String title) {
    return Builder(
      builder: (context) => ResponsiveService.responsiveCard(
        context: context,
        child: Column(
          children: [
            Icon(
              Icons.star,
              size: ResponsiveService.getIconSize(context),
              color: Colors.amber,
            ),
            SizedBox(height: ResponsiveService.getPadding(context) * 0.5),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showResponsiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ResponsiveService.responsiveDialog(
        context: context,
        title: 'Dialogue Responsive',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: ResponsiveService.getIconSize(context) * 2,
              color: Colors.green,
            ),
            SizedBox(height: ResponsiveService.getPadding(context)),
            Text(
              'Ce dialogue s\'adapte à la taille de l\'écran !',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
              ),
              textAlign: TextAlign.center,
            ),
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
} 