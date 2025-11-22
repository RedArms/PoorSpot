import 'package:flutter/material.dart';
import '../models/spot_models.dart';
import '../models/user_model.dart';
import '../data/current_session.dart';
import '../services/api_service.dart';

class ProfileDrawer extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final List<Spot>? allSpots;
  final Function(Spot)? onSpotTap;

  const ProfileDrawer({
    super.key, 
    required this.onLoginSuccess, 
    this.allSpots,
    this.onSpotTap,
  });

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  
  bool _isRegistering = false;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  List<BeggarAttribute> _selectedAttributes = [];
  bool _isLoading = false;
  String? _errorMsg;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (CurrentSession().user != null) {
      _tabController = TabController(length: 3, vsync: this);
    }
  }

  @override
  void didUpdateWidget(covariant ProfileDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (CurrentSession().user != null && _tabController == null) {
      _tabController = TabController(length: 3, vsync: this);
    } else if (CurrentSession().user == null && _tabController != null) {
      _tabController?.dispose();
      _tabController = null;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  List<_UserReviewWithSpot> _getUserReviews() {
    final user = CurrentSession().user;
    if (user == null || widget.allSpots == null) return [];

    List<_UserReviewWithSpot> userReviews = [];
    for (var spot in widget.allSpots!) {
      for (var review in spot.reviews) {
        if (review.authorName == user.name) {
          userReviews.add(_UserReviewWithSpot(review: review, spot: spot));
        }
      }
    }
    userReviews.sort((a, b) => b.review.createdAt.compareTo(a.review.createdAt));
    return userReviews;
  }

  List<Spot> _getFavoriteSpots() {
    final user = CurrentSession().user;
    if (user == null || widget.allSpots == null) return [];
    return widget.allSpots!.where((spot) => user.favorites.contains(spot.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = CurrentSession().user;

    if (user != null) {
      if (_tabController == null) {
        _tabController = TabController(length: 3, vsync: this);
      }
      return _buildUserProfile(user);
    }
    return _buildAuthForm();
  }

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
                        label: Text(_getAttributeDisplayName(attr), style: const TextStyle(fontSize: 10)),
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

  Widget _buildUserProfile(User user) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              border: Border(bottom: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3), width: 1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Color(0xFF00C853), size: 32)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text("MEMBRE ACTIF", style: TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // TAB BAR - 3 TABS
          Container(
            color: const Color(0xFF020617),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF00C853),
              indicatorWeight: 3,
              labelColor: const Color(0xFF00C853),
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: "PROFIL", icon: Icon(Icons.person_outline, size: 18)),
                Tab(text: "FAVORIS", icon: Icon(Icons.star_outline, size: 18)),
                Tab(text: "MES AVIS", icon: Icon(Icons.rate_review_outlined, size: 18)),
              ],
            ),
          ),

          // TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(user),
                _buildFavoritesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),

          // LOGOUT BUTTON
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
            child: OutlinedButton.icon(
              onPressed: () {
                CurrentSession().user = null;
                _tabController?.dispose();
                _tabController = null;
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

  // --- PROFILE TAB ---
  Widget _buildProfileTab(User user) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSectionTitle("MES SPÉCIALITÉS"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: user.attributes.isEmpty
            ? const Text("Aucune spécialité définie", style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.attributes.map<Widget>((attr) => Chip(
                  label: Text(_getAttributeDisplayName(attr)),
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
        
        const Divider(color: Colors.white10, height: 30),
        
        _buildSectionTitle("STATISTIQUES"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatCard(Icons.rate_review, _getUserReviews().length.toString(), "Avis"),
              const SizedBox(width: 12),
              _buildStatCard(Icons.star, _getFavoriteSpots().length.toString(), "Favoris"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00C853), size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // --- FAVORITES TAB ---
  Widget _buildFavoritesTab() {
    final favorites = _getFavoriteSpots();

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 60, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text("Aucun favori pour le moment", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            const Text("Ajoutez des spots avec l'étoile ⭐", style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final spot = favorites[index];
        return _FavoriteSpotCard(
          spot: spot,
          onTap: () {
            Navigator.pop(context); // Close drawer
            widget.onSpotTap?.call(spot);
          },
        );
      },
    );
  }

  // --- REVIEWS TAB ---
  Widget _buildReviewsTab() {
    final userReviews = _getUserReviews();

    if (userReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text("Aucun avis pour le moment", style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            const Text("Partagez votre expérience sur les spots !", style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: userReviews.length,
      itemBuilder: (context, index) {
        final item = userReviews[index];
        return _UserReviewCard(item: item);
      },
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
      _tabController = TabController(length: 3, vsync: this);
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
                  label: Text(_getAttributeDisplayName(attr), style: const TextStyle(fontSize: 10)),
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

  String _getAttributeDisplayName(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.none: return "Aucun";
      case BeggarAttribute.dog: return "Chien";
      case BeggarAttribute.music: return "Musique";
      case BeggarAttribute.disability: return "Handicap";
      case BeggarAttribute.circus: return "Cirque";
      case BeggarAttribute.family: return "Famille";
    }
  }
}

// --- Helper class ---
class _UserReviewWithSpot {
  final Review review;
  final Spot spot;
  _UserReviewWithSpot({required this.review, required this.spot});
}

// --- Favorite Spot Card ---
class _FavoriteSpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onTap;

  const _FavoriteSpotCard({required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = spot.globalRating;
    final color = _getGraduatedColor(rating);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Rating circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getCategoryIcon(spot.category), size: 14, color: Colors.white54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          spot.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.category.toUpperCase(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.rate_review, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text(
                        "${spot.reviews.length} avis",
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tourisme': return Icons.camera_alt;
      case 'Business': return Icons.business_center;
      case 'Shopping': return Icons.shopping_bag;
      case 'Nightlife': return Icons.local_bar;
      case 'Transport': return Icons.directions_subway;
      default: return Icons.place;
    }
  }
}

// --- User Review Card ---
class _UserReviewCard extends StatefulWidget {
  final _UserReviewWithSpot item;
  const _UserReviewCard({required this.item});

  @override
  State<_UserReviewCard> createState() => _UserReviewCardState();
}

class _UserReviewCardState extends State<_UserReviewCard> {
  bool _isExpanded = false;
  static const int _maxChars = 100;

  @override
  Widget build(BuildContext context) {
    final r = widget.item.review;
    final spot = widget.item.spot;
    final comment = r.comment;
    final isLong = comment.length > _maxChars;
    final displayText = (!_isExpanded && isLong) ? '${comment.substring(0, _maxChars)}...' : comment;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getCategoryIcon(spot.category), size: 16, color: const Color(0xFF00C853)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spot.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text(spot.category.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1)),

          const SizedBox(height: 12),
          _buildMiniCriteriaRow(r),

          const SizedBox(height: 12),
          Text(displayText, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),

          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _isExpanded ? "Réduire" : "Lire la suite",
                  style: const TextStyle(color: Color(0xFF00C853), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.white38),
              const SizedBox(width: 4),
              Text(_formatDate(r.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCriteriaRow(Review r) {
    return Row(
      children: [
        _buildMiniCriteria(Icons.attach_money, r.ratingRevenue),
        const SizedBox(width: 10),
        _buildMiniCriteria(Icons.lock_outline, r.ratingSecurity),
        const SizedBox(width: 10),
        _buildMiniCriteria(Icons.directions_walk, r.ratingTraffic),
      ],
    );
  }

  Widget _buildMiniCriteria(IconData icon, double score) {
    final color = _getGraduatedColor(score);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.white54),
            const SizedBox(width: 4),
            Text(score.toStringAsFixed(1), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return "Il y a ${diff.inMinutes} min";
      return "Il y a ${diff.inHours}h";
    } else if (diff.inDays == 1) return "Hier";
    else if (diff.inDays < 7) return "Il y a ${diff.inDays} jours";
    return "${date.day}/${date.month}/${date.year}";
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tourisme': return Icons.camera_alt;
      case 'Business': return Icons.business_center;
      case 'Shopping': return Icons.shopping_bag;
      case 'Nightlife': return Icons.local_bar;
      case 'Transport': return Icons.directions_subway;
      default: return Icons.place;
    }
  }
}