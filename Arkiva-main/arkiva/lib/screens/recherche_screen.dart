import 'package:flutter/material.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/responsive_service.dart';
import 'package:provider/provider.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  // Filtres avancés
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;
  String? _selectedTag;
  DateTimeRange? _selectedDateRange;

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    try {
      List<dynamic> results = [];
      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        // Recherche par tag
        results = await _searchService.getFilesByTag(token, int.parse(_selectedTag!), entrepriseId);
      } else if (_selectedDateRange != null) {
        // Recherche par date
        final debut = _selectedDateRange!.start.toIso8601String().substring(0, 10);
        final fin = _selectedDateRange!.end.toIso8601String().substring(0, 10);
        results = await _searchService.searchByDate(token, debut, fin, entrepriseId);
      } else if (_selectedArmoire != null || _selectedCasier != null || _selectedDossier != null || _searchController.text.isNotEmpty) {
        // Recherche flexible
        results = await _searchService.searchFlexible(
          token,
          entrepriseId,
          armoire: _selectedArmoire,
          casier: _selectedCasier,
          dossier: _selectedDossier,
          nom: _searchController.text.isNotEmpty ? _searchController.text : null,
        );
      } else if (_searchController.text.isNotEmpty) {
        // Recherche OCR/nom
        results = await _searchService.searchByOcr(token, _searchController.text, entrepriseId);
      }
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Widget _buildMobileSearch() {
    return Column(
      children: [
        // Barre de recherche
        ResponsiveService.responsiveCard(
          context: context,
          child: Column(
            children: [
              ResponsiveService.responsiveTextField(
                context: context,
                controller: _searchController,
                labelText: 'Rechercher un document...',
                hintText: 'Nom, contenu, tag...',
                prefixIcon: Icon(Icons.search, size: ResponsiveService.getIconSize(context)),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, size: ResponsiveService.getIconSize(context)),
                  onPressed: _openFilters,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _performSearch();
                  }
                },
              ),
              SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
              ResponsiveService.responsiveButton(
                context: context,
                onPressed: _isLoading ? null : _performSearch,
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: ResponsiveService.getIconSize(context),
                        height: ResponsiveService.getIconSize(context),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Icon(Icons.search, size: ResponsiveService.getIconSize(context)),
                    SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                    Text(
                      _isLoading ? 'Recherche...' : 'Rechercher',
                      style: TextStyle(
                        fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
        // Résultats
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildTabletSearch() {
    return Row(
      children: [
        // Panneau de recherche
        Expanded(
          flex: 1,
          child: ResponsiveService.responsiveCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recherche avancée',
                  style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: _searchController,
                  labelText: 'Rechercher un document...',
                  hintText: 'Nom, contenu, tag...',
                  prefixIcon: Icon(Icons.search, size: ResponsiveService.getIconSize(context)),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _performSearch();
                    }
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                
                // Filtres rapides
                Text(
                  'Filtres rapides',
                  style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedArmoire ?? ''),
                  labelText: 'Armoire',
                  onChanged: (value) {
                    setState(() {
                      _selectedArmoire = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedCasier ?? ''),
                  labelText: 'Casier',
                  onChanged: (value) {
                    setState(() {
                      _selectedCasier = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                
                ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: _isLoading ? null : _performSearch,
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: ResponsiveService.getIconSize(context),
                          height: ResponsiveService.getIconSize(context),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(Icons.search, size: ResponsiveService.getIconSize(context)),
                      SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                      Text(
                        _isLoading ? 'Recherche...' : 'Rechercher',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 16)),
        // Résultats
        Expanded(
          flex: 2,
          child: _buildResults(),
        ),
      ],
    );
  }

  Widget _buildDesktopSearch() {
    return Row(
      children: [
        // Panneau de recherche
        Expanded(
          flex: 1,
          child: ResponsiveService.responsiveCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recherche avancée',
                  style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: _searchController,
                  labelText: 'Rechercher un document...',
                  hintText: 'Nom, contenu, tag...',
                  prefixIcon: Icon(Icons.search, size: ResponsiveService.getIconSize(context)),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _performSearch();
                    }
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                
                // Filtres avancés
                Text(
                  'Filtres avancés',
                  style: TextStyle(
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedArmoire ?? ''),
                  labelText: 'Armoire',
                  onChanged: (value) {
                    setState(() {
                      _selectedArmoire = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedCasier ?? ''),
                  labelText: 'Casier',
                  onChanged: (value) {
                    setState(() {
                      _selectedCasier = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedDossier ?? ''),
                  labelText: 'Dossier',
                  onChanged: (value) {
                    setState(() {
                      _selectedDossier = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedTag ?? ''),
                  labelText: 'Tag (ID)',
                  onChanged: (value) {
                    setState(() {
                      _selectedTag = value.isEmpty ? null : value;
                    });
                  },
                ),
                
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 24)),
                
                ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: _isLoading ? null : _performSearch,
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: ResponsiveService.getIconSize(context),
                          height: ResponsiveService.getIconSize(context),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(Icons.search, size: ResponsiveService.getIconSize(context)),
                      SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                      Text(
                        _isLoading ? 'Recherche...' : 'Rechercher',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 24)),
        // Résultats
        Expanded(
          flex: 2,
          child: _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
            Text(
              'Recherche en cours...',
              style: TextStyle(
                fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: ResponsiveService.responsiveCard(
          context: context,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: ResponsiveService.getIconSize(context) * 3,
                color: Colors.grey[400],
              ),
              SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
              Text(
                'Aucun résultat trouvé',
                style: TextStyle(
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 8)),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ResponsiveService.responsiveBuilder(
      context: context,
      mobile: ListView.builder(
        padding: ResponsiveService.getScreenPadding(context),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return ResponsiveService.responsiveCard(
            context: context,
            child: ListTile(
              leading: Icon(
                Icons.description,
                size: ResponsiveService.getIconSize(context),
                color: Colors.blue[600],
              ),
              title: Text(
                result['nom'] ?? 'Document sans nom',
                style: TextStyle(
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                result['description'] ?? 'Aucune description',
                style: TextStyle(
                  fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                  color: Colors.grey[600],
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.open_in_new,
                  size: ResponsiveService.getIconSize(context),
                ),
                onPressed: () {
                  // TODO: Ouvrir le document
                },
              ),
            ),
          );
        },
      ),
      tablet: GridView.builder(
        padding: ResponsiveService.getScreenPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2,
          crossAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 16),
          mainAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 16),
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return ResponsiveService.responsiveCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: ResponsiveService.getIconSize(context),
                      color: Colors.blue[600],
                    ),
                    SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                    Expanded(
                      child: Text(
                        result['nom'] ?? 'Document sans nom',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.open_in_new,
                        size: ResponsiveService.getIconSize(context),
                      ),
                      onPressed: () {
                        // TODO: Ouvrir le document
                      },
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                Expanded(
                  child: Text(
                    result['description'] ?? 'Aucune description',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      desktop: GridView.builder(
        padding: ResponsiveService.getScreenPadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.5,
          crossAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 20),
          mainAxisSpacing: ResponsiveService.getSpacing(context, baseSpacing: 20),
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return ResponsiveService.responsiveCard(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: ResponsiveService.getIconSize(context),
                      color: Colors.blue[600],
                    ),
                    SizedBox(width: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                    Expanded(
                      child: Text(
                        result['nom'] ?? 'Document sans nom',
                        style: TextStyle(
                          fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.open_in_new,
                        size: ResponsiveService.getIconSize(context),
                      ),
                      onPressed: () {
                        // TODO: Ouvrir le document
                      },
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 8)),
                Expanded(
                  child: Text(
                    result['description'] ?? 'Aucune description',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                      color: Colors.grey[600],
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setStateSB) => Padding(
            padding: ResponsiveService.getScreenPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filtres avancés',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                  ),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedArmoire ?? ''),
                  labelText: 'Armoire',
                  onChanged: (v) => setStateSB(() => _selectedArmoire = v.isEmpty ? null : v),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedCasier ?? ''),
                  labelText: 'Casier',
                  onChanged: (v) => setStateSB(() => _selectedCasier = v.isEmpty ? null : v),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedDossier ?? ''),
                  labelText: 'Dossier',
                  onChanged: (v) => setStateSB(() => _selectedDossier = v.isEmpty ? null : v),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 12)),
                ResponsiveService.responsiveTextField(
                  context: context,
                  controller: TextEditingController(text: _selectedTag ?? ''),
                  labelText: 'Tag (ID)',
                  onChanged: (v) => setStateSB(() => _selectedTag = v.isEmpty ? null : v),
                ),
                SizedBox(height: ResponsiveService.getSpacing(context, baseSpacing: 16)),
                ResponsiveService.responsiveButton(
                  context: context,
                  onPressed: () {
                    Navigator.pop(context);
                    _performSearch();
                  },
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  child: Text(
                    'Appliquer les filtres',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recherche',
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
          mobile: Padding(
            padding: ResponsiveService.getScreenPadding(context),
            child: _buildMobileSearch(),
          ),
          tablet: Padding(
            padding: ResponsiveService.getScreenPadding(context),
            child: _buildTabletSearch(),
          ),
          desktop: Padding(
            padding: ResponsiveService.getScreenPadding(context),
            child: _buildDesktopSearch(),
          ),
        ),
      ),
    );
  }
} 