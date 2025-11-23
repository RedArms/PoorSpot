import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/current_session.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _api = ApiService();
  
  // États
  String _selectedPeriod = "forever"; // daily, weekly, monthly, forever
  String _sortBy = "points"; // 'points' (défaut) ou 'time'
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  // Configuration des filtres
  final List<String> _periods = ["daily", "weekly", "monthly", "forever"];
  final Map<String, String> _periodLabels = {
    "daily": "24H",
    "weekly": "7 JOURS",
    "monthly": "30 JOURS",
    "forever": "TOUJOURS"
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // On appelle l'API avec la période et le mode de tri
    final data = await _api.fetchLeaderboard(_selectedPeriod, _sortBy);
    if (mounted) {
      setState(() {
        _users = data;
        _isLoading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("CLASSEMENT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- TOGGLE TYPE (Points vs Temps) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Container(
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  _buildToggleBtn("POINTS", "points"),
                  _buildToggleBtn("TEMPS", "time"),
                ],
              ),
            ),
          ),

          // --- FILTRES (Seulement si Temps, car Points c'est global) ---
          // On cache les filtres de temps si on est en mode Points pour simplifier l'interface
          if (_sortBy == "time")
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final p = _periods[index];
                  final isSelected = _selectedPeriod == p;
                  return GestureDetector(
                    onTap: () => _onPeriodChanged(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00C853) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF00C853) : Colors.white10),
                      ),
                      child: Text(
                        _periodLabels[p]!,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
              : _users.isEmpty 
                ? _buildEmptyState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, String value) {
    final isSelected = _sortBy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { 
          if (_sortBy != value) {
            setState(() => _sortBy = value); 
            _loadData(); 
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label, 
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54, 
              fontWeight: FontWeight.bold
            )
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          const Text("Personne n'est classé ici...", style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 5),
          const Text("Sois le premier !", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final top3 = _users.take(3).toList();
    final rest = _users.length > 3 ? _users.sublist(3) : <Map<String, dynamic>>[];

    return CustomScrollView(
      slivers: [
        // --- PODIUM ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top3.length >= 2) _buildPodiumItem(top3[1], 2, 140, const Color(0xFFC0C0C0)), // Silver
                if (top3.isNotEmpty) _buildPodiumItem(top3[0], 1, 180, const Color(0xFFFFD700)), // Gold
                if (top3.length >= 3) _buildPodiumItem(top3[2], 3, 120, const Color(0xFFCD7F32)), // Bronze
              ],
            ),
          ),
        ),

        // --- LISTE ---
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = rest[index];
              final rank = index + 4;
              final isMe = user['userId'] == CurrentSession().user?.id;
              final score = user['score'] as int;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF00C853).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isMe ? Border.all(color: const Color(0xFF00C853).withOpacity(0.5)) : null,
                ),
                child: Row(
                  children: [
                    Text(
                      "#$rank",
                      style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 15),
                    CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Text(user['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isMe) const Text("C'est vous !", style: TextStyle(color: Color(0xFF00C853), fontSize: 10)),
                        ],
                      ),
                    ),
                    _buildScoreBadge(score),
                  ],
                ),
              );
            },
            childCount: rest.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double height, Color color) {
    final isMe = user['userId'] == CurrentSession().user?.id;
    final score = user['score'] as int;
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                child: CircleAvatar(
                  radius: rank == 1 ? 35 : 25,
                  backgroundColor: Colors.white10,
                  child: Text(user['name'][0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: rank == 1 ? 24 : 18, fontWeight: FontWeight.bold)),
                ),
              ),
              if (rank == 1) 
                const Positioned(
                  right: 0,
                  child: Icon(Icons.verified, color: Color(0xFF00C853), size: 20),
                )
            ],
          ),
          const SizedBox(height: 8),
          
          // Name
          Text(
            user['name'], 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis, 
            style: TextStyle(color: isMe ? const Color(0xFF00C853) : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
          ),
          const SizedBox(height: 4),
          
          // Score / Time Badge
          _buildScoreBadge(score),
          
          const SizedBox(height: 10),
          
          // Bar
          Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.8), color.withOpacity(0.3)]
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)]
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text("$rank", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 40, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    if (_sortBy == "time") {
      // Mode Temps
      return _buildTimeBadgeDisplay(score);
    } else {
      // Mode Points
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber),
        ),
        child: Text(
          "$score pts", 
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)
        ),
      );
    }
  }

  Widget _buildTimeBadgeDisplay(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    String text;
    if (h > 0) text = "${h}h ${m}m";
    else text = "${m} min";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 10, color: Color(0xFF00C853)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}