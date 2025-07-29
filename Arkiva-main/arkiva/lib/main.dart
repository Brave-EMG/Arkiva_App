import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/home_screen.dart';
import 'package:arkiva/screens/login_screen.dart';
import 'package:arkiva/screens/register_screen.dart';
import 'package:arkiva/screens/splash_screen.dart';
import 'package:arkiva/screens/armoires_screen.dart';
import 'package:arkiva/screens/casiers_screen.dart';
import 'package:arkiva/screens/dossiers_screen.dart';
import 'package:arkiva/screens/fichiers_screen.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/profile_screen.dart';
import 'package:arkiva/screens/settings_screen.dart';
import 'package:arkiva/screens/backups_screen.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';
import 'package:arkiva/screens/responsive_test_screen.dart';
import 'package:arkiva/screens/welcome_screen.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/armoire_service.dart';
import 'package:arkiva/services/casier_service.dart';
import 'package:arkiva/services/dossier_service.dart';
import 'package:arkiva/services/fichier_service.dart';
import 'package:arkiva/services/backup_service.dart';
import 'package:arkiva/services/admin_service.dart';
import 'package:arkiva/services/responsive_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AuthStateService()),
      ],
      child: const ArkivaApp(),
    ),
  );
}

class ArkivaApp extends StatelessWidget {
  const ArkivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final authStateService = context.watch<AuthStateService>();

    return MaterialApp(
      title: 'ARKIVA',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/scan': (context) => const ScanScreen(),
        '/upload': (context) => const UploadScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/backups': (context) => const BackupsScreen(),
        '/versions': (context) => const VersionsScreen(),
        '/restorations': (context) => const RestorationsScreen(),
        '/responsive-test': (context) => const ResponsiveTestScreen(),
        '/payment': (context) => PaymentScreen(
          paymentId: '1', // ID de test
          authToken: 'your_test_token_here', // Token de test
        ),
        '/payment-success': (context) => PaymentSuccessScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Empêche le redimensionnement du texte
          ),
          child: child!,
        );
      },
    );
  }
}
