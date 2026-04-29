import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/patterns_painter.dart';
import '../widgets/top_app_bar.dart';

class ClassementScreen extends StatefulWidget {
  const ClassementScreen({super.key});

  @override
  State<ClassementScreen> createState() => _ClassementScreenState();
}

class _ClassementScreenState extends State<ClassementScreen> {
  String _selectedTab = 'Hebdomadaire';

  final List<Map<String, dynamic>> _leaderboard = [
    {
      'rank': 2,
      'name': 'Kwame O.',
      'xp': 9420,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    },
    {
      'rank': 1,
      'name': 'Zainab L.',
      'xp': 12850,
      'avatar': 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200',
    },
    {
      'rank': 3,
      'name': 'Jabari W.',
      'xp': 8910,
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    },
  ];

  final List<Map<String, dynamic>> _listItems = [
    {'rank': 4, 'name': 'Chidi M.', 'xp': 7420, 'avatar': 'https://images.unsplash.com/photo-1463453091185-61582044d556?w=200', 'league': 'Expert'},
    {'rank': 5, 'name': 'Nala S.', 'xp': 6890, 'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 'league': 'Expert'},
    {'rank': 14, 'name': 'Amara K. (Toi)', 'xp': 4120, 'avatar': 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200', 'league': 'Pionnier', 'isCurrentUser': true},
    {'rank': 15, 'name': 'Yara T.', 'xp': 3950, 'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200', 'league': 'Pionnier'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: TopAppBar(
                showLogo: true,
                actions: [
                  IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(backgroundColor: Colors.white, shape: const CircleBorder()),
                    icon: const Icon(Icons.share_rounded, color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: ['Hebdomadaire', 'Global'].map((tab) {
                      final isSelected = tab == _selectedTab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = tab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tab,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPodiumItem(_leaderboard[0], 110, AppColors.secondary),
                    const SizedBox(width: 16),
                    _buildPodiumItem(_leaderboard[1], 150, AppColors.primary, isWinner: true),
                    const SizedBox(width: 16),
                    _buildPodiumItem(_leaderboard[2], 90, AppColors.tertiary),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildListItem(_listItems[index]),
                  childCount: _listItems.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, double height, Color color, {bool isWinner = false}) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: isWinner ? 80 : 64,
                height: isWinner ? 80 : 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isWinner ? 4 : 2),
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(backgroundImage: NetworkImage(user['avatar'])),
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Text('${user['rank']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user['xp'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SpaceMono')),
                const Text('XP', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'SpaceMono')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(user['name'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    final isUser = item['isCurrentUser'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isUser ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(item['rank'].toString().padLeft(2, '0'), style: TextStyle(fontFamily: 'SpaceMono', fontWeight: FontWeight.bold, color: isUser ? AppColors.primary : AppColors.onSurface.withOpacity(0.3))),
          ),
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(item['avatar'])),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(item['league'].toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: isUser ? AppColors.primary : AppColors.onSurface.withOpacity(0.4), fontFamily: 'SpaceMono')),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item['xp'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'SpaceMono')),
              const Text('XP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
            ],
          ),
        ],
      ),
    );
  }
}
