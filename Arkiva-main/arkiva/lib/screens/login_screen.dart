import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/register_screen.dart';
import 'package:arkiva/services/auth_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/theme_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _code2FAController = TextEditingController();
  bool _show2FA = false;
  String? _token;
  String? _errorMsg;
  bool _isLoading = false;
  final _authService = AuthService();
  int? _userId;
  bool _isPasswordVisible = false;
  
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
    _code2FAController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
      );
    final data = jsonDecode(response.body);
    print('Réponse backend : ${response.body}'); // Log la réponse brute
    if (response.statusCode == 200) {
      final user = data['user'];
      if (user == null || user['user_id'] == null || user['role'] == null) {
        setState(() {
          _errorMsg = "Réponse du serveur incomplète. Veuillez contacter l'administrateur.";
          _isLoading = false;
        });
        print('Réponse inattendue : $data');
        return;
      }
      _token = data['token'];
      _userId = user['user_id'];
      if (user['two_factor_enabled'] == true) {
        setState(() { _show2FA = true; });
        // Optionnel : renvoyer un code à chaque tentative de login
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/enable'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'method': 'email'}),
        );
      } else {
        // Connexion normale
      final authStateService = context.read<AuthStateService>();
      await authStateService.setAuthState(
          _token!,
          _userId!.toString(),
        );
        final userInfo = await _authService.getUserInfo(_token!);
        final userRole = userInfo['role'];
        final entrepriseId = userInfo['entreprise_id'];
        if (!mounted) return;
        if (userRole == 'admin' && (entrepriseId == 0 || entrepriseId == null)) {
          print('✅ Admin connecté sans entreprise, redirection vers la création d\'entreprise.');
          Navigator.of(context).pushReplacementNamed('/create-entreprise');
        } else {
          print('✅ Utilisateur connecté (Admin avec entreprise ou autre rôle), redirection vers l\'accueil.');
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } else {
      setState(() { _errorMsg = data['message'] ?? 'Erreur de connexion'; });
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _verify2FA() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/2fa/verify'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': _code2FAController.text.trim()}),
      );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final newToken = data['token'];
      // Récupérer les informations complètes de l'utilisateur avec le nouveau token
      final userInfo = await _authService.getUserInfo(newToken);
      final userId = userInfo['user_id'].toString();
      final userRole = userInfo['role'];
      final entrepriseId = userInfo['entreprise_id'];
      final authStateService = context.read<AuthStateService>();
      await authStateService.setAuthState(
        newToken,
        userId,
      );
      if (!mounted) return;
      if (userRole == 'admin' && (entrepriseId == 0 || entrepriseId == null)) {
        print('✅ Admin connecté sans entreprise, redirection vers la création d\'entreprise.');
        Navigator.of(context).pushReplacementNamed('/create-entreprise');
      } else {
        print('✅ Utilisateur connecté (Admin avec entreprise ou autre rôle), redirection vers l\'accueil.');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() { _errorMsg = data['message'] ?? 'Code 2FA invalide'; });
    }
    setState(() { _isLoading = false; });
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
          child: _buildLoginForm(),
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
            child: _buildLoginForm(),
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
                        'Scannez • Classez • Recherchez\nVos fichiers en toute sécurité',
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

  Widget _buildLoginForm() {
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
                              _show2FA ? 'Vérification' : 'Bonjour !',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: ArkivaColors.neutral800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _show2FA 
                                  ? 'Entrez le code de vérification'
                                  : 'Connectez-vous à votre compte',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: ArkivaColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Formulaire
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (!_show2FA) ...[
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
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          // TODO: Mot de passe oublié
                                        },
                                        child: Text(
                                          'Mot de passe oublié ?',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: ArkivaColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: ArkivaColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: ArkivaColors.primary.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.security_outlined,
                                            color: ArkivaColors.primary,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Un code de vérification a été envoyé à votre email.',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: ArkivaColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildModernTextField(
                                      controller: _code2FAController,
                                      label: 'Code de vérification',
                                      hint: '123456',
                                      icon: Icons.verified_user_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer le code de vérification';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  
                                  // Message d'erreur
                                  if (_errorMsg != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: ArkivaColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: ArkivaColors.error.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: ArkivaColors.error,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMsg!,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: ArkivaColors.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Bouton principal
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : (_show2FA ? _verify2FA : _login),
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
                                              _show2FA ? 'Vérifier le code' : 'Se connecter',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  
                                  if (!_show2FA) ...[
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Pas encore de compte ? ',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: ArkivaColors.neutral600,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                            );
                                          },
                                          child: Text(
                                            'S\'inscrire',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: ArkivaColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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