import 'package:flutter/material.dart';
import '../models/armoire.dart';
import '../services/armoire_service.dart';
import 'casiers_screen.dart';
import '../services/auth_state_service.dart';
import '../services/responsive_service.dart';
import 'package:provider/provider.dart';
import '../services/casier_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:arkiva/config/api_config.dart';

class ArmoiresScreen extends StatefulWidget {
  final int entrepriseId;
  final int userId;

  const ArmoiresScreen({
    Key? key,
    required this.entrepriseId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ArmoiresScreen> createState() => _ArmoiresScreenState();
}

class _ArmoiresScreenState extends State<ArmoiresScreen> {
  final ArmoireService _armoireService = ArmoireService();
  List<Armoire> _armoires = [];
  bool _isLoading = true;
  String? _error;
  bool _abonnementActif = true;
  bool _abonnementCharge = false;

  @override
  void initState() {
    super.initState();
    _checkAbonnement();
    _loadArmoires();
  }

  // Widgets helpers pour un design moderne
  Widget _buildModernCard({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: padding ?? EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: color != null ? LinearGradient(
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : LinearGradient(
              colors: [
                Colors.white,
                Colors.grey.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildArmoireCard(Armoire armoire) {
    return ResponsiveService.responsiveCard(
      context: context,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CasiersScreen(
                armoireId: armoire.armoireId,
                armoireNom: armoire.nom,
                entrepriseId: widget.entrepriseId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(ResponsiveService.getBorderRadius(context)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveService.getCardPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveService.getPadding(context) * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Colors.blue[700],
                      size: ResponsiveService.getIconSize(context),
                    ),
                  ),
                  SizedBox(width: ResponsiveService.getPadding(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          armoire.nom,
                          style: TextStyle(
                            fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (armoire.description != null && armoire.description!.isNotEmpty)
                          Text(
                            armoire.description!,
                            style: TextStyle(
                              fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveService.getPadding(context)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Créée le ${_formatDate(armoire.dateCreation)}',
                    style: TextStyle(
                      fontSize: ResponsiveService.getFontSize(context, baseSize: 10),
                      color: Colors.grey[500],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: ResponsiveService.getIconSize(context) * 0.8,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAbonnement() async {
    try {
      final authState = context.read<AuthStateService>();
      final token = authState.token;
      if (token != null) {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/payments/current-subscription'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _abonnementActif = data['subscription']?['isActive'] ?? false;
            _abonnementCharge = true;
          });
        } else {
          setState(() {
            _abonnementActif = false;
            _abonnementCharge = true;
          });
        }
      } else {
        setState(() {
          _abonnementActif = false;
          _abonnementCharge = true;
        });
      }
    } catch (e) {
      setState(() {
        _abonnementActif = false;
        _abonnementCharge = true;
      });
    }
  }

  Future<void> _loadArmoires() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final armoires = await _armoireService.getAllArmoires(widget.entrepriseId);
      setState(() {
        _armoires = armoires;
      });

      // Mettre à jour le compteur d'armoires dans AuthStateService
      context.read<AuthStateService>().setArmoireCount(armoires.length);

      // Calculer et mettre à jour le nombre total de casiers
      int totalCasiers = 0;
      final casierService = CasierService(); // Créer une instance du service Casier
      for (final armoire in armoires) {
        // Pour chaque armoire, récupérer ses casiers
        final casiers = await casierService.getCasiersByArmoire(armoire.armoireId);
        totalCasiers += casiers.length;
      }

      // Mettre à jour le compteur de casiers dans AuthStateService
      context.read<AuthStateService>().setCasierCount(totalCasiers);

      setState(() {
        _isLoading = false; // Fin du chargement après avoir tout récupéré
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createArmoire() async {
    try {
      await _armoireService.createArmoire(widget.userId, widget.entrepriseId);
      await _loadArmoires();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création: $e')),
      );
    }
  }

  Future<void> _renameArmoire(Armoire armoire) async {
    final TextEditingController controller = TextEditingController(text: armoire.sousTitre);
    
    final String? newSousTitre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Renommer l\'armoire'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Sous-titre',
            hintText: 'Entrez un sous-titre pour l\'armoire',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.warehouse, color: Colors.purple[600]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Renommer'),
          ),
        ],
      ),
    );

    if (newSousTitre != null && newSousTitre != armoire.sousTitre) {
      try {
        await _armoireService.renameArmoire(armoire.armoireId, newSousTitre);
        await _loadArmoires();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du renommage: $e')),
        );
      }
    }
  }

  Future<void> _deleteArmoire(Armoire armoire) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Supprimer l\'armoire'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer ${armoire.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _armoireService.deleteArmoire(armoire.armoireId);
        await _loadArmoires();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  Widget _buildSubscriptionWarning() {
    return _buildModernCard(
      color: Colors.red[50],
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Vous ne pouvez pas accéder à vos armoires car votre abonnement n'est pas actif.",
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: _buildModernCard(
        color: Colors.purple[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warehouse,
              size: 64,
              color: Colors.purple[400],
            ),
            SizedBox(height: 16),
            Text(
              'Aucune armoire disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez votre première armoire pour commencer',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: _buildModernCard(
        color: Colors.red[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Erreur lors du chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadArmoires,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateArmoireDialog() {
    final TextEditingController controller = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_box, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Créer une nouvelle armoire'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'armoire',
                  hintText: 'Entrez le nom de l\'armoire',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.warehouse, color: Colors.blue[600]),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  hintText: 'Ajoutez une description pour l\'armoire',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.description, color: Colors.blue[600]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final String nom = controller.text.trim();
              final String? description = descriptionController.text.trim();

              if (nom.isNotEmpty) {
                _createArmoire();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Le nom de l\'armoire est requis.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Armoires',
          style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 20)),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateArmoireDialog,
            icon: Icon(
              Icons.add,
              size: ResponsiveService.getIconSize(context),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête avec statistiques
              Container(
                padding: EdgeInsets.all(ResponsiveService.getScreenPadding(context).horizontal),
                child: ResponsiveService.responsiveCard(
                  context: context,
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: ResponsiveService.getIconSize(context) * 1.5,
                        color: Colors.blue[700],
                      ),
                      SizedBox(width: ResponsiveService.getPadding(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_armoires.length} Armoire${_armoires.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: ResponsiveService.getFontSize(context, baseSize: 18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Organisez vos documents',
                              style: TextStyle(
                                fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: ResponsiveService.getPadding(context)),
              
              // Liste des armoires
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.blue[700],
                            ),
                            SizedBox(height: ResponsiveService.getPadding(context)),
                            Text(
                              'Chargement des armoires...',
                              style: TextStyle(
                                fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: ResponsiveService.getIconSize(context) * 2,
                                  color: Colors.red[300],
                                ),
                                SizedBox(height: ResponsiveService.getPadding(context)),
                                Text(
                                  'Erreur: $_error',
                                  style: TextStyle(
                                    fontSize: ResponsiveService.getFontSize(context, baseSize: 14),
                                    color: Colors.red[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: ResponsiveService.getPadding(context)),
                                ResponsiveService.responsiveButton(
                                  context: context,
                                  onPressed: _loadArmoires,
                                  child: Text(
                                    'Réessayer',
                                    style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _armoires.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: ResponsiveService.getIconSize(context) * 3,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: ResponsiveService.getPadding(context)),
                                    Text(
                                      'Aucune armoire trouvée',
                                      style: TextStyle(
                                        fontSize: ResponsiveService.getFontSize(context, baseSize: 16),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveService.getPadding(context) * 0.5),
                                    Text(
                                      'Créez votre première armoire pour commencer',
                                      style: TextStyle(
                                        fontSize: ResponsiveService.getFontSize(context, baseSize: 12),
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: ResponsiveService.getPadding(context)),
                                    ResponsiveService.responsiveButton(
                                      context: context,
                                      onPressed: _showCreateArmoireDialog,
                                      child: Text(
                                        'Créer une armoire',
                                        style: TextStyle(fontSize: ResponsiveService.getFontSize(context, baseSize: 14)),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: ResponsiveService.getHorizontalPadding(context),
                                child: ResponsiveService.responsiveGrid(
                                  context: context,
                                  children: _armoires.map((armoire) => _buildArmoireCard(armoire)).toList(),
                                  mobileCrossAxisCount: 1,
                                  tabletCrossAxisCount: 2,
                                  desktopCrossAxisCount: 3,
                                  crossAxisSpacing: ResponsiveService.getPadding(context),
                                  mainAxisSpacing: ResponsiveService.getPadding(context),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _armoires.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showCreateArmoireDialog,
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              child: Icon(
                Icons.add,
                size: ResponsiveService.getIconSize(context),
              ),
            )
          : null,
    );
  }
} 