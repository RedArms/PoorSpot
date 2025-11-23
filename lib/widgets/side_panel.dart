import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // N'oubliez pas le pub add url_launcher
import '../models/spot_models.dart';
import '../models/user_model.dart';
import '../data/current_session.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart'; // <--- AJOUT

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

  // --- NOUVEAU : Ouvre le GPS ---
  Future<void> _launchGPS() async {
    final lat = widget.spot.position.latitude;
    final lng = widget.spot.position.longitude;
    
    // Essaye d'ouvrir Google Maps ou l'app par défaut
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir le GPS")));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final user = CurrentSession().user;
    if (user == null || user.history.isEmpty) return;

    try {
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
      // Pas de log trouvé
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
  if (user == null) {
    _showError("Connectez-vous pour pointer");
    return;
  }

  // TOUJOURS activer le loading en premier (même pour libérer !)
  setState(() => _isLoadingOccupation = true);

  try {
    // === 1. Vérification GPS UNIQUEMENT si on veut OCCUPER (pas libérer) ===
    if (!_isOccupiedByMe) {
      bool canProceed = false;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          _showError("Localisation refusée dans les paramètres");
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          widget.spot.position.latitude,
          widget.spot.position.longitude,
        );

        if (distance > 300) {
          _showError("Trop loin ! ${distance.toStringAsFixed(0)} m (max 300 m)");
          return;
        }

        canProceed = true;
      } catch (e) {
        _showError("Impossible d'accéder au GPS");
        return;
      }

      if (!canProceed) return;
    }

    // === 2. Action : OCCUPER ou LIBÉRER ===
    if (_isOccupiedByMe) {
      // ─────────── LIBÉRATION ───────────
      final result = await _api.releaseSpotFull(widget.spot.id, user.id);

      if (!mounted) return;

      // Mise à jour durée du log en cours
      final duration = result['duration'] as int?;
      if (duration != null) {
        try {
          final logToUpdate = user.history.firstWhere(
            (log) => log.spotId == widget.spot.id && log.durationSeconds == 0,
          );
          logToUpdate.durationSeconds = duration;
        } catch (_) {}
      }

      // Mise à jour points + badges
      final totalPoints = result['total_points'] as int?;
      if (totalPoints != null) user.points = totalPoints;

      final newBadges = result['new_achievements'] as List<dynamic>?;
      if (newBadges != null && newBadges.isNotEmpty) {
        for (var b in newBadges) {
          final badgeId = b['id']?.toString();
          if (badgeId != null && !user.achievements.contains(badgeId)) {
            user.achievements.add(badgeId);
          }
          _showAchievementSnack(b['name'] ?? "Succès", b['points'] ?? 0);
        }
      }

      // UI + timer
      setState(() {
        _occupationInfo = null;
      });
      _stopTimer();
      widget.onHistoryChanged?.call();

    } else {
      // ─────────── OCCUPATION ───────────
      final success = await _api.occupySpot(widget.spot.id, user.id);

      if (!mounted) return;

      if (success) {
        // Nettoyage des anciens logs "en cours" (évite les bugs d'affichage)
        for (var log in user.history) {
          if (log.durationSeconds == 0) {
            final approxDuration = DateTime.now().difference(log.timestamp).inSeconds;
            log.durationSeconds = approxDuration > 0 ? approxDuration : 1;
          }
        }

        // Ajout du nouveau log
        user.history.insert(0, CheckInLog(
          spotId: widget.spot.id,
          spotName: widget.spot.name,
          timestamp: DateTime.now(),
          durationSeconds: 0,
        ));

        setState(() {
          _occupationInfo = {
            "userId": user.id,
            "userName": user.name,
          };
        });

        _startTimer();
        widget.onHistoryChanged?.call();
      } else {
        _showError("Spot déjà pris par quelqu’un d’autre");
        await _checkOccupation(); // refresh forcé
      }
    }
  } catch (e) {
    if (mounted) {
      _showError("Erreur réseau ou serveur");
      await _checkOccupation();
    }
  } finally {
    if (mounted) {
      setState(() => _isLoadingOccupation = false);
    }
  }
}

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 10), Text(msg)]),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      )
    );
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
                        const SizedBox(height: 15),
                        // --- NOUVEAU BOUTON GPS ---
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _launchGPS,
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text("Y ALLER (GPS)", style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
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