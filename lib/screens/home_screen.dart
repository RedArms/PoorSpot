import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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
  final MapController _mapController = MapController();

  List<Spot> _spots = [];
  Spot? _selectedSpot;
  bool _isLoading = true;
  LatLng? _tempSpotPos; 
  
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  
  // Contrôleur pour l'avis
  final TextEditingController _reviewCommentCtrl = TextEditingController();

  String _selectedCategory = 'Tourisme';
  double _ratingRevenue = 2.5;
  double _ratingSecurity = 2.5;
  double _ratingTraffic = 2.5;
  bool _isCreating = false;
  bool _isSubmittingReview = false; // État pour l'envoi d'avis

  final List<String> _categories = ['Tourisme', 'Business', 'Shopping', 'Nightlife', 'Transport', 'Culture', 'Parc', 'Market', 'Nature'];

  Timer? _globalTimer;
  Spot? _activeSessionSpot;
  String _activeSessionDuration = "00:00:00";

  @override
  void initState() {
    super.initState();
    _loadSpots();
    _locateUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _reviewCommentCtrl.dispose();
    _globalTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSpots() async {
    final spots = await _api.fetchSpots();
    if (mounted) {
      setState(() {
        _spots = spots;
        _isLoading = false;
      });
      _checkActiveSession();
    }
  }

  Future<void> _locateUser() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  void _checkActiveSession() {
    _globalTimer?.cancel();
    _activeSessionSpot = null;
    final user = CurrentSession().user;
    if (user != null && user.history.isNotEmpty) {
      try {
        final activeLog = user.history.firstWhere((log) => log.durationSeconds == 0);
        final spot = _spots.firstWhere((s) => s.id == activeLog.spotId, orElse: () => _spots.first);
        setState(() { _activeSessionSpot = spot; });
        final startTime = activeLog.timestamp;
        _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final now = DateTime.now();
          final duration = now.difference(startTime);
          final h = duration.inHours.toString().padLeft(2, '0');
          final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
          final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
          if (mounted) setState(() { _activeSessionDuration = "$h:$m:$s"; });
        });
      } catch (e) { setState(() { _activeSessionSpot = null; }); }
    }
  }

  void _onSpotTap(Spot spot) { setState(() { _selectedSpot = spot; _tempSpotPos = null; }); }
  
  void _onMapLongPress(LatLng pos) {
    if (!CurrentSession().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connectez-vous pour ajouter un spot !"), backgroundColor: Colors.redAccent));
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    _nameCtrl.clear(); _descCtrl.clear(); _ratingRevenue=2.5; _ratingSecurity=2.5; _ratingTraffic=2.5; _selectedCategory='Tourisme';
    setState(() { _selectedSpot = null; _tempSpotPos = pos; });
    _showCreateDialog(pos);
  }

  void _showCreateDialog(LatLng pos) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) {
      return StatefulBuilder(builder: (context, setModalState) {
        return BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Dialog(backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(16), child: Container(width: MediaQuery.of(context).size.width * 0.9, constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700), decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF00C853).withOpacity(0.5), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]), child: Column(children: [Padding(padding: const EdgeInsets.all(20), child: Row(children: [const Icon(Icons.add_location_alt, color: Color(0xFF00C853), size: 28), const SizedBox(width: 12), const Text("NOUVEAU SPOT", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)), const Spacer(), IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () { setState(() => _tempSpotPos = null); Navigator.pop(context); })])), const Divider(height: 1, color: Colors.white10), Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor("Nom du spot", Icons.place)), const SizedBox(height: 16), TextField(controller: _descCtrl, style: const TextStyle(color: Colors.white), maxLines: 2, decoration: _inputDecor("Description", Icons.description)), const SizedBox(height: 24), const Text("CATÉGORIE", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: _categories.map((cat) { final isSelected = _selectedCategory == cat; return ChoiceChip(label: Text(cat.toUpperCase(), style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : Colors.white70)), selected: isSelected, onSelected: (v) => setModalState(() => _selectedCategory = cat), selectedColor: const Color(0xFF00C853), backgroundColor: Colors.white10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none)); }).toList()), const SizedBox(height: 32), const Text("CRITÈRES & ÉVALUATION", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)), const SizedBox(height: 16), _buildRatingSlider("REVENU", Icons.attach_money, _ratingRevenue, (v) => setModalState(() => _ratingRevenue = v)), const SizedBox(height: 12), _buildRatingSlider("SÉCURITÉ", Icons.lock_outline, _ratingSecurity, (v) => setModalState(() => _ratingSecurity = v)), const SizedBox(height: 12), _buildRatingSlider("PASSAGE", Icons.directions_walk, _ratingTraffic, (v) => setModalState(() => _ratingTraffic = v))]))), Padding(padding: const EdgeInsets.all(24), child: SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isCreating ? null : () { _createSpot(); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isCreating ? const CircularProgressIndicator(color: Colors.black) : const Text("VALIDER LE SPOT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))))]) )));
      });
    });
  }

  // --- NOUVEAU : BOITE DE DIALOGUE D'AVIS ---
  void _showAddReviewDialog(Spot spot) {
    if (!CurrentSession().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connectez-vous pour laisser un avis !"), backgroundColor: Colors.redAccent));
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    // Reset values
    _reviewCommentCtrl.clear();
    _ratingRevenue = 2.5;
    _ratingSecurity = 2.5;
    _ratingTraffic = 2.5;

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
                  constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF00C853).withOpacity(0.5), width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(Icons.rate_review, color: Color(0xFF00C853), size: 28),
                            const SizedBox(width: 12),
                            const Text("NOUVEL AVIS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Votre avis sur : ${spot.name}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 20),
                              
                              _buildRatingSlider("REVENU", Icons.attach_money, _ratingRevenue, (v) => setModalState(() => _ratingRevenue = v)),
                              const SizedBox(height: 12),
                              _buildRatingSlider("SÉCURITÉ", Icons.lock_outline, _ratingSecurity, (v) => setModalState(() => _ratingSecurity = v)),
                              const SizedBox(height: 12),
                              _buildRatingSlider("PASSAGE", Icons.directions_walk, _ratingTraffic, (v) => setModalState(() => _ratingTraffic = v)),
                              
                              const SizedBox(height: 24),
                              TextField(
                                controller: _reviewCommentCtrl,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 3,
                                decoration: _inputDecor("Votre commentaire...", Icons.comment),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmittingReview ? null : () {
                              _submitReview(spot);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: _isSubmittingReview 
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text("PUBLIER L'AVIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _submitReview(Spot spot) async {
    if (_reviewCommentCtrl.text.isEmpty) return;
    
    setState(() => _isSubmittingReview = true);
    final user = CurrentSession().user!;
    
    final newReview = Review(
      id: "rev_${DateTime.now().millisecondsSinceEpoch}",
      authorName: user.name,
      ratingRevenue: _ratingRevenue,
      ratingSecurity: _ratingSecurity,
      ratingTraffic: _ratingTraffic,
      attribute: user.attributes.isNotEmpty ? user.attributes.first : BeggarAttribute.none,
      comment: _reviewCommentCtrl.text.trim(),
      createdAt: DateTime.now()
    );

    final success = await _api.addReview(spot.id, newReview);
    
    setState(() => _isSubmittingReview = false);

    if (success) {
      // Mise à jour locale
      setState(() {
        spot.reviews.insert(0, newReview);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Avis publié ! Merci."), backgroundColor: Color(0xFF00C853)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'envoi."), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _createSpot() async {
    if (_nameCtrl.text.isEmpty || _tempSpotPos == null) return;
    setState(() => _isCreating = true);
    final user = CurrentSession().user!;
    
    // --- MODIFICATION ICI ---
    // Si une description est fournie, on l'utilise. Sinon, on met "Création du spot"
    final commentText = _descCtrl.text.trim().isNotEmpty 
        ? _descCtrl.text.trim() 
        : "Création du spot";

    final initialReview = Review(
      id: "init_${DateTime.now().millisecondsSinceEpoch}", 
      authorName: user.name, 
      ratingRevenue: _ratingRevenue, 
      ratingSecurity: _ratingSecurity, 
      ratingTraffic: _ratingTraffic, 
      attribute: user.attributes.isNotEmpty ? user.attributes.first : BeggarAttribute.none, 
      comment: commentText, // Utilisation du commentaire dynamique
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
      currentActiveUsers: 0
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

  void _onLoginSuccess() { _checkActiveSession(); setState(() {}); }

  Widget _buildRatingSlider(String label, IconData icon, double value, ValueChanged<double> onChanged) {
    final color = _getGraduatedColor(value);
    return Column(children: [Row(children: [Icon(icon, color: Colors.white54, size: 16), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(value.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)))]), SliderTheme(data: SliderThemeData(activeTrackColor: color, thumbColor: color, inactiveTrackColor: Colors.white10, trackHeight: 4.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16), overlayColor: color.withOpacity(0.2)), child: Slider(value: value, min: 0.0, max: 5.0, divisions: 10, onChanged: onChanged))]);
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(prefixIcon: Icon(icon, color: Colors.white38, size: 20), labelText: label, labelStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00C853))), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16));
  }

  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth > 500 ? 450.0 : screenWidth * 0.90;

    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileDrawer(
        onLoginSuccess: _onLoginSuccess,
        allSpots: _spots,
        onSpotTap: (spot) { setState(() { _selectedSpot = spot; _tempSpotPos = null; }); _mapController.move(spot.position, 16); },
      ),
      body: Stack(
        children: [
          _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853))) : MapView(spots: _spots, onSpotTap: _onSpotTap, onMapLongPress: _onMapLongPress, tempPosition: _tempSpotPos, selectedSpotId: _selectedSpot?.id, mapController: _mapController),
          Positioned(top: MediaQuery.of(context).padding.top + 10, left: 20, child: FloatingActionButton(mini: true, backgroundColor: const Color(0xFF0F172A), heroTag: "menuBtn", onPressed: () => _scaffoldKey.currentState?.openDrawer(), child: const Icon(Icons.menu, color: Colors.white))),
          Positioned(bottom: 30, right: 20, child: FloatingActionButton(backgroundColor: const Color(0xFF00C853), onPressed: _locateUser, child: const Icon(Icons.my_location, color: Colors.black))),
          
          // --- MINI LECTEUR DE SESSION (RÉINTÉGRÉ) ---
          if (_activeSessionSpot != null && (_selectedSpot == null || _selectedSpot!.id != _activeSessionSpot!.id))
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() { _selectedSpot = _activeSessionSpot; });
                  _mapController.move(_activeSessionSpot!.position, 16);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF00C853), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Color(0xFF00C853), size: 16),
                      const SizedBox(width: 8),
                      Text(_activeSessionDuration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 12, color: Colors.white24),
                      const SizedBox(width: 8),
                      Text(_activeSessionSpot!.name, style: const TextStyle(color: Colors.white70, fontSize: 10))
                    ],
                  ),
                ),
              ),
            ),
          // ---------------------------------------------

          if (_selectedSpot != null) 
            Align(
              alignment: Alignment.centerRight, 
              child: SizedBox(
                width: panelWidth, 
                child: SidePanel(
                  spot: _selectedSpot!, 
                  onClose: () => setState(() => _selectedSpot = null), 
                  onAddReview: () => _showAddReviewDialog(_selectedSpot!), // <--- CONNEXION ICI
                  onFavoriteChanged: () {}, 
                  onHistoryChanged: () { _checkActiveSession(); setState(() {}); }
                )
              )
            ),
        ],
      ),
    );
  }
}