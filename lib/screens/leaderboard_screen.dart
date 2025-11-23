import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../data/current_session.dart';
import '../models/user_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  // LEADERBOARD STATE
  String _selectedPeriod = "forever"; 
  String _sortBy = "points"; 
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingLeaderboard = true;

  // ACHIEVEMENTS STATE
  List<AchievementDef> _allAchievements = [];
  bool _isLoadingAchievements = true;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboard();
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoadingLeaderboard = true);
    final data = await _api.fetchLeaderboard(_selectedPeriod, _sortBy);
    if (mounted) {
      setState(() {
        _users = data;
        _isLoadingLeaderboard = false;
      });
    }
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoadingAchievements = true);
    final data = await _api.fetchAllAchievements();
    if (mounted) {
      setState(() {
        _allAchievements = data;
        _isLoadingAchievements = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Text("CLASSEMENT & SUCCÈS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00C853),
          labelColor: const Color(0xFF00C853),
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "CLASSEMENT"),
            Tab(text: "LISTE DES SUCCÈS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  // --- TAB 1: LEADERBOARD ---
  Widget _buildLeaderboardTab() {
    return Column(
      children: [
        const SizedBox(height: 10),
        // SWITCH MODE (Points vs Temps)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                _buildToggleBtn("POINTS", "points"),
                _buildToggleBtn("TEMPS", "time"),
              ],
            ),
          ),
        ),

        // FILTRES (Uniquement pour le temps)
        if (_sortBy == "time")
          Container(
            height: 40,
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
                      color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFF00C853) : Colors.white24),
                    ),
                    child: Text(
                      _periodLabels[p]!,
                      style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                );
              },
            ),
          ),

        Expanded(
          child: _isLoadingLeaderboard
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
            : _users.isEmpty 
              ? _buildEmptyState("Personne n'est classé ici...")
              : _buildLeaderboardList(),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    final top3 = _users.take(3).toList();
    final rest = _users.length > 3 ? _users.sublist(3) : <Map<String, dynamic>>[];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: SizedBox(
              height: 200, // Hauteur fixe pour éviter l'overflow
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (top3.length >= 2) _buildPodiumItem(top3[1], 2, 120, const Color(0xFFC0C0C0)),
                  if (top3.isNotEmpty) _buildPodiumItem(top3[0], 1, 160, const Color(0xFFFFD700)),
                  if (top3.length >= 3) _buildPodiumItem(top3[2], 3, 90, const Color(0xFFCD7F32)),
                ],
              ),
            ),
          ),
        ),
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
                    SizedBox(width: 30, child: Text("#$rank", style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 14))),
                    CircleAvatar(
                      radius: 18, backgroundColor: Colors.white10,
                      child: Text(user['name'].isNotEmpty ? user['name'][0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

  // --- TAB 2: ACHIEVEMENTS LIST ---
  Widget _buildAchievementsTab() {
    if (_isLoadingAchievements) return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
    if (_allAchievements.isEmpty) return _buildEmptyState("Aucun succès disponible");

    final userAchievements = CurrentSession().user?.achievements ?? [];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _allAchievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final def = _allAchievements[index];
        final isUnlocked = userAchievements.contains(def.id);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFF00C853).withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? const Color(0xFF00C853).withOpacity(0.5) : Colors.white10
            ),
          ),
          child: Row(
            children: [
              // ICONE
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFF00C853).withOpacity(0.2) : Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(def.icon), 
                  color: isUnlocked ? const Color(0xFF00C853) : Colors.white24,
                  size: 24
                ),
              ),
              const SizedBox(width: 16),
              // TEXTES
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name.toUpperCase(),
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      def.desc,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white70 : Colors.white24,
                        fontSize: 12
                      ),
                    ),
                  ],
                ),
              ),
              // POINTS
              Column(
                children: [
                  Text(
                    "+${def.points}",
                    style: TextStyle(
                      color: isUnlocked ? const Color(0xFFFFD700) : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                  Text("PTS", style: TextStyle(color: isUnlocked ? const Color(0xFFFFD700) : Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // --- HELPERS ---

  Widget _buildToggleBtn(String label, String value) {
    final isSelected = _sortBy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { 
          if (_sortBy != value) {
            setState(() => _sortBy = value); 
            _loadLeaderboard(); 
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(msg, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double height, Color color) {
    final isMe = user['userId'] == CurrentSession().user?.id;
    final score = user['score'] as int;
    
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                child: CircleAvatar(
                  radius: rank == 1 ? 30 : 22, backgroundColor: Colors.white10,
                  child: Text(user['name'].isNotEmpty ? user['name'][0].toUpperCase() : "?", style: TextStyle(color: Colors.white, fontSize: rank == 1 ? 20 : 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (rank == 1) const Positioned(right: -5, top: -5, child: Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24))
            ],
          ),
          const SizedBox(height: 8),
          Text(user['name'], maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: isMe ? const Color(0xFF00C853) : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          _buildScoreBadge(score, small: true),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, height: height, margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.4), color.withOpacity(0.1)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(top: BorderSide(color: color.withOpacity(0.5), width: 2)),
            ),
            child: Column(children: [const SizedBox(height: 10), Text("$rank", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 32, fontWeight: FontWeight.bold))]),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score, {bool small = false}) {
    if (_sortBy == "time") {
      final h = score ~/ 3600;
      final m = (score % 3600) ~/ 60;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer, size: small ? 10 : 12, color: const Color(0xFF00C853)), const SizedBox(width: 4),
          Text(h > 0 ? "${h}h ${m.toString().padLeft(2,'0')}" : "${m}m", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: small ? 10 : 12)),
        ]),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.6))),
        child: Text("$score pts", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: small ? 10 : 12)),
      );
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'footprint': return Icons.directions_walk;
      case 'compass': return Icons.explore;
      case 'map': return Icons.map;
      case 'public': return Icons.public;
      case 'category': return Icons.category;
      case 'hourglass_bottom': return Icons.hourglass_bottom;
      case 'hourglass_top': return Icons.hourglass_top;
      case 'hourglass_full': return Icons.hourglass_full;
      case 'history': return Icons.history;
      case 'infinity': return Icons.all_inclusive;
      case 'fire': return Icons.local_fire_department;
      case 'bedtime': return Icons.bedtime;
      case 'sunny': return Icons.wb_sunny;
      case 'restaurant': return Icons.restaurant;
      case 'weekend': return Icons.weekend;
      case 'business_center': return Icons.business_center;
      case 'camera_alt': return Icons.camera_alt;
      case 'celebration': return Icons.celebration;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'train': return Icons.train;
      case 'add_location': return Icons.add_location_alt;
      case 'domain': return Icons.domain;
      case 'rate_review': return Icons.rate_review;
      case 'campaign': return Icons.campaign;
      case 'home': return Icons.home;
      case 'timer': return Icons.timer;
      case 'bolt': return Icons.bolt;
      case 'attach_money': return Icons.attach_money;
      case 'shield': return Icons.shield;
      case 'groups': return Icons.groups;
      case 'waving_hand': return Icons.waving_hand;
      case 'hourglass_empty': return Icons.hourglass_empty;
      // Icons ajoutées pour les nouveaux succès
      case 'school': return Icons.school;
      case 'park': return Icons.park;
      case 'storefront': return Icons.storefront;
      case 'local_activity': return Icons.local_activity;
      case 'local_bar': return Icons.local_bar;
      case 'nights_stay': return Icons.nights_stay;
      case 'city': return Icons.location_city;
      case 'lock': return Icons.lock;
      case 'tent': return Icons.holiday_village;
      case 'flash_on': return Icons.flash_on;
      case 'star': return Icons.star;
      case 'warning': return Icons.warning;
      case 'skull': return Icons.dangerous;
      case 'visibility_off': return Icons.visibility_off;
      case 'nature_people': return Icons.nature_people;
      case 'diamond': return Icons.diamond;
      case 'money_off': return Icons.money_off;
      default: return Icons.emoji_events;
    }
  }
}