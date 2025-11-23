import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/spot_models.dart';
import '../models/user_model.dart';
import '../data/current_session.dart';
import '../services/api_service.dart';

class SidePanel extends StatefulWidget {
  final Spot spot;
  final VoidCallback onClose;
  final VoidCallback onAddReview;
  final VoidCallback onFavoriteChanged;
  final VoidCallback? onHistoryChanged;

  const SidePanel({
    super.key, 
    required this.spot, 
    required this.onClose,
    required this.onAddReview,
    required this.onFavoriteChanged,
    this.onHistoryChanged,
  });

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  final ApiService _api = ApiService();
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;

  // États pour l'occupation
  bool _isLoadingOccupation = true;
  Map<String, dynamic>? _occupationInfo; 
  
  bool get _isOccupied => _occupationInfo != null;
  bool get _isOccupiedByMe => _occupationInfo != null && _occupationInfo!['userId'] == CurrentSession().user?.id;
  
  Timer? _timer;
  String _elapsedTime = "00:00:00";

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    if (CurrentSession().isLoggedIn) {
      _checkOccupation();
    } else {
      _isLoadingOccupation = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spot.id != widget.spot.id) {
      _timer?.cancel();
      _elapsedTime = "00:00:00";
      _checkFavorite();
      if (CurrentSession().isLoggedIn) {
        _checkOccupation();
      } else {
        setState(() { _occupationInfo = null; _isLoadingOccupation = false; });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final user = CurrentSession().user;
    if (user == null || user.history.isEmpty) return;

    // On cherche le log actif correspondant au spot
    try {
      // On prend le premier qui match le spotId et qui n'a pas de durée finale
      final currentLog = user.history.firstWhere(
        (log) => log.spotId == widget.spot.id && log.durationSeconds == 0,
        orElse: () => user.history.first
      );
      
      final startTime = currentLog.timestamp;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final duration = now.difference(startTime);
        final h = duration.inHours.toString().padLeft(2, '0');
        final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) {
          setState(() {
            _elapsedTime = "$h:$m:$s";
          });
        }
      });
    } catch (e) {
      // Pas de log trouvé, pas grave
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() { _elapsedTime = "00:00:00"; });
  }

  void _checkFavorite() {
    final user = CurrentSession().user;
    if (user != null) {
      setState(() {
        _isFavorite = user.favorites.contains(widget.spot.id);
      });
    }
  }

  Future<void> _checkOccupation() async {
    setState(() => _isLoadingOccupation = true);
    final occupations = await _api.fetchOccupations();
    if (mounted) {
      setState(() {
        _occupationInfo = occupations[widget.spot.id];
        _isLoadingOccupation = false;
        
        if (_isOccupiedByMe) {
          _startTimer();
        } else {
          _stopTimer();
        }
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = CurrentSession().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connectez-vous pour ajouter aux favoris")));
      return;
    }
    setState(() => _isTogglingFavorite = true);
    bool success;
    if (_isFavorite) {
      success = await _api.removeFavorite(user.id, widget.spot.id);
      if (success) user.favorites.remove(widget.spot.id);
    } else {
      success = await _api.addFavorite(user.id, widget.spot.id);
      if (success) user.favorites.add(widget.spot.id);
    }
    setState(() {
      _isTogglingFavorite = false;
      if (success) _isFavorite = !_isFavorite;
    });
    widget.onFavoriteChanged();
  }

  Future<void> _toggleOccupation() async {
    final user = CurrentSession().user;
    if (user == null) return;

    setState(() => _isLoadingOccupation = true);

if (_isOccupiedByMe) {
      // --- LIBÉRATION ---
      // On utilise la version Full pour récupérer les achievements
      final result = await _api.releaseSpotFull(widget.spot.id, user.id);
      
      final duration = result['duration'] as int?;
      final newBadges = result['new_achievements'] as List<dynamic>?;
      final totalPoints = result['total_points'] as int?;

      if (duration != null) {
        // Update Time
        try {
          final logToUpdate = user.history.firstWhere((log) => log.spotId == widget.spot.id && log.durationSeconds == 0);
          logToUpdate.durationSeconds = duration;
        } catch (e) {}
      }
      
      // Update Points
      if (totalPoints != null) user.points = totalPoints;

      // NOTIFICATION SUCCÈS !
      if (newBadges != null && newBadges.isNotEmpty) {
        for (var b in newBadges) {
          user.achievements.add(b['id']); // Update local
          _showAchievementSnack(b['name'], b['points']);
        }
      }

      setState(() { _occupationInfo = null; });
      _stopTimer();
      if (widget.onHistoryChanged != null) widget.onHistoryChanged!();

    } else {
      // OCCUPER (NOUVEAU SPOT)
      final success = await _api.occupySpot(widget.spot.id, user.id);
      
      if (success) {
        setState(() { 
          _occupationInfo = { "userId": user.id, "userName": user.name }; 
        });
        
        // --- CORRECTION ICI : Nettoyage local de l'historique ---
        // Avant d'ajouter le nouveau, on cherche s'il y avait un log "En cours" d'un AUTRE spot
        // et on le ferme artificiellement pour l'UI (le backend a calculé la vraie durée, 
        // ici on met une approx pour que ça ne reste pas "En cours" visuellement).
        for (var log in user.history) {
          if (log.durationSeconds == 0) {
            final start = log.timestamp;
            final now = DateTime.now();
            // On met la différence
            log.durationSeconds = now.difference(start).inSeconds;
            // Si la diff est 0 (trop rapide), on met 1s pour ne pas qu'il reste "En cours"
            if (log.durationSeconds == 0) log.durationSeconds = 1;
          }
        }

        // Ajout du nouveau log
        user.history.insert(0, CheckInLog(
          spotId: widget.spot.id, 
          spotName: widget.spot.name, 
          timestamp: DateTime.now()
        ));
        
        _startTimer();
        if (widget.onHistoryChanged != null) widget.onHistoryChanged!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible : Déjà pris !")));
        _checkOccupation();
      }
    }
    setState(() => _isLoadingOccupation = false);
  }

void _showAchievementSnack(String name, int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber[700],
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("SUCCÈS DÉBLOQUÉ !", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Text("$name (+$points pts)", style: const TextStyle(color: Colors.black87)),
                ],
              ),
            )
          ],
        ),
        behavior: SnackBarBehavior.floating,
      )
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = CurrentSession().user;
    final globalRating = widget.spot.globalRating;
    final themeColor = _getGraduatedColor(globalRating);
    final advice = widget.spot.getSmartAdvice(user?.attributes ?? []);
    
    return SafeArea(
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.98),
              border: Border(left: BorderSide(color: themeColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.spot.name, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(_getCategoryIcon(widget.spot.category), color: Colors.grey, size: 14),
                                const SizedBox(width: 6),
                                Text(widget.spot.category.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isTogglingFavorite
                            ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)))
                            : IconButton(
                                icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: _isFavorite ? Colors.amber : Colors.white54),
                                onPressed: _toggleFavorite,
                              ),
                          IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: widget.onClose),
                        ],
                      ),
                    ],
                  ),
                ),

                // STATUS
                if (user != null) _buildOccupationStatus(),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 20),
                      
                      if (user != null) ...[
                        _buildOccupationButton(),
                        const SizedBox(height: 30),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(globalRating.toStringAsFixed(1), style: TextStyle(color: themeColor, fontSize: 48, fontWeight: FontWeight.bold, height: 1)),
                          const Padding(padding: EdgeInsets.only(bottom: 8.0, left: 4), child: Text("/ 5", style: TextStyle(color: Colors.grey, fontSize: 16))),
                        ],
                      ),
                      const Center(child: Text("NOTE GLOBALE", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2))),
                      
                      const SizedBox(height: 30),
                      _buildCriteriaRow("REVENU", widget.spot.avgRevenue, Icons.attach_money),
                      const SizedBox(height: 15),
                      _buildCriteriaRow("SÉCURITÉ", widget.spot.avgSecurity, Icons.lock_outline),
                      const SizedBox(height: 15),
                      _buildCriteriaRow("PASSAGE", widget.spot.avgTraffic, Icons.directions_walk),

                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [Icon(Icons.info_outline, size: 16, color: Colors.white70), SizedBox(width: 8), Text("CONSEIL DU RÉSEAU", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))]),
                            const SizedBox(height: 8),
                            Text(advice, style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Text("DERNIERS AVIS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...widget.spot.reviews.map((r) => _ReviewCard(review: r)),
                      
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onAddReview, 
                          icon: const Icon(Icons.add_chart, color: Colors.black),
                          label: const Text("DONNER SON AVIS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccupationStatus() {
    if (_isLoadingOccupation) return const LinearProgressIndicator(minHeight: 2, color: Color(0xFF00C853));

    final isFree = !_isOccupied;
    final statusColor = isFree ? const Color(0xFF00C853) : (_isOccupiedByMe ? Colors.blue : Colors.redAccent);
    String statusText;
    
    if (isFree) {
      statusText = "LIBRE";
    } else if (_isOccupiedByMe) {
      statusText = "VOUS OCCUPEZ ($_elapsedTime)";
    } else {
      final occupantName = _occupationInfo?['userName'] ?? "QUELQU'UN";
      statusText = "OCCUPÉ PAR ${occupantName.toUpperCase()}";
    }

    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: statusColor.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          ),
          if (!isFree && !_isOccupiedByMe)
            const Text("Indisponible", style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic))
        ],
      ),
    );
  }

  Widget _buildOccupationButton() {
    final isFree = !_isOccupied;
    
    if (!isFree && !_isOccupiedByMe) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null, 
          icon: const Icon(Icons.block),
          label: const Text("ZONE INDISPONIBLE"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.grey, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoadingOccupation ? null : _toggleOccupation,
        icon: Icon(_isOccupiedByMe ? Icons.timer_off : Icons.timer),
        label: Text(_isOccupiedByMe ? "FIN DE SESSION" : "SE POINTER ICI (START CHRONO)"),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isOccupiedByMe ? Colors.redAccent.withOpacity(0.2) : const Color(0xFF00C853).withOpacity(0.2),
          foregroundColor: _isOccupiedByMe ? Colors.redAccent : const Color(0xFF00C853),
          side: BorderSide(color: _isOccupiedByMe ? Colors.redAccent : const Color(0xFF00C853)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String label, double score, IconData icon) {
    final color = _getGraduatedColor(score);
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: Colors.white70), const SizedBox(width: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 6),
      Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: score / 5.0, backgroundColor: Colors.white10, color: color, minHeight: 6))), const SizedBox(width: 8), SizedBox(width: 30, child: Text(score.toStringAsFixed(1), textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))])
    ]);
  }

  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
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

class _ReviewCard extends StatefulWidget {
  final Review review;
  const _ReviewCard({required this.review});
  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isExpanded = false;
  static const int _maxChars = 150;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final comment = r.comment;
    final isLong = comment.length > _maxChars;
    final displayText = (!_isExpanded && isLong) ? '${comment.substring(0, _maxChars)}...' : comment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.person_outline, size: 14, color: Colors.white54), const SizedBox(width: 4), Text(r.authorName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text(_getAttributeName(r.attribute), style: const TextStyle(color: Color(0xFF00C853), fontSize: 9, fontWeight: FontWeight.bold)))]),
            const SizedBox(height: 8),
            _buildMiniCriteriaRow(r),
            const SizedBox(height: 10),
            Text(displayText, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            if (isLong) GestureDetector(onTap: () => setState(() => _isExpanded = !_isExpanded), child: Padding(padding: const EdgeInsets.only(top: 6), child: Text(_isExpanded ? "Réduire" : "Lire la suite", style: const TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.w600)))),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCriteriaRow(Review r) {
    return Row(children: [_buildMiniCriteria(Icons.attach_money, r.ratingRevenue), const SizedBox(width: 12), _buildMiniCriteria(Icons.lock_outline, r.ratingSecurity), const SizedBox(width: 12), _buildMiniCriteria(Icons.directions_walk, r.ratingTraffic)]);
  }

  Widget _buildMiniCriteria(IconData icon, double score) {
    final color = _getGraduatedColor(score);
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.white38), const SizedBox(width: 3), Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: score / 5.0, child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))))), const SizedBox(width: 4), Text(score.toStringAsFixed(0), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))]);
  }

  Color _getGraduatedColor(double rating) {
    double t = (rating / 5.0).clamp(0.0, 1.0);
    if (t < 0.5) return Color.lerp(const Color(0xFFFF3D00), const Color(0xFFFFEA00), t * 2)!;
    return Color.lerp(const Color(0xFFFFEA00), const Color(0xFF00C853), (t - 0.5) * 2)!;
  }

  String _getAttributeName(BeggarAttribute attr) {
    switch (attr) {
      case BeggarAttribute.dog: return "Chien";
      case BeggarAttribute.music: return "Musique";
      case BeggarAttribute.circus: return "Cirque";
      case BeggarAttribute.disability: return "Handicap";
      case BeggarAttribute.family: return "Famille";
      default: return "Solo";
    }
  }
}