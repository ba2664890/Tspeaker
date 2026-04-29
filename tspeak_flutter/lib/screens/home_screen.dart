import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/top_app_bar.dart';
import '../widgets/patterns_painter.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as models;
import 'catalogue_screen.dart';
import 'classement_screen.dart';
import 'profil_screen.dart';
import 'session_vocale_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(onTabChange: _handleTabChange),
      const CatalogueScreen(),
      const SessionVocaleScreen(),
      const ClassementScreen(),
      const ProfilScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleTabChange,
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              height: 72,
              width: 72,
              margin: const EdgeInsets.only(bottom: 15),
              child: FloatingActionButton(
                onPressed: () => _handleTabChange(2),
                backgroundColor: AppColors.primary,
                elevation: 12,
                shape: const CircleBorder(),
                child: const Icon(Icons.mic, color: Colors.white, size: 36),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int) onTabChange;
  const HomeContent({super.key, required this.onTabChange});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<models.User> _userFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _userFuture = context.read<UserService>().getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState();
        }

        final user = snapshot.data!;

        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => widget.onTabChange(4), // Profile tab
                        child: Row(
                          children: [
                            _buildProfileAvatar(user),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour,',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurface.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${user.firstName} 👋',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildNotificationBell(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStreakCard(user.streak),
                    const SizedBox(height: 16),
                    _buildXPProgressCard(user.xp, user.xpToNextLevel, user.level),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Continue ta session', 
                      onAction: () => widget.onTabChange(1), // Catalogue tab
                    ),
                    const SizedBox(height: 16),
                    _buildContinueCard(),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Sessions recommandées',
                      onAction: () => widget.onTabChange(1), // Catalogue tab
                    ),
                    const SizedBox(height: 16),
                    _buildRecommendedList(),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(models.User user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            image: user.avatarUrl.isNotEmpty 
              ? DecorationImage(image: NetworkImage(user.avatarUrl), fit: BoxFit.cover)
              : const DecorationImage(image: AssetImage('assets/images/placeholder_avatar.png'), fit: BoxFit.cover),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -4,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                'LVL ${user.level}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.onSurface.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pas de nouvelles notifications pour le moment.')),
          );
        },
        icon: const Icon(Icons.notifications, color: AppColors.onSurface, size: 24),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A50), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.local_fire_department,
              size: 140,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SÉRIE ACTUELLE',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 8),
                  Text(
                    '$streak jours consécutifs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Tu es en feu ! Continue comme ça pour atteindre ton objectif hebdo.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgressCard(int xp, int target, int level) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Points d’expérience',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Spacer(),
              Text(
                '$xp / $target',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const Text(' XP', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: xp / target,
              minHeight: 12,
              backgroundColor: AppColors.onSurface.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'Encore ${target - xp} XP pour passer au Niveau ${level + 1}',
                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinueCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF00BFA5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  bottomLeft: Radius.circular(32),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB2EBF2).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.record_voice_over, color: Color(0xFF00838F), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MODULE 4 • CONVERSATION',
                                style: TextStyle(
                                  color: Color(0xFF00BFA5),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Commander au restaurant en Wolof',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Dernière étape : Maîtriser les formules de politesse.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => widget.onTabChange(2), // Session tab
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reprendre',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedList() {
    return SizedBox(
      height: 280,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSessionCard('Négocier au marché', '12 MIN', 'A1', 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=400&h=300&fit=crop'),
          const SizedBox(width: 20),
          _buildSessionCard('Salutations', '15 MIN', 'A1', 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400&h=300&fit=crop'),
        ],
      ),
    );
  }

  Widget _buildSessionCard(String title, String duration, String level, String img) {
    return GestureDetector(
      onTap: () => widget.onTabChange(2), // Session tab
      child: Container(
        width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(img, height: 140, width: 240, fit: BoxFit.cover),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(duration, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                const Text(
                  'Apprends l’art de la négociation et les chiffres usuels.',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.orange.shade100,
                      child: Text(level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFFE0F2F1),
                      child: Icon(Icons.mic, size: 14, color: Color(0xFF00897B)),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Erreur de chargement'),
          ElevatedButton(onPressed: _refreshData, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
