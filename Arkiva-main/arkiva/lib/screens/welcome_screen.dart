import 'package:flutter/material.dart';
import 'package:arkiva/screens/login_screen.dart';
import 'package:arkiva/screens/register_screen.dart';
import 'package:arkiva/services/theme_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeOut,
      ),
    );
    
    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      body: Container(
        height: screenSize.height,
        width: screenSize.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArkivaColors.primary,
              ArkivaColors.primaryLight,
              const Color(0xFF6366F1),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildMainContent(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Cercles flottants
            Positioned(
              top: -100,
              right: -50,
              child: Transform.scale(
                scale: _backgroundAnimation.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Transform.scale(
                scale: _backgroundAnimation.value * 0.8,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArkivaColors.secondary.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            // Formes géométriques
            Positioned(
              top: 150,
              left: 30,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 0.5,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: ArkivaColors.accent.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              right: 40,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 0.3,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            // Éléments de fichiers flottants
            Positioned(
              top: 120,
              right: 80,
              child: Transform.translate(
                offset: Offset(0, 20 * _backgroundAnimation.value),
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.white.withOpacity(0.2),
                  size: 40,
                ),
              ),
            ),
            Positioned(
              bottom: 300,
              left: 60,
              child: Transform.translate(
                offset: Offset(0, -15 * _backgroundAnimation.value),
                child: Icon(
                  Icons.folder_outlined,
                  color: Colors.white.withOpacity(0.15),
                  size: 35,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(bool isTablet) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _contentAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _contentAnimation,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 60 : 32,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 40),
                        _buildActionButtons(),
                        SizedBox(height: 20),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo animé - taille adaptative
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            final logoSize = isSmallScreen ? 80.0 : 100.0;
            final iconSize = isSmallScreen ? 40.0 : 50.0;
            
            return Transform.scale(
              scale: value,
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.archive_outlined,
                  size: iconSize,
                  color: ArkivaColors.primary,
                ),
              ),
            );
          },
        ),
        SizedBox(height: isSmallScreen ? 20 : 30),
        
        // Titre principal - taille adaptative
        Text(
          'ARKIVA',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            fontSize: isSmallScreen ? 32 : 38,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Sous-titre - taille adaptative
        Text(
          'Votre solution d\'archivage\nintelligent et sécurisé',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w400,
            fontSize: isSmallScreen ? 16 : 20,
            height: 1.3,
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Points clés
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isSmallScreen ? 12 : 20,
          runSpacing: 8,
          children: [
            _buildFeaturePoint('Organisez', Icons.folder_outlined, isSmallScreen),
            _buildFeaturePoint('Numérisez', Icons.scanner_outlined, isSmallScreen),
            _buildFeaturePoint('Sécurisez', Icons.security_outlined, isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturePoint(String text, IconData icon, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isSmallScreen ? 16 : 18,
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    final buttonHeight = isSmallScreen ? 50.0 : 56.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton Se connecter
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ArkivaColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.login_outlined,
                  color: ArkivaColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Se connecter',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ArkivaColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        
        // Bouton S'inscrire
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withOpacity(0.8),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Créer un compte',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 20 : 24),
        
        // Texte informatif - conditionnel pour les petits écrans
        if (!isSmallScreen)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gérez tous vos documents en toute sécurité avec ARKIVA',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '© 2024 ARKIVA. Tous droits réservés.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.6),
            fontSize: isSmallScreen ? 11 : 12,
          ),
          textAlign: TextAlign.center,
        ),
        if (!isSmallScreen) ...[
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 