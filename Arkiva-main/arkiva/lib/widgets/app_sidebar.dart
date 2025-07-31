import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/theme_service.dart';

import 'package:arkiva/screens/armoires_screen.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/favoris_screen.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';
import 'package:arkiva/screens/entreprise_detail_screen.dart';
import 'package:arkiva/screens/settings_screen.dart';
import 'package:arkiva/screens/tags_screen.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final bool isCollapsed;
  final VoidCallback? onToggle;

  const AppSidebar({
    Key? key,
    required this.currentRoute,
    this.isCollapsed = false,
    this.onToggle,
  }) : super(key: key);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String? _hoveredItem;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthStateService>();
    final userRole = authService.role;
    final isAdmin = userRole == 'admin';
    final username = authService.username ?? 'Utilisateur';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArkivaColors.primary,
            ArkivaColors.primaryLight,
            ArkivaColors.primary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(username),
          
          // Navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavigationSection('PRINCIPAL', [
                    _buildNavItem(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/home',
                      onTap: () => _navigateToHome(context),
                    ),
                    _buildNavItem(
                      icon: Icons.folder_outlined,
                      activeIcon: Icons.folder,
                      title: 'Armoires',
                      route: '/armoires',
                      onTap: () => _navigateToArmoires(context),
                    ),
                    _buildNavItem(
                      icon: Icons.star_border,
                      activeIcon: Icons.star,
                      title: 'Favoris',
                      route: '/favoris',
                      onTap: () => _navigateToFavoris(context),
                    ),
                    _buildNavItem(
                      icon: Icons.tag_outlined,
                      activeIcon: Icons.tag,
                      title: 'Tags',
                      route: '/tags',
                      onTap: () => _navigateToTags(context),
                    ),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  _buildNavigationSection('ACTIONS', [
                    _buildNavItem(
                      icon: Icons.scanner_outlined,
                      activeIcon: Icons.scanner,
                      title: 'Scanner',
                      route: '/scan',
                      onTap: () => _navigateToScan(context),
                    ),
                    _buildNavItem(
                      icon: Icons.upload_outlined,
                      activeIcon: Icons.upload,
                      title: 'Upload',
                      route: '/upload',
                      onTap: () => _navigateToUpload(context),
                    ),
                    _buildNavItem(
                      icon: Icons.search_outlined,
                      activeIcon: Icons.search,
                      title: 'Recherche',
                      route: '/search',
                      onTap: () => _showSearchDialog(context),
                    ),
                  ]),
                  
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    _buildNavigationSection('ADMINISTRATION', [
                      _buildNavItem(
                        icon: Icons.admin_panel_settings_outlined,
                        activeIcon: Icons.admin_panel_settings,
                        title: 'Dashboard Admin',
                        route: '/admin-dashboard',
                        onTap: () => _navigateToAdminDashboard(context),
                      ),
                      _buildNavItem(
                        icon: Icons.business_outlined,
                        activeIcon: Icons.business,
                        title: 'Entreprise',
                        route: '/entreprise',
                        onTap: () => _navigateToEntreprise(context),
                      ),
                      _buildNavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        title: 'Paramètres',
                        route: '/settings',
                        onTap: () => _navigateToSettings(context),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
          
          // Footer
          _buildFooter(username, userRole ?? 'user'),
        ],
      ),
    );
  }

  Widget _buildHeader(String username) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ARKIVA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.archive_outlined,
                  color: ArkivaColors.primary,
                  size: widget.isCollapsed ? 24 : 28,
                ),
              ),
              
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARKIVA',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Gestion documentaire',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Toggle button
              if (widget.onToggle != null)
                IconButton(
                  onPressed: widget.onToggle,
                  icon: Icon(
                    widget.isCollapsed ? Icons.menu : Icons.menu_open,
                    color: Colors.white,
                  ),
                  tooltip: widget.isCollapsed ? 'Étendre' : 'Réduire',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection(String title, List<Widget> items) {
    if (widget.isCollapsed) {
      return Column(children: items);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String route,
    required VoidCallback onTap,
    int? badge,
  }) {
    final isActive = widget.currentRoute == route;
    final isHovered = _hoveredItem == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItem = route),
        onExit: (_) => setState(() => _hoveredItem = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive 
              ? Colors.white.withOpacity(0.15)
              : isHovered 
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive 
              ? Border.all(color: Colors.white.withOpacity(0.3))
              : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isActive ? activeIcon : icon,
                      color: Colors.white,
                      size: 22,
                    ),
                    
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      if (badge != null && badge > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ArkivaColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(String username, String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: widget.isCollapsed ? 16 : 20,
            backgroundColor: Colors.white,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: TextStyle(
                color: ArkivaColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: widget.isCollapsed ? 14 : 16,
              ),
            ),
          ),
          
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role == 'admin' ? 'Administrateur' : 'Utilisateur',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: ArkivaColors.primary),
                      const SizedBox(width: 12),
                      Text('Profil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: ArkivaColors.error),
                      const SizedBox(width: 12),
                      Text('Déconnexion'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  _logout(context);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToHome(BuildContext context) {
    if (widget.currentRoute != '/home') {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _navigateToArmoires(BuildContext context) {
    final authService = context.read<AuthStateService>();
    final entrepriseId = authService.entrepriseId;
    final userId = authService.userId;
    
    if (entrepriseId != null && userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArmoiresScreen(
            entrepriseId: entrepriseId,
            userId: int.parse(userId),
          ),
        ),
      );
    }
  }

  void _navigateToFavoris(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavorisScreen()),
    );
  }

  void _navigateToTags(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TagsScreen()),
    );
  }

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
  }

  void _navigateToUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadScreen()),
    );
  }

  void _navigateToAdminDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }

  void _navigateToEntreprise(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EntrepriseDetailScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recherche Globale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // TODO: Implement logout functionality
    // authService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}