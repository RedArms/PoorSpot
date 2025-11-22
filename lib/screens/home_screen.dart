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
          
          // Bouton Menu
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

          // Création de spot
          if (_tempNewSpotPosition != null)
             Positioned(
              bottom: 40, left: 20, right: 20,
              child: Card(
                color: const Color(0xFF0F172A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.add_location, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 12),
                      const Expanded(child: Text("DÉCLARER ZONE ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      TextButton(onPressed: _cancelCreation, child: const Text("ANNULER", style: TextStyle(color: Colors.redAccent))),
                      ElevatedButton(
                        onPressed: _openCreateDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
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
              ? SidePanel(spot: _selectedSpot!, onClose: _closePanel) 
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

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
  final _rateController = TextEditingController();
  
  String _selectedCategory = 'Tourisme';
  BeggarAttribute _selectedAttribute = BeggarAttribute.none;

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
              DropdownButton<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: ['Tourisme', 'Business', 'Shopping', 'Nightlife'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),
              const Text("ATTRIBUT UTILISÉ (SKIN)", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
              DropdownButton<BeggarAttribute>(
                value: _selectedAttribute,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                isExpanded: true,
                items: BeggarAttribute.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedAttribute = v!),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'GAIN HORAIRE ESTIMÉ (€)', suffixText: '€/h'),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
          child: const Text("VALIDER"),
        )
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final rate = double.tryParse(_rateController.text) ?? 0.0;
      final newSpot = Spot(
        id: DateTime.now().toString(),
        name: _nameController.text,
        description: _descController.text,
        position: widget.position,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        createdBy: 'Moi',
        reviews: [
          Review(
            id: 'init', authorName: 'Moi',
            hourlyRate: rate, attribute: _selectedAttribute,
            comment: _descController.text, createdAt: DateTime.now(),
          )
        ],
      );
      widget.onSubmit(newSpot);
    }
  }
}