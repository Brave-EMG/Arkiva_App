import 'package:flutter/material.dart';
import 'package:arkiva/widgets/app_sidebar.dart';
import 'package:arkiva/services/theme_service.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAppBar;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ArkivaColors.neutral50,
      body: Row(
        children: [
          // Sidebar fixe
          Container(
            width: _isSidebarCollapsed ? 80 : 280,
            child: AppSidebar(
              currentRoute: widget.currentRoute,
              isCollapsed: _isSidebarCollapsed,
              onToggle: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                if (widget.showAppBar) _buildAppBar(),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ArkivaColors.neutral50,
      appBar: widget.showAppBar ? _buildAppBar() : null,
      drawer: SizedBox(
        width: 280,
        child: AppSidebar(
          currentRoute: widget.currentRoute,
          isCollapsed: false,
        ),
      ),
      body: widget.child,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ArkivaColors.neutral50,
      appBar: widget.showAppBar ? _buildAppBar() : null,
      drawer: SizedBox(
        width: 280,
        child: AppSidebar(
          currentRoute: widget.currentRoute,
          isCollapsed: false,
        ),
      ),
      body: widget.child,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: ArkivaColors.neutral800,
      title: widget.title != null
          ? Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ArkivaColors.neutral800,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: widget.actions,
      leading: MediaQuery.of(context).size.width <= 1024
          ? IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: ArkivaColors.neutral200,
        ),
      ),
    );
  }
}