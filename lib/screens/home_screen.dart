import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot_models.dart';
import '../services/api_service.dart';
import '../widgets/map_view.dart';
import '../widgets/side_panel.dart';
import '../widgets/profile_drawer.dart';
import '../data/current_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Spot> _spots = [];
  Spot? _selectedSpot;
  bool _isLoading = true;
  
  // État pour la création de spot
  LatLng? _tempSpotPos; 
  
  // Contrôleurs pour le formulaire de création
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _selectedCategory = 'Tourisme';
  
  // Notes initiales pour la création
  double _ratingRevenue = 2.5;
  double _ratingSecurity = 2.5;
  double _ratingTraffic = 2.5;

  bool _isCreating = false;

  final List<String> _categories = [
    'Tourisme', 'Business', 'Shopping', 'Nightlife', 
    'Transport', 'Culture', 'Parc', 'Market', 'Nature'
  ];

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSpots() async {
    final spots = await _api.fetchSpots();
    if (mounted) {
      setState(() {
        _spots = spots;
        _isLoading = false;
      });
    }
  }

  void _onSpotTap(Spot spot) {
    setState(() {
      _selectedSpot = spot;
      _tempSpotPos = null; 
    });
  }

  void _onMapLongPress(LatLng pos) {
    if (!CurrentSession().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connectez-vous pour ajouter un spot !"),
          backgroundColor: Colors.redAccent,
        )
      );
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    // Reset du formulaire
    _nameCtrl.clear();
    _descCtrl.clear();
    _ratingRevenue = 2.5;
    _ratingSecurity = 2.5;
    _ratingTraffic = 2.5;
    _selectedCategory = 'Tourisme';

    setState(() {
      _selectedSpot = null; // Ferme le panneau de consultation
      _tempSpotPos = pos;   
    });

    _showCreateDialog(pos);
  }

  // --- POP-UP DE CRÉATION ---
  void _showCreateDialog(LatLng pos) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF00C853).withOpacity(0.5), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: Column(
                    children: [
                      // HEADER
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.add_location_alt, color: Color(0xFF00C853), size: 28),
                            const SizedBox(width: 12),
                            const Text("NOUVEAU SPOT", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () {
                                setState(() => _tempSpotPos = null);
                                Navigator.pop(context);
                              },
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      
                      // CONTENT SCROLLABLE
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecor("Nom du spot", Icons.place),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _descCtrl,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                decoration: _inputDecor("Description", Icons.description),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              const Text("CATÉGORIE", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((cat) {
                                  final isSelected = _selectedCategory == cat;
                                  return ChoiceChip(
                                    label: Text(cat.toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : Colors.white70)),
                                    selected: isSelected,
                                    onSelected: (v) => setModalState(() => _selectedCategory = cat),
                                    selectedColor: const Color(0xFF00C853),
                                    backgroundColor: Colors.white10,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 32),
                              const Text("CRITÈRES & ÉVALUATION", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const SizedBox(height: 16),

                              _buildRatingSlider("REVENU", Icons.attach_money, _ratingRevenue, (v) => setModalState(() => _ratingRevenue = v)),
                              const SizedBox(height: 12),
                              _buildRatingSlider("SÉCURITÉ", Icons.lock_outline, _ratingSecurity, (v) => setModalState(() => _ratingSecurity = v)),
                              const SizedBox(height: 12),
                              _buildRatingSlider("PASSAGE", Icons.directions_walk, _ratingTraffic, (v) => setModalState(() => _ratingTraffic = v)),
                            ],
                          ),
                        ),
                      ),

                      // FOOTER ACTIONS
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : () {
                              _createSpot();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: _isCreating 
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text("VALIDER LE SPOT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildRatingSlider(String label, IconData icon, double value, ValueChanged<double> onChanged) {
    final color = _getGraduatedColor(value);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: Text(value.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: Colors.white10,
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C853))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) {
      return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    } else {
      return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
    }
  }

  Future<void> _createSpot() async {
    if (_nameCtrl.text.isEmpty || _tempSpotPos == null) return;
    setState(() => _isCreating = true);
    final user = CurrentSession().user!;
    
    final initialReview = Review(
      id: "init_${DateTime.now().millisecondsSinceEpoch}", 
      authorName: user.name, 
      ratingRevenue: _ratingRevenue, 
      ratingSecurity: _ratingSecurity, 
      ratingTraffic: _ratingTraffic, 
      attribute: user.attributes.isNotEmpty ? user.attributes.first : BeggarAttribute.none, 
      comment: "Création du spot", 
      createdAt: DateTime.now()
    );

    final newSpot = Spot(
      id: "",
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      position: _tempSpotPos!,
      reviews: [initialReview],
      category: _selectedCategory,
      createdAt: DateTime.now(),
      createdBy: user.id,
      currentActiveUsers: 0,
    );

    final created = await _api.createSpot(newSpot);

    setState(() => _isCreating = false);

    if (created != null) {
      setState(() {
        _spots.add(created);
        _tempSpotPos = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Spot créé avec succès !"), backgroundColor: Color(0xFF00C853)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la création du spot."), backgroundColor: Colors.redAccent));
    }
  }

  void _onLoginSuccess() {
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de la largeur du panneau (Responsive)
    final screenWidth = MediaQuery.of(context).size.width;
    // Sur mobile (< 500px) : 90% de l'écran
    // Sur desktop/tablette (> 500px) : Fixé à 450px
    final panelWidth = screenWidth > 500 ? 450.0 : screenWidth * 0.90;

    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileDrawer(
        onLoginSuccess: _onLoginSuccess,
        allSpots: _spots,
        onSpotTap: (spot) {
          setState(() {
            _selectedSpot = spot;
            _tempSpotPos = null;
          });
        },
      ),
      body: Stack(
        children: [
          // 1. CARTE
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
              : MapView(
                  spots: _spots, 
                  onSpotTap: _onSpotTap,
                  onMapLongPress: _onMapLongPress, 
                  tempPosition: _tempSpotPos,
                  selectedSpotId: _selectedSpot?.id,
                ),

          // 2. BOUTON MENU
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF0F172A),
              heroTag: "menuBtn",
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ),

          // 3. SIDE PANEL (CONSULTATION)
          // Changement ici : On utilise ConstrainedBox au lieu de FractionallySizedBox
          if (_selectedSpot != null)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: panelWidth, // Largeur calculée dynamiquement
                child: SidePanel(
                  spot: _selectedSpot!,
                  onClose: () => setState(() => _selectedSpot = null),
                  onAddReview: () {
                    // TODO: Implémenter la modale d'avis si besoin
                  },
                  onFavoriteChanged: () {},
                  onHistoryChanged: () => setState(() {}),
                ),
              ),
            ),
        ],
      ),
    );
  }
}