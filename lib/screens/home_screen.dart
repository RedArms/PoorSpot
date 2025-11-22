import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot_models.dart';
import '../data/mock_data.dart'; 
import '../widgets/map_view.dart';
import '../widgets/side_panel.dart';
import '../widgets/profile_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Spot? _selectedSpot;
  LatLng? _tempNewSpotPosition;
  final List<Spot> _spots = [...mockSpots];

  void _onSpotSelected(Spot spot) {
    setState(() {
      _selectedSpot = spot;
      _tempNewSpotPosition = null;
    });
  }

  void _onMapLongPress(LatLng position) {
    setState(() {
      _selectedSpot = null;
      _tempNewSpotPosition = position;
    });
  }

  void _openCreateDialog() {
    if (_tempNewSpotPosition == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _CreateSpotDialog(
        position: _tempNewSpotPosition!,
        onSubmit: (Spot newSpot) {
          setState(() {
            _spots.add(newSpot);
            _tempNewSpotPosition = null;
            _selectedSpot = newSpot;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _onAddReview() {
    if (_selectedSpot == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _AddReviewDialog(
        spotName: _selectedSpot!.name,
        onSubmit: (Review newReview) {
          setState(() {
            final updatedSpot = Spot(
              id: _selectedSpot!.id,
              name: _selectedSpot!.name,
              description: _selectedSpot!.description,
              position: _selectedSpot!.position,
              category: _selectedSpot!.category,
              createdAt: _selectedSpot!.createdAt,
              createdBy: _selectedSpot!.createdBy,
              currentActiveUsers: _selectedSpot!.currentActiveUsers,
              reviews: [newReview, ..._selectedSpot!.reviews],
            );

            final index = _spots.indexWhere((s) => s.id == updatedSpot.id);
            if (index != -1) {
              _spots[index] = updatedSpot;
            }
            _selectedSpot = updatedSpot;
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _cancelCreation() {
    setState(() { _tempNewSpotPosition = null; });
  }

  void _closePanel() {
    setState(() { _selectedSpot = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const ProfileDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: PoorSpotMap(
              spots: _spots,
              selectedSpotId: _selectedSpot?.id,
              tempPosition: _tempNewSpotPosition,
              onSpotTap: _onSpotSelected,
              onMapLongPress: _onMapLongPress,
            ),
          ),
          
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white), 
                onPressed: () => _scaffoldKey.currentState?.openDrawer()
              ),
            ),
          ),

          if (_tempNewSpotPosition != null)
             Positioned(
              bottom: 40, left: 20, right: 20,
              child: Card(
                color: const Color(0xFF0F172A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.add_location, color: Color(0xFF00C853)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text("DÉCLARER ZONE ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      TextButton(onPressed: _cancelCreation, child: const Text("ANNULER", style: TextStyle(color: Colors.redAccent))),
                      ElevatedButton(
                        onPressed: _openCreateDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
                        child: const Text("CRÉER"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutExpo,
            top: 0, bottom: 0,
            right: _selectedSpot != null ? 0 : -450,
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width,
            child: _selectedSpot != null 
              ? SidePanel(
                  spot: _selectedSpot!, 
                  onClose: _closePanel,
                  onAddReview: _onAddReview,
                ) 
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// --- CRÉATION DE SPOT ---
class _CreateSpotDialog extends StatefulWidget {
  final LatLng position;
  final Function(Spot) onSubmit;
  const _CreateSpotDialog({required this.position, required this.onSubmit});
  @override
  State<_CreateSpotDialog> createState() => _CreateSpotDialogState();
}

class _CreateSpotDialogState extends State<_CreateSpotDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Tourisme';
  double _revenue = 3.0;
  double _security = 3.0;
  double _traffic = 3.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('NOUVEAU SPOT', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Nom du lieu', labelStyle: TextStyle(color: Colors.grey)),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Catégorie', labelStyle: TextStyle(color: Colors.grey)),
                items: ['Tourisme', 'Business', 'Shopping', 'Nightlife', 'Transport'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),
              const Text("NOTATION RAPIDE", style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildSlider("Revenu", _revenue, (v) => setState(() => _revenue = v)),
              _buildSlider("Sécurité", _security, (v) => setState(() => _security = v)),
              _buildSlider("Passage", _traffic, (v) => setState(() => _traffic = v)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Commentaire', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
          child: const Text("VALIDER"),
        )
      ],
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    // Couleur dynamique ROUGE -> VERT
    final color = _getGraduatedColor(value);
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Slider(
            value: value, min: 1, max: 5, divisions: 4,
            activeColor: color, 
            thumbColor: color,
            inactiveColor: Colors.white10,
            label: value.toStringAsFixed(0), onChanged: onChanged,
          ),
        ),
        Text(value.toStringAsFixed(0), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final userAttribute = currentUser.myAttributes.isNotEmpty ? currentUser.myAttributes.first : BeggarAttribute.none;
      final newSpot = Spot(
        id: DateTime.now().toString(),
        name: _nameController.text,
        description: _descController.text,
        position: widget.position,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        createdBy: currentUser.name,
        reviews: [
          Review(
            id: 'init', authorName: currentUser.name,
            ratingRevenue: _revenue, ratingSecurity: _security, ratingTraffic: _traffic,
            attribute: userAttribute, comment: _descController.text, createdAt: DateTime.now(),
          )
        ],
      );
      widget.onSubmit(newSpot);
    }
  }
}

// --- AJOUT D'AVIS ---
class _AddReviewDialog extends StatefulWidget {
  final String spotName;
  final Function(Review) onSubmit;
  const _AddReviewDialog({required this.spotName, required this.onSubmit});
  @override
  State<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<_AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _revenue = 3.0;
  double _security = 3.0;
  double _traffic = 3.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DÉCLARER UN GAIN', style: TextStyle(color: Colors.white, fontSize: 14)),
          Text(widget.spotName, style: const TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("COMMENT C'ÉTAIT ?", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildSlider("Revenu", _revenue, (v) => setState(() => _revenue = v)),
              _buildSlider("Sécurité", _security, (v) => setState(() => _security = v)),
              _buildSlider("Passage", _traffic, (v) => setState(() => _traffic = v)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _commentController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Commentaire rapide', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
          child: const Text("PUBLIER"),
        )
      ],
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    final color = _getGraduatedColor(value);
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Slider(
            value: value, min: 1, max: 5, divisions: 4,
            activeColor: color,
            thumbColor: color,
            inactiveColor: Colors.white10,
            label: value.toStringAsFixed(0), onChanged: onChanged,
          ),
        ),
        Text(value.toStringAsFixed(0), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final userAttribute = currentUser.myAttributes.isNotEmpty ? currentUser.myAttributes.first : BeggarAttribute.none;
      final newReview = Review(
        id: DateTime.now().toString(),
        authorName: currentUser.name,
        ratingRevenue: _revenue,
        ratingSecurity: _security,
        ratingTraffic: _traffic,
        attribute: userAttribute,
        comment: _commentController.text.isEmpty ? "Rien à signaler." : _commentController.text,
        createdAt: DateTime.now(),
      );
      widget.onSubmit(newReview);
    }
  }
}