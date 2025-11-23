import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // IMPORTANT pour LatLng
import '../models/spot_models.dart';
import '../services/api_service.dart';
import '../widgets/map_view.dart';
import '../widgets/side_panel.dart';
import '../widgets/profile_drawer.dart';
import '../data/current_session.dart';
import 'leaderboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSpots();
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
      _tempSpotPos = null; // On annule la création si on clique sur un spot existant
    });
  }

  // Gère l'appui long sur la carte (Création)
  void _onMapLongPress(LatLng pos) {
    if (!CurrentSession().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour ajouter un spot !"))
      );
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    setState(() {
      _selectedSpot = null;
      _tempSpotPos = pos;
    });
    
    // Ici, tu pourrais ouvrir directement une modale de création si tu veux
    // Pour l'instant ça place juste le marqueur "+"
    _showCreateDialog(pos);
  }

  void _showCreateDialog(LatLng pos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Créer un spot ici ?"),
        content: const Text("Voulez-vous ajouter ce lieu à la carte ?"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _tempSpotPos = null);
              Navigator.pop(ctx);
            }, 
            child: const Text("ANNULER")
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Ouvrir le formulaire de création
              // _openCreateForm(pos); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feature de création à venir !")));
              setState(() => _tempSpotPos = null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853)),
            child: const Text("CRÉER", style: TextStyle(color: Colors.black)),
          )
        ],
      )
    );
  }

  void _onLoginSuccess() {
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
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
                  // AJOUTS ICI :
                  onMapLongPress: _onMapLongPress, 
                  tempPosition: _tempSpotPos,
                  selectedSpotId: _selectedSpot?.id,
                ),

          // 2. BOUTON MENU (Haut Gauche)
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

          // 3. SIDE PANEL (Si spot sélectionné)
          if (_selectedSpot != null)
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.85,
                child: SidePanel(
                  spot: _selectedSpot!,
                  onClose: () => setState(() => _selectedSpot = null),
                  onAddReview: () {},
                  onFavoriteChanged: () {},
                  onHistoryChanged: () {
                    setState(() {}); 
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}