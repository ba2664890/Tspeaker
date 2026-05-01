import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/url_validator.dart';

class ClassementScreen extends StatefulWidget {
  const ClassementScreen({super.key});

  @override
  State<ClassementScreen> createState() => _ClassementScreenState();
}

class _ClassementScreenState extends State<ClassementScreen> {
  String _selectedScope = 'weekly';
  late Future<LeaderboardData> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _fetchLeaderboard();
  }

  Future<LeaderboardData> _fetchLeaderboard() {
    return context.read<UserService>().getLeaderboard(scope: _selectedScope);
  }

  Future<void> _refresh() async {
    final future = _fetchLeaderboard();
    setState(() {
      _leaderboardFuture = future;
    });
    await future;
  }

  void _changeScope(String scope) {
    if (_selectedScope == scope) return;
    setState(() {
      _selectedScope = scope;
      _leaderboardFuture = _fetchLeaderboard();
    });
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaderboardData>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState();
        }

        final data = snapshot.data!;
        final currentUser = data.currentUser;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              _buildAmbientBackground(),
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                          child: _buildTopBar(),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildScopeSelector(data.summary),
                          const SizedBox(height: 20),
                          _buildSeasonCard(data, currentUser),
                          const SizedBox(height: 20),
                          if (data.podium.isNotEmpty) ...[
                            _buildPodiumSection(data),
                            const SizedBox(height: 20),
                          ],
                          if (currentUser != null) ...[
                            _buildPersonalPositionSection(data),
                            const SizedBox(height: 20),
                          ],
                          _buildLeaderboardSection(data),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 18),
            Text(
              'Le classement se met à jour...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.leaderboard_outlined,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Impossible de charger les ranks',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Relance le chargement pour récupérer le podium et ta position.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.64),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            left: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: 180,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Row(
          children: [
            Image.asset('assets/images/logo.png', width: 34, height: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'T.Speak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  'Ranks & ligues',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _buildTopIconButton(
          icon: Icons.info_outline_rounded,
          onTap: () => _showInfoSnackBar(
            'Le classement hebdomadaire repose sur les XP gagnés sur les 7 derniers jours.',
          ),
        ),
        const SizedBox(width: 10),
        _buildTopIconButton(
          icon: Icons.share_rounded,
          onTap: () => _showInfoSnackBar(
            'Le partage du rang arrive bientôt.',
          ),
        ),
      ],
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.onSurface),
      ),
    );
  }

  Widget _buildScopeSelector(LeaderboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildScopeChip(
                  label: 'Hebdomadaire',
                  scope: 'weekly',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildScopeChip(
                  label: 'Global',
                  scope: 'global',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              summary.scopeDescription,
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip({
    required String label,
    required String scope,
  }) {
    final isSelected = _selectedScope == scope;

    return GestureDetector(
      onTap: () => _changeScope(scope),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonCard(
    LeaderboardData data,
    LeaderboardEntry? currentUser,
  ) {
    final summary = data.summary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101426),
            Color(0xFF24345C),
            Color(0xFFB24C17),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24345C).withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -25,
            bottom: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildHeroPill(
                    icon: Icons.workspace_premium_rounded,
                    label: summary.currentLeague,
                    color: Colors.white.withValues(alpha: 0.12),
                    textColor: Colors.white,
                  ),
                  const Spacer(),
                  _buildHeroPill(
                    icon: Icons.public_rounded,
                    label: summary.scopeLabel,
                    color: AppColors.secondary.withValues(alpha: 0.18),
                    textColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (currentUser != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: UrlValidator.getSafeImage(
                          currentUser.avatarUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rang #${currentUser.rank} • Top ${summary.userPercentile}%',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildHeroTag(
                                '${_formatNumber(summary.currentScore)} ${summary.scoreLabel}',
                              ),
                              _buildHeroTag(
                                '${_formatNumber(summary.currentTotalXp)} XP cumulés',
                              ),
                              _buildHeroTag(
                                '${currentUser.streakDays} jours de série',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Classement indisponible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.nextLeague.isNotEmpty
                          ? 'Progression vers ${summary.nextLeague}'
                          : 'Ligue maximale atteinte',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: summary.leagueProgress.clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFFC56B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      summary.nextLeague.isNotEmpty
                          ? 'Encore ${_formatNumber(summary.scoreToNextLeague)} XP pour atteindre ${summary.nextLeague}.'
                          : 'Tu es déjà dans la meilleure ligue disponible.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'Apprenants',
                        value: _formatNumber(summary.totalLearners),
                        icon: Icons.groups_rounded,
                      ),
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'Meilleur score',
                        value: _formatNumber(summary.topScore),
                        icon: Icons.trending_up_rounded,
                      ),
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'Meilleur streak',
                        value: '${summary.bestStreak}j',
                        icon: Icons.local_fire_department_rounded,
                      ),
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'Sessions actives',
                        value: currentUser != null
                            ? '${currentUser.sessionsCount}'
                            : '0',
                        icon: Icons.mic_external_on_rounded,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeroStatCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSection(LeaderboardData data) {
    final podium = data.podium;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'PODIUM',
            title: 'Les trois leaders du moment',
            subtitle:
                'Un aperçu immédiat des profils qui dominent actuellement la ligue.',
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: podium.length > 1
                    ? _buildPodiumItem(
                        podium[1],
                        height: 124,
                        color: AppColors.secondary,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: podium.isNotEmpty
                    ? _buildPodiumItem(
                        podium[0],
                        height: 156,
                        color: AppColors.primary,
                        isWinner: true,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: podium.length > 2
                    ? _buildPodiumItem(
                        podium[2],
                        height: 106,
                        color: AppColors.tertiary,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardEntry entry, {
    required double height,
    required Color color,
    bool isWinner = false,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: isWinner ? 84 : 70,
              height: isWinner ? 84 : 70,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: isWinner ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundImage: UrlValidator.getSafeImage(entry.avatarUrl),
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.78),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  entry.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatNumber(entry.xp),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'XP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalPositionSection(LeaderboardData data) {
    final summary = data.summary;
    final currentUser = data.currentUser!;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'AUTOUR DE TOI',
            title: 'Ta bataille immédiate',
            subtitle:
                'Les positions à surveiller pour grimper vite sans perdre de terrain.',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.north_rounded,
                  title: summary.targetName.isNotEmpty
                      ? 'Cible: ${summary.targetName}'
                      : 'Tu es en tête',
                  body: summary.targetName.isNotEmpty
                      ? '${_formatNumber(summary.gapToTarget)} ${summary.scoreLabel} à rattraper.'
                      : 'Personne devant toi sur ce scope.',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.south_rounded,
                  title: summary.chaserName.isNotEmpty
                      ? 'Derrière: ${summary.chaserName}'
                      : 'Zone sûre',
                  body: summary.chaserName.isNotEmpty
                      ? '${_formatNumber(summary.leadOverChaser)} ${summary.scoreLabel} d’avance.'
                      : 'Aucun poursuivant immédiat.',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...data.aroundMe.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRankingTile(
                entry,
                highlight: entry.isCurrentUser,
                scoreLabel: summary.scoreLabel,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'Ton profil actuel: rang #${currentUser.rank}, ${currentUser.league}, ${currentUser.sessionsCount} sessions actives sur ce scope et un score moyen de ${currentUser.averageScore.round()}/100.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(LeaderboardData data) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'CLASSEMENT',
            title: 'Top joueurs',
            subtitle:
                'La vue complète du leaderboard actif, avec mise en avant de ton rang.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${data.summary.totalLearners} joueurs',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...data.leaderboard.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRankingTile(
                entry,
                highlight: entry.isCurrentUser,
                scoreLabel: data.summary.scoreLabel,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.summary.generatedAt != null
                ? 'Mise à jour: ${_formatDateTime(data.summary.generatedAt!)}'
                : 'Mise à jour récente',
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.48),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTile(
    LeaderboardEntry entry, {
    required bool highlight,
    required String scoreLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.onSurface.withValues(alpha: 0.05),
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              entry.rank.toString().padLeft(2, '0'),
              style: TextStyle(
                color: highlight
                    ? AppColors.primary
                    : AppColors.onSurface.withValues(alpha: 0.35),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: highlight
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: UrlValidator.getSafeImage(entry.avatarUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (highlight)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'TOI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniTag(entry.league),
                    _buildMiniTag('Niv ${entry.levelNumber}'),
                    _buildMiniTag('${entry.streakDays}j streak'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.sessionsCount} sessions • Score moyen ${entry.averageScore.round()}/100',
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(entry.xp),
                style: TextStyle(
                  color: highlight ? AppColors.primary : AppColors.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                scoreLabel.toUpperCase(),
                style: TextStyle(
                  color: highlight
                      ? AppColors.primary
                      : AppColors.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: AppColors.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.onSurface.withValues(alpha: 0.64),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final reversedIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month à $hour:$minute';
  }
}
