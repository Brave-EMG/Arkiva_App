import 'package:flutter/material.dart';
import 'package:arkiva/screens/scan_screen.dart';
import 'package:arkiva/screens/upload_screen.dart';
import 'package:arkiva/screens/armoires_screen.dart';
import 'package:arkiva/screens/casiers_screen.dart';
import 'package:arkiva/screens/favoris_screen.dart';
import 'package:arkiva/models/armoire.dart';
import 'package:arkiva/services/animation_service.dart';
import 'package:arkiva/services/auth_state_service.dart';
import 'package:arkiva/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:arkiva/screens/entreprise_detail_screen.dart';
import 'package:arkiva/screens/create_user_screen.dart';
import 'package:arkiva/screens/admin_dashboard_screen.dart';
import 'package:arkiva/screens/settings_screen.dart';
import 'package:arkiva/screens/login_screen.dart';
import 'package:arkiva/services/document_service.dart';
import 'package:arkiva/screens/tags_screen.dart';
import 'package:arkiva/services/search_service.dart';
import 'package:arkiva/services/tag_service.dart';
import 'package:arkiva/screens/fichier_view_screen.dart';
import 'package:arkiva/widgets/main_layout.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _quickSearchController = TextEditingController();
  final TextEditingController _armoireController = TextEditingController();
  final TextEditingController _casierController = TextEditingController();
  final TextEditingController _dossierController = TextEditingController();
  final SearchService _searchService = SearchService();
  final TagService _tagService = TagService();
  bool _isSearching = false;
  List<dynamic> _quickResults = [];
  List<dynamic> _allTags = [];
  DateTimeRange? _selectedDateRange;
  Map<String, dynamic>? _selectedTag;

  // Dropdown dépendants
  List<dynamic> _allArmoires = [];
  List<dynamic> _allCasiers = [];
  List<dynamic> _allDossiers = [];
  String? _selectedArmoire;
  String? _selectedCasier;
  String? _selectedDossier;

  // Ajout des listes pour la sélection multiple
  List<String> _selectedArmoiresMulti = [];
  List<String> _selectedCasiersMulti = [];
  List<String> _selectedDossiersMulti = [];

  // Ajout des variables d'état pour les filtres principaux
  bool _filterArmoires = true;
  bool _filterCasiers = true;
  bool _filterDossiers = true;
  bool _filterFichiers = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadArmoires();
    _loadAllCasiers();
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    _armoireController.dispose();
    _casierController.dispose();
    _dossierController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final tags = await _tagService.getAllTags(token, entrepriseId);
        setState(() {
          _allTags = tags;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des tags: $e');
    }
  }

  Future<void> _loadArmoires() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/armoire/$entrepriseId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _allArmoires = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement armoires: $e');
    }
  }

  Future<void> _loadCasiers(String armoireId) async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/casier/$armoireId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _allCasiers = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement casiers: $e');
    }
  }

  Future<void> _loadDossiers(String casierId) async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/dosier/$casierId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _allDossiers = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement dossiers: $e');
    }
  }

  Future<void> _loadAllCasiers() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      final entrepriseId = authState.entrepriseId;
      if (token != null && entrepriseId != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/casier/getcasiers'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _allCasiers = data;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement tous les casiers: $e');
    }
  }

  Future<void> _performQuickSearch() async {
    setState(() { _isSearching = true; });
    final authState = context.read<AuthStateService>();
    final token = authState.token;
    final entrepriseId = authState.entrepriseId;
    if (token == null || entrepriseId == null) return;
    try {
      List<dynamic> results = [];
      // Déterminer les filtres cochés dans l'ordre
      final List<String> filtres = [];
      if (_filterArmoires) filtres.add('armoire');
      if (_filterCasiers) filtres.add('casier');
      if (_filterDossiers) filtres.add('dossier');
      if (_filterFichiers) filtres.add('nom');
      final input = _quickSearchController.text.trim();
      final parts = input.split(RegExp(r'[ ,;]+'));
      if (parts.length < filtres.length) {
        setState(() { _isSearching = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci de saisir un nom pour chaque filtre sélectionné.')),
        );
        return;
      }
      // Gestion de la sélection multiple
      Set<dynamic> allResults = {};
      if (_selectedArmoiresMulti.isNotEmpty || _selectedCasiersMulti.isNotEmpty || _selectedDossiersMulti.isNotEmpty) {
        // Pour chaque combinaison sélectionnée, faire une requête
        for (var armoireNom in _selectedArmoiresMulti.isNotEmpty ? _selectedArmoiresMulti : [null]) {
          for (var casierNom in _selectedCasiersMulti.isNotEmpty ? _selectedCasiersMulti : [null]) {
            for (var dossierNom in _selectedDossiersMulti.isNotEmpty ? _selectedDossiersMulti : [null]) {
              final res = await _searchService.searchFlexible(
                token,
                entrepriseId,
                armoire: armoireNom,
                casier: casierNom,
                dossier: dossierNom,
                nom: filtres.contains('nom') ? parts[filtres.indexOf('nom')] : null,
              );
              allResults.addAll(res);
            }
          }
        }
        results = allResults.toList();
      } else {
        // Cas classique : un seul filtre par champ
        Map<String, String?> params = {};
        for (int i = 0; i < filtres.length; i++) {
          params[filtres[i]] = parts[i];
        }
        params['entreprise_id'] = entrepriseId.toString();
        results = await _searchService.searchFlexible(
          token,
          entrepriseId,
          armoire: params['armoire'],
          casier: params['casier'],
          dossier: params['dossier'],
          nom: params['nom'],
        );
      }
      setState(() {
        _quickResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() { _isSearching = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la recherche : $e')),
      );
    }
  }

  Widget _buildQuickResultsList() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_quickResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Aucun document trouvé', style: TextStyle(fontSize: 16))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _quickResults.length,
      itemBuilder: (context, index) {
        final doc = _quickResults[index];
        final nomAffiche = doc['originalfilename'] ?? doc['nom'] ?? 'Document';
        final cheminAffiche = doc['chemin'] ??
          [doc['armoire_nom'] ?? doc['armoire'], doc['casier_nom'] ?? doc['casier'], doc['dossier_nom'] ?? doc['dossier']]
            .where((e) => e != null && e.toString().isNotEmpty).join(' > ');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(nomAffiche),
            subtitle: Text(cheminAffiche),
            onTap: () {
    Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FichierViewScreen(doc: doc),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showQuickResultsDialog() {
    final entrepriseId = context.read<AuthStateService>().entrepriseId;
    final token = context.read<AuthStateService>().token;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résultats pour "${_quickSearchController.text}"'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: _quickResults.isEmpty
              ? const Text('Aucun document trouvé')
              : ListView.builder(
                  itemCount: _quickResults.length,
                  itemBuilder: (context, index) {
                    final doc = _quickResults[index];
                    final nomAffiche = doc['originalfilename'] ?? doc['nom'] ?? 'Document';
                    final armoire = doc['armoire'] ?? '';
                    final casier = doc['casier'] ?? '';
                    final dossier = doc['dossier'] ?? '';
                    final cheminAffiche = [armoire, casier, dossier].where((e) => e != null && e.toString().isNotEmpty).join(' > ');
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(nomAffiche),
                      subtitle: Text(cheminAffiche),
                      onTap: () {
                        Navigator.pop(context); // Fermer le dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FichierViewScreen(doc: doc),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) => Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 420,
                minWidth: 320,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtres multi-sélection',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blueGrey)),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Section Rechercher par
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rechercher par :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterArmoires,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterArmoires = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Armoires'),
                            Checkbox(
                              value: _filterCasiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterCasiers = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Casiers'),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterDossiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterDossiers = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Dossiers'),
                            Checkbox(
                              value: _filterFichiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterFichiers = v!;
                                  _updateTousSB();
                                });
                              },
                            ),
                            const Text('Fichiers'),
                          ],
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _filterArmoires && _filterCasiers && _filterDossiers && _filterFichiers,
                              onChanged: (v) {
                                setStateSB(() {
                                  _filterArmoires = v!;
                                  _filterCasiers = v;
                                  _filterDossiers = v;
                                  _filterFichiers = v;
                                });
                              },
                            ),
                            const Text('Tous', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quickSearchController,
                    decoration: InputDecoration(
                      labelText: 'Nom du fichier ou mot-clé',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_filterArmoires) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Armoires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedArmoiresMulti.length == _allArmoires.length && _allArmoires.isNotEmpty,
                                      onChanged: (v) {
                                        setStateSB(() {
                                          if (v == true) {
                                            _selectedArmoiresMulti = _allArmoires.map<String>((a) => a['nom']).toList();
                                          } else {
                                            _selectedArmoiresMulti.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue[700],
                                    ),
                                    Text('Tous', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            ..._allArmoires.map<Widget>((armoire) => CheckboxListTile(
                              value: _selectedArmoiresMulti.contains(armoire['nom']),
                              onChanged: (v) {
                                setStateSB(() {
                                  if (v == true) {
                                    _selectedArmoiresMulti.add(armoire['nom']);
                                  } else {
                                    _selectedArmoiresMulti.remove(armoire['nom']);
                                  }
                                });
                              },
                              title: Text(armoire['nom']),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[700],
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                            const SizedBox(height: 14),
                          ],
                          if (_filterCasiers) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Casiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedCasiersMulti.length == _allCasiers.length && _allCasiers.isNotEmpty,
                                      onChanged: (v) {
                                        setStateSB(() {
                                          if (v == true) {
                                            _selectedCasiersMulti = _allCasiers.map<String>((c) => c['cassier_id'].toString()).toList();
                                          } else {
                                            _selectedCasiersMulti.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue[700],
                                    ),
                                    Text('Tous', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            ..._allCasiers.map<Widget>((casier) => CheckboxListTile(
                              value: _selectedCasiersMulti.contains(casier['cassier_id'].toString()),
                              onChanged: (v) {
                                setStateSB(() {
                                  if (v == true) {
                                    _selectedCasiersMulti.add(casier['cassier_id'].toString());
                                  } else {
                                    _selectedCasiersMulti.remove(casier['cassier_id'].toString());
                                  }
                                });
                              },
                              title: Text(casier['nom']),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[700],
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                            const SizedBox(height: 14),
                          ],
                          if (_filterDossiers) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Dossiers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue[900])),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedDossiersMulti.length == _allDossiers.length && _allDossiers.isNotEmpty,
                                      onChanged: (v) {
                                        setStateSB(() {
                                          if (v == true) {
                                            _selectedDossiersMulti = _allDossiers.map<String>((d) => d['dossier_id'].toString()).toList();
                                          } else {
                                            _selectedDossiersMulti.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue[700],
                                    ),
                                    Text('Tous', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                            ..._allDossiers.map<Widget>((dossier) => CheckboxListTile(
                              value: _selectedDossiersMulti.contains(dossier['dossier_id'].toString()),
                              onChanged: (v) {
                                setStateSB(() {
                                  if (v == true) {
                                    _selectedDossiersMulti.add(dossier['dossier_id'].toString());
                                  } else {
                                    _selectedDossiersMulti.remove(dossier['dossier_id'].toString());
                                  }
                                });
                              },
                              title: Text(dossier['nom']),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.blue[700],
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            )),
                            const SizedBox(height: 14),
                          ],
                          // Fichiers : rien à afficher, c'est juste le champ texte
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _performQuickSearch();
                            setState(() {});
                          },
                          icon: Icon(Icons.check),
                          label: Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            minimumSize: Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setStateSB(() {
                            _selectedArmoiresMulti.clear();
                            _selectedCasiersMulti.clear();
                            _selectedDossiersMulti.clear();
                            _quickSearchController.clear();
                            _filterArmoires = true;
                            _filterCasiers = true;
                            _filterDossiers = true;
                            _filterFichiers = true;
                          });
                        },
                        child: Text('Réinitialiser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.blueGrey,
                          minimumSize: Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Fonction utilitaire pour gérer la logique de la case Tous
  void _updateTousSB() {
    // Cette fonction est appelée à chaque changement d'une case individuelle
    // Elle met à jour la case "Tous" automatiquement si besoin
    // (rien à faire ici car la case "Tous" dépend directement des autres)
  }

  Color _parseTagColor(String? colorString) {
    if (colorString == null) return Colors.grey;
    try {
      if (colorString.startsWith('#') && (colorString.length == 7)) {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      }
    } catch (_) {}
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final authStateService = context.watch<AuthStateService>();
    final username = authStateService.username ?? 'Utilisateur';
    final userRole = authStateService.role;
    final token = authStateService.token;

    return MainLayout(
      currentRoute: '/home',
      title: 'Dashboard - Bonjour $username 👋',
        actions: [
          IconButton(
            onPressed: () {
            // TODO: Afficher les notifications
          },
          icon: Stack(
          children: [
              Icon(Icons.notifications_outlined),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ArkivaColors.accent,
                    shape: BoxShape.circle,
                  ),
                      ),
                    ),
                ],
              ),
          tooltip: 'Notifications',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Bienvenue moderne
            _buildWelcomeSection(username),
            const SizedBox(height: 32),
            
            // Section des actions rapides
            _buildQuickActions(context),
            const SizedBox(height: 32),
            
            // Section admin si applicable
            if (userRole == 'admin') ...[
              _buildAdminSection(context),
              const SizedBox(height: 32),
            ],
            
            // Section activité récente
            _buildRecentActivity(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherche Rapide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _quickSearchController,
                    decoration: InputDecoration(
                      hintText: 'Nom du fichier ou mot-clé',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (text) => _performQuickSearch(),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showMultiSelectFilters,
                        icon: Icon(Icons.filter_list),
                        label: Text('Filtrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          foregroundColor: Colors.blue[900],
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _performQuickSearch,
                        icon: Icon(Icons.search),
                        label: Text('Rechercher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Affichage des résultats sous la barre de recherche
                  _buildQuickResultsList(),
                ],
              ),
            ),

            SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accès Rapide',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),

                  Column(
                    children: [
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.star, size: 28, color: Colors.amber[700]),
                          title: Text('Documents favoris', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            _navigateToScreen(context, const FavorisScreen());
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.history, size: 28, color: Colors.blue[700]),
                          title: Text('Documents récemment consultés', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            print('Tapped on Documents récemment consultés');
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.recent_actors, size: 28, color: Colors.green[700]),
                          title: Text('Derniers documents', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            print('Tapped on Derniers documents');
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.backup, size: 28, color: Colors.orange[700]),
                          title: Text('Sauvegardes', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            Navigator.pushNamed(context, '/backups');
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.history, size: 28, color: Colors.purple[700]),
                          title: Text('Versions', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            Navigator.pushNamed(context, '/versions');
                          },
                        ),
                      ),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: Icon(Icons.restore, size: 28, color: Colors.teal[700]),
                          title: Text('Restaurations', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.grey[600]),
                          onTap: () {
                            Navigator.pushNamed(context, '/restorations');
                          },
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
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _showCreateArmoireDialog(BuildContext context) async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle armoire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'armoire',
                hintText: 'Ex: Armoire personnelle',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (facultatif)',
                hintText: 'Ex: Documents importants',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'nom': nomController.text,
                  'description': descriptionController.text,
                });
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null) {
      print('Nouvelle armoire à créer: Nom - ${result['nom']}, Description - ${result['description']}');
    }
  }



  // Méthodes helper pour les sections modernisées
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: ArkivaColors.neutral800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.camera_alt_outlined,
                title: 'Scanner',
                subtitle: 'Numériser documents',
                color: ArkivaColors.secondary,
                onTap: () => _navigateToScreen(context, const ScanScreen()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.cloud_upload_outlined,
                title: 'Upload',
                subtitle: 'Télécharger fichiers',
                color: ArkivaColors.accent,
                onTap: () => _navigateToScreen(context, const UploadScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.search_outlined,
                title: 'Rechercher',
                subtitle: 'Trouver documents',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  // TODO: Ouvrir recherche globale
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.folder_outlined,
                title: 'Armoires',
                subtitle: 'Explorer dossiers',
                color: ArkivaColors.primary,
                onTap: () {
                  final authStateService = context.read<AuthStateService>();
                  final entrepriseId = authStateService.entrepriseId;
                  final userId = authStateService.userId;
                  
                  if (entrepriseId != null && userId != null) {
                    _navigateToScreen(
                      context,
                      ArmoiresScreen(
                        entrepriseId: entrepriseId,
                        userId: int.parse(userId),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
        onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: ArkivaColors.neutral800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ArkivaColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AuthStateService authStateService, String? token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: ArkivaColors.neutral800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Armoires',
                value: '${authStateService.armoireCount ?? 0}',
                icon: Icons.folder_outlined,
                color: ArkivaColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Casiers',
                value: '${authStateService.casierCount ?? 0}',
                icon: Icons.storage_outlined,
                color: ArkivaColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<int>(
          future: token != null ? DocumentService().fetchDocumentsCount(token) : Future.value(0),
          builder: (context, snapshot) {
            final docCount = snapshot.data ?? 0;
            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Documents',
                    value: '$docCount',
                    icon: Icons.description_outlined,
                    color: ArkivaColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Favoris',
                    value: '12', // TODO: Récupérer le vrai nombre
                    icon: Icons.star_outline,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ArkivaColors.neutral800,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ArkivaColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    final authStateService = context.watch<AuthStateService>();
    final token = authStateService.token;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ArkivaColors.primaryLight.withOpacity(0.1),
            ArkivaColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ArkivaColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête Dashboard
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ArkivaColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Administrateur',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: ArkivaColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Vue d\'ensemble et gestion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ArkivaColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Métriques principales
          _buildDashboardMetrics(context, authStateService, token),
          const SizedBox(height: 20),
          
          // Indicateurs de performance
          _buildPerformanceIndicators(context),
          const SizedBox(height: 20),
          
          // Actions rapides admin
          _buildAdminQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildDashboardMetrics(BuildContext context, AuthStateService authStateService, String? token) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métriques Principales',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ArkivaColors.neutral800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Armoires',
                value: '${authStateService.armoireCount ?? 0}',
                icon: Icons.folder_outlined,
                color: ArkivaColors.primary,
                trend: '+12%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'Casiers',
                value: '${authStateService.casierCount ?? 0}',
                icon: Icons.storage_outlined,
                color: ArkivaColors.secondary,
                trend: '+8%',
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<int>(
          future: token != null ? DocumentService().fetchDocumentsCount(token) : Future.value(0),
          builder: (context, snapshot) {
            final docCount = snapshot.data ?? 0;
            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Documents',
                    value: '$docCount',
                    icon: Icons.description_outlined,
                    color: ArkivaColors.accent,
                    trend: '+25%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    title: 'Utilisateurs',
                    value: '5', // TODO: Récupérer le vrai nombre
                    icon: Icons.people_outline,
                    color: ArkivaColors.success,
                    trend: '+3',
                    isPositive: true,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? ArkivaColors.success.withOpacity(0.1) : ArkivaColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? ArkivaColors.success : ArkivaColors.error,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPositive ? ArkivaColors.success : ArkivaColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ArkivaColors.neutral800,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ArkivaColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs de Performance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ArkivaColors.neutral800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            children: [
              _buildProgressIndicator(
                context,
                label: 'Espace de stockage',
                value: 0.75,
                color: ArkivaColors.primary,
                details: '750 GB / 1 TB utilisés',
              ),
              const SizedBox(height: 16),
              _buildProgressIndicator(
                context,
                label: 'Activité mensuelle',
                value: 0.60,
                color: ArkivaColors.secondary,
                details: '1,245 documents ajoutés ce mois',
              ),
              const SizedBox(height: 16),
              _buildProgressIndicator(
                context,
                label: 'Taux de numérisation',
                value: 0.85,
                color: ArkivaColors.accent,
                details: '85% des documents numérisés',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
    required String details,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArkivaColors.neutral800,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          backgroundColor: ArkivaColors.neutral200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
            Text(
          details,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ArkivaColors.neutral500,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: ArkivaColors.neutral800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                title: 'Gestion Entreprise',
                icon: Icons.business_outlined,
                color: ArkivaColors.primary,
                onPressed: () {
                  _navigateToScreen(context, const EntrepriseDetailScreen());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                title: 'Dashboard Complet',
                icon: Icons.analytics_outlined,
                color: ArkivaColors.secondary,
                onPressed: () {
                  _navigateToScreen(context, const AdminDashboardScreen());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                title: 'Créer Utilisateur',
                icon: Icons.person_add_outlined,
                color: ArkivaColors.accent,
                onPressed: () {
                  _navigateToScreen(context, const SettingsScreen());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                title: 'Sauvegardes',
                icon: Icons.backup_outlined,
                color: ArkivaColors.warning,
                onPressed: () {
                  // TODO: Naviguer vers les sauvegardes
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
              title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String username) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArkivaColors.primary,
            ArkivaColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ArkivaColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, $username ! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez vos documents efficacement avec ARKIVA',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickStat(
                      icon: Icons.folder_outlined,
                      label: 'Armoires',
                      value: '12',
                    ),
                    const SizedBox(width: 24),
                    _buildQuickStat(
                      icon: Icons.description_outlined,
                      label: 'Documents',
                      value: '1.2k',
                    ),
                    const SizedBox(width: 24),
                    _buildQuickStat(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Aujourd\'hui',
                      value: '+15',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.rocket_launch_outlined,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité Récente',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ArkivaColors.neutral800,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                icon: Icons.upload_file,
                color: ArkivaColors.success,
                title: 'Document "Facture_2024.pdf" uploadé',
                subtitle: 'Il y a 2 heures',
              ),
              Divider(height: 1, color: ArkivaColors.neutral200),
              _buildActivityItem(
                icon: Icons.scanner,
                color: ArkivaColors.secondary,
                title: 'Nouveau scan ajouté à "Armoire Comptabilité"',
                subtitle: 'Il y a 4 heures',
              ),
              Divider(height: 1, color: ArkivaColors.neutral200),
              _buildActivityItem(
                icon: Icons.folder_open,
                color: ArkivaColors.primary,
                title: 'Dossier "Contrats 2024" créé',
                subtitle: 'Hier',
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {
                    // TODO: Voir toute l'activité
                  },
                  child: Text('Voir toute l\'activité'),
                  style: TextButton.styleFrom(
                    foregroundColor: ArkivaColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ArkivaColors.neutral800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArkivaColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 