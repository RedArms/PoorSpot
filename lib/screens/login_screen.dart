import 'package:flutter/material.dart';
import '../models/spot_models.dart';
import '../services/api_service.dart';
import '../data/current_session.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  
  // Par défaut, on sélectionne "Aucun" tag
  List<BeggarAttribute> _selectedAttributes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 80, color: Color(0xFF00C853)),
              const SizedBox(height: 20),
              const Text("POORSPOT", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text("Le Waze de la rue", style: TextStyle(color: Colors.grey, fontSize: 14)),
              
              const SizedBox(height: 40),
              
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Votre Pseudonyme",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00C853)), borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05)
                ),
              ),
              
              const SizedBox(height: 20),
              const Text("VOS ATOUTS (Optionnel)", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: BeggarAttribute.values.where((e) => e != BeggarAttribute.none).map((attr) {
                  final isSelected = _selectedAttributes.contains(attr);
                  return FilterChip(
                    label: Text(attr.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAttributes.add(attr);
                        } else {
                          _selectedAttributes.remove(attr);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF00C853),
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                    backgroundColor: Colors.white10,
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("COMMENCER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_nameController.text.isEmpty) return;

    setState(() { _isLoading = true; });

    final user = await _api.register(
      _nameController.text.trim(), 
      "default_password", // Mot de passe par défaut pour simplifier
      _selectedAttributes
    );

    setState(() { _isLoading = false; });

    if (user != null) {
      // Sauvegarde en session
      CurrentSession().user = user;
      
      // Navigation vers la Map
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const HomeScreen())
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur de connexion au serveur")));
    }
  }
}