import 'package:flutter/material.dart';
import 'package:arkiva/widgets/main_layout.dart';
import 'package:arkiva/services/theme_service.dart';

// EXEMPLE D'UTILISATION DU NOUVEAU LAYOUT AVEC NAVBAR
class ExamplePageWithNavbar extends StatelessWidget {
  const ExamplePageWithNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/example', // Route actuelle pour highlights
      title: 'Exemple de Page', // Titre optionnel dans l'AppBar
      actions: [
        // Actions optionnelles dans l'AppBar
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            // Action search
          },
        ),
        IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            // Menu d'actions
          },
        ),
      ],
      // Contenu principal de la page
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contenu de votre page',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: ArkivaColors.neutral800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Votre contenu ici...\n\n'
                'Le navbar se gère automatiquement :\n'
                '• Desktop : Sidebar fixe\n'
                '• Tablet/Mobile : Drawer\n'
                '• Navigation responsive\n'
                '• Thème cohérent',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}