import 'package:flutter/material.dart';
import '../models/spot_models.dart';
import '../data/current_session.dart';
import '../services/api_service.dart';

class ProfileDrawer extends StatefulWidget {
  final VoidCallback onLoginSuccess; 

  const ProfileDrawer({super.key, required this.onLoginSuccess});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  final ApiService _api = ApiService();
  
  bool _isRegistering = false;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  List<BeggarAttribute> _selectedAttributes = [];
  bool _isLoading = false;
  String? _errorMsg;

  @override
  Widget build(BuildContext context) {
    final user = CurrentSession().user;

    if (user != null) {
      return _buildUserProfile(user);
    }
    return _buildAuthForm();
  }

  // --- LOGIN / REGISTER ---
  Widget _buildAuthForm() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 60, color: Color(0xFF00C853)),
                const SizedBox(height: 20),
                Text(
                  _isRegistering ? "CRÉER COMPTE" : "CONNEXION",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text("Identifiez-vous pour participer.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                
                const SizedBox(height: 30),
                
                if (_errorMsg != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),

                TextField(
                  controller: _usernameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecor("Pseudonyme", Icons.person),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecor("Mot de passe", Icons.key),
                ),

                if (_isRegistering) ...[
                  const SizedBox(height: 20),
                  const Text("VOS SPÉCIALITÉS", style: TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: BeggarAttribute.values.where((e) => e != BeggarAttribute.none).map((attr) {
                      final isSelected = _selectedAttributes.contains(attr);
                      return FilterChip(
                        label: Text(attr.name, style: const TextStyle(fontSize: 10)),
                        selected: isSelected,
                        onSelected: (v) => setState(() { v ? _selectedAttributes.add(attr) : _selectedAttributes.remove(attr); }),
                        selectedColor: const Color(0xFF00C853),
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                        backgroundColor: Colors.white10,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                      : Text(_isRegistering ? "S'INSCRIRE" : "SE CONNECTER", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() { 
                    _isRegistering = !_isRegistering; 
                    _errorMsg = null;
                  }),
                  child: Text(
                    _isRegistering ? "J'ai déjà un compte" : "Créer un compte",
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PROFIL ---
  Widget _buildUserProfile(user) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              border: Border(bottom: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 30, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Color(0xFF00C853), size: 35)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("MEMBRE ACTIF", style: TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionTitle("MES SPÉCIALITÉS"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: user.attributes.map<Widget>((attr) => Chip(
                      label: Text(attr.name),
                      backgroundColor: const Color(0xFF00C853).withOpacity(0.2),
                      labelStyle: const TextStyle(color: Color(0xFF00C853), fontSize: 10),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white54, size: 18),
                  title: const Text("Modifier mes atouts", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  onTap: _showEditTagsDialog,
                  dense: true,
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
            child: OutlinedButton.icon(
              onPressed: () {
                CurrentSession().user = null;
                setState(() {}); 
                widget.onLoginSuccess(); 
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text("DÉCONNEXION"),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _submitAuth() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errorMsg = "Champs requis");
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = _isRegistering
      ? await _api.register(_usernameCtrl.text, _passwordCtrl.text, _selectedAttributes)
      : await _api.login(_usernameCtrl.text, _passwordCtrl.text);

    setState(() => _isLoading = false);

    if (result != null) {
      CurrentSession().user = result;
      widget.onLoginSuccess(); 
      Navigator.pop(context); 
    } else {
      setState(() => _errorMsg = "Identifiants incorrects ou erreur serveur");
    }
  }

  void _showEditTagsDialog() {
    final user = CurrentSession().user!;
    List<BeggarAttribute> tempTags = List.from(user.attributes);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("MODIFIER PROFIL", style: TextStyle(color: Colors.white, fontSize: 16)),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BeggarAttribute.values.where((e) => e != BeggarAttribute.none).map((attr) {
                final isSelected = tempTags.contains(attr);
                return FilterChip(
                  label: Text(attr.name, style: const TextStyle(fontSize: 10)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) tempTags.add(attr);
                      else tempTags.remove(attr);
                    });
                  },
                  selectedColor: const Color(0xFF00C853),
                  checkmarkColor: Colors.black,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                  backgroundColor: Colors.white10,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("ANNULER")),
              ElevatedButton(
                onPressed: () async {
                  await _api.updateUserTags(user.id, tempTags);
                  user.attributes.clear();
                  user.attributes.addAll(tempTags);
                  Navigator.pop(context);
                  this.setState(() {}); 
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
                child: const Text("SAUVEGARDER"),
              )
            ],
          );
        }
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }
}