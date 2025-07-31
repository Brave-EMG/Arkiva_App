import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/auth_state_service.dart';
import '../services/theme_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Champs du formulaire d'inscription
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔄 Début du processus d\'inscription...');
    setState(() => _isLoading = true);

    try {
      print('📝 Validation du formulaire d\'inscription...');
      final response = await _authService.registerAdmin(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
      );

      print('✅ Inscription réussie, redirection vers la création d\'entreprise...');
      final authStateService = context.read<AuthStateService>();
      await authStateService.setAuthState(
        response['token'],
        response['userId'],
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/create-entreprise');

    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Section gauche avec illustration
        Expanded(
          flex: 3,
          child: _buildIllustrationSection(),
        ),
        // Section droite avec formulaire
        Expanded(
          flex: 2,
          child: _buildRegisterForm(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Illustration compacte en haut pour mobile
          Container(
            height: 180,
            child: _buildIllustrationSection(),
          ),
          // Formulaire en bas
          Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 180,
            ),
            child: _buildRegisterForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArkivaColors.primary,
            ArkivaColors.primaryLight,
            const Color(0xFF6366F1), // Violet moderne
          ],
        ),
      ),
      child: Stack(
        children: [
          // Formes géométriques animées
          _buildAnimatedShapes(),
          // Illustration principale
          Center(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration de gestion de fichiers
                      _buildFileManagementIllustration(),
                      const SizedBox(height: 20),
                      Text(
                        'Organisez vos documents\nintelligemment',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Créez votre compte et rejoignez\nla solution d\'archivage moderne',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedShapes() {
    return Stack(
      children: [
        // Cercle animé en haut à droite
        Positioned(
          top: -50,
          right: -50,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _fadeAnimation.value * 0.8,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ),
        // Rectangle arrondi en bas à gauche
        Positioned(
          bottom: -30,
          left: -30,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _fadeAnimation.value * 0.6,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: ArkivaColors.secondary.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
        ),
        // Petit cercle accent
        Positioned(
          top: 100,
          left: 50,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _fadeAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArkivaColors.accent.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileManagementIllustration() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fadeAnimation.value,
          child: Container(
            width: 200,
            height: 160,
            child: Stack(
              children: [
                // Cloud de stockage en arrière-plan
                Positioned(
                  top: 0,
                  left: 50,
                  child: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.cloud_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                // Dossier principal
                Positioned(
                  top: 40,
                  left: 20,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: ArkivaColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                // Documents flottants
                Positioned(
                  top: 60,
                  right: 20,
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.description,
                      color: ArkivaColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                // Fichier scanné
                Positioned(
                  bottom: 0,
                  left: 80,
                  child: Container(
                    width: 50,
                    height: 35,
                    decoration: BoxDecoration(
                      color: ArkivaColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.scanner,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Icône de vérification
                Positioned(
                  top: 30,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: ArkivaColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      decoration: BoxDecoration(
        color: ArkivaColors.neutral50,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // En-tête
                            Text(
                              'Créer un compte',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: ArkivaColors.neutral800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rejoignez ARKIVA et commencez à organiser',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: ArkivaColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Formulaire
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildModernTextField(
                                    controller: _usernameController,
                                    label: 'Nom d\'utilisateur',
                                    hint: 'Votre nom d\'utilisateur',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre nom d\'utilisateur';
                                      }
                                      if (value.length < 3) {
                                        return 'Le nom doit contenir au moins 3 caractères';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildModernTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'votre@email.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Email invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildModernTextField(
                                    controller: _passwordController,
                                    label: 'Mot de passe',
                                    hint: '••••••••',
                                    icon: Icons.lock_outlined,
                                    obscureText: !_isPasswordVisible,
                                    suffixIcon: _isPasswordVisible 
                                        ? Icons.visibility_off_outlined 
                                        : Icons.visibility_outlined,
                                    onSuffixPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre mot de passe';
                                      }
                                      if (value.length < 8) {
                                        return 'Le mot de passe doit contenir au moins 8 caractères';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Bouton principal
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ArkivaColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              'Créer mon compte',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Déjà un compte ? ',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: ArkivaColors.neutral600,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Se connecter',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: ArkivaColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    IconData? suffixIcon,
    VoidCallback? onSuffixPressed,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ArkivaColors.neutral700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ArkivaColors.neutral400,
            ),
            prefixIcon: icon != null 
                ? Icon(icon, color: ArkivaColors.neutral500, size: 20) 
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: ArkivaColors.neutral500, size: 20),
                    onPressed: onSuffixPressed,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ArkivaColors.neutral200,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ArkivaColors.neutral200,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ArkivaColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ArkivaColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
} 