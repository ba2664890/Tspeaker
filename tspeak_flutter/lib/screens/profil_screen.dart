import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart' as models;
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/safe_ui.dart';
import '../utils/url_validator.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  static const String _notificationsPrefKey = 'profile.notifications.enabled';
  static const String _weeklyDigestPrefKey = 'profile.weekly_digest.enabled';
  static const String _focusReminderPrefKey = 'profile.focus_reminders.enabled';

  late Future<models.User> _userFuture;
  bool _notificationsEnabled = true;
  bool _weeklyDigestEnabled = true;
  bool _focusRemindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserService>().getUserProfile();
    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsPrefKey) ?? true;
      _weeklyDigestEnabled = prefs.getBool(_weeklyDigestPrefKey) ?? true;
      _focusRemindersEnabled = prefs.getBool(_focusReminderPrefKey) ?? false;
    });
  }

  Future<void> _refreshProfile() async {
    final future = context.read<UserService>().getUserProfile();
    setState(() {
      _userFuture = future;
    });
    await future;
  }

  Future<void> _updateLocalPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    if (!mounted) return;

    setState(() {
      switch (key) {
        case _notificationsPrefKey:
          _notificationsEnabled = value;
          break;
        case _weeklyDigestPrefKey:
          _weeklyDigestEnabled = value;
          break;
        case _focusReminderPrefKey:
          _focusRemindersEnabled = value;
          break;
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Se déconnecter ?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Tu devras te reconnecter pour reprendre tes sessions et accéder à ton profil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    await context.read<AuthService>().logout();
    if (!mounted) return;

    SafeUI.navigate(context, (ctx) {
      if (mounted) {
        Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    });
  }

  void _showInfoSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState();
        }

        final user = snapshot.data!;
        final milestones = _buildMilestones(user);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              _buildAmbientBackground(),
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refreshProfile,
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
                          child: _buildTopBar(user),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeroCard(user),
                          const SizedBox(height: 22),
                          _buildProgressCard(user),
                          const SizedBox(height: 22),
                          _buildSkillsCard(user),
                          const SizedBox(height: 22),
                          _buildIdentityCard(user),
                          const SizedBox(height: 22),
                          _buildMilestonesCard(user, milestones),
                          const SizedBox(height: 22),
                          _buildSettingsCard(user),
                          const SizedBox(height: 18),
                          _buildLogoutButton(),
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
              'Ton profil se prépare...',
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
                    Icons.wifi_off_rounded,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Impossible de charger le profil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifie ta connexion puis relance le chargement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _refreshProfile,
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
            top: -80,
            right: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            left: -70,
            top: 240,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            right: -40,
            bottom: 60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(models.User user) {
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
                  'Ton espace personnel',
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
          icon: Icons.shield_outlined,
          onTap: _showPrivacyDialog,
        ),
        const SizedBox(width: 10),
        _buildTopIconButton(
          icon: Icons.info_outline_rounded,
          onTap: () => _showAccountDialog(user),
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

  Widget _buildHeroCard(models.User user) {
    final profileCompletion = _profileCompletion(user);
    final overallScore = _safeScore(user.averageScore);
    final achievementCount = user.badgesCount > 0
        ? user.badgesCount
        : _buildMilestones(user).where((item) => item.completed).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22120C),
            Color(0xFF7A2A00),
            Color(0xFFE46C2F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
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
                    icon: user.isPremiumActive
                        ? Icons.workspace_premium_rounded
                        : Icons.auto_awesome_rounded,
                    label: user.isPremiumActive
                        ? 'Premium actif'
                        : 'Plan standard',
                    color: user.isPremiumActive
                        ? AppColors.secondaryContainer
                        : Colors.white.withValues(alpha: 0.12),
                    textColor: user.isPremiumActive
                        ? AppColors.onSecondaryContainer
                        : Colors.white,
                  ),
                  const Spacer(),
                  _buildHeroPill(
                    icon: Icons.tune_rounded,
                    label: 'Profil ${(profileCompletion * 100).round()}%',
                    color: Colors.white.withValues(alpha: 0.12),
                    textColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundImage:
                          UrlValidator.getSafeImage(user.avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name.isEmpty ? 'Apprenant T.Speak' : user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _buildHeadline(user),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _buildHeroTags(user),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Text(
                  user.bio.isNotEmpty
                      ? user.bio
                      : 'Ajoute une bio courte pour personnaliser encore plus tes sessions, tes conseils et ta progression.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildHeroActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Modifier',
                      filled: true,
                      onTap: () => _showEditProfileSheet(user),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeroActionButton(
                      icon: Icons.language_rounded,
                      label: 'Préférences',
                      filled: false,
                      onTap: () => _showLearningPreferencesSheet(user),
                    ),
                  ),
                ],
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
                        label: 'Score global',
                        value: '${overallScore.round()}%',
                        icon: Icons.insights_rounded,
                      ),
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'XP cumulés',
                        value: '${user.xp}',
                        icon: Icons.stars_rounded,
                      ),
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'Sessions',
                        value: '${user.sessions}',
                        icon: Icons.mic_external_on_rounded,
                      ),
                      _buildHeroStatCard(
                        width: itemWidth,
                        label: 'Succès',
                        value: '$achievementCount',
                        icon: Icons.emoji_events_rounded,
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

  Widget _buildHeroActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: filled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: filled ? AppColors.onSurface : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: filled ? AppColors.onSurface : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildProgressCard(models.User user) {
    final currentFloor = _currentLevelFloor(user.level);
    final nextCeiling = _nextLevelCeiling(user);
    final progress = _levelProgress(user);
    final remaining = nextCeiling > user.xp ? nextCeiling - user.xp : 0;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'PROGRESSION',
            title: 'Cap sur le niveau suivant',
            subtitle:
                'Une lecture claire de ton XP, de tes points forts et du prochain palier.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Niveau ${user.level}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricBadge(
                        title: 'Palier actuel',
                        value: '$currentFloor XP',
                        icon: Icons.flag_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricBadge(
                        title: 'Prochain cap',
                        value: nextCeiling >= 99999
                            ? 'Maîtrise'
                            : '$nextCeiling XP',
                        icon: Icons.rocket_launch_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor:
                        AppColors.onSurface.withValues(alpha: 0.06),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${user.xp} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      nextCeiling >= 99999
                          ? 'Niveau avancé atteint'
                          : 'Encore $remaining XP',
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildInsightCard(
            icon: Icons.trending_up_rounded,
            title: 'Point fort',
            body:
                '${_bestSkill(user).label} mène la danse avec ${_bestSkill(user).score.round()}/100.',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.track_changes_rounded,
            title: 'Prochain focus',
            body:
                'Travaille ${_lowestSkill(user).label.toLowerCase()} pour équilibrer encore mieux tes performances.',
            color: AppColors.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(models.User user) {
    final skills = _buildSkills(user);
    final hasSessions =
        user.sessions > 0 || skills.any((skill) => skill.score > 0);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'COMPÉTENCES',
            title: 'Tableau de performance',
            subtitle:
                'Tes quatre piliers vocaux, avec un focus immédiat sur ce qu’il faut renforcer.',
          ),
          const SizedBox(height: 18),
          if (hasSessions) ...[
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.onSurface.withValues(alpha: 0.06),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.onSurface.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= skills.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              skills[index].shortLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: skills.asMap().entries.map((entry) {
                    final index = entry.key;
                    final skill = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: skill.score,
                          width: 18,
                          color: skill.color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: skill.color.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aucune session notée pour le moment',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dès que tu termines quelques sessions vocales, ce tableau s’anime avec tes vraies statistiques.',
                    style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.64),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          ...skills.map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSkillRow(skill),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(_SkillMetric skill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: skill.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(skill.icon, color: skill.color, size: 22),
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
                        skill.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      '${skill.score.round()}/100',
                      style: TextStyle(
                        color: skill.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (skill.score / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: skill.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(skill.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(models.User user) {
    final interests = _splitInterests(user.interests);

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'IDENTITÉ',
            title: 'Profil et objectifs',
            subtitle:
                'Les informations qui aident T.Speak à mieux personnaliser tes sessions.',
            trailing: TextButton.icon(
              onPressed: () => _showEditProfileSheet(user),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Éditer'),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: user.email.isNotEmpty ? user.email : 'Non renseigné',
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: user.phone.isNotEmpty ? user.phone : 'Non renseigné',
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.public_rounded,
                  label: 'Pays',
                  value:
                      user.country.isNotEmpty ? user.country : 'Non renseigné',
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.language_rounded,
                  label: 'Langue native',
                  value: _languageLabel(user.nativeLanguage),
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.flag_outlined,
                  label: 'Objectif',
                  value: user.learningGoal.isNotEmpty
                      ? _goalLabel(user.learningGoal)
                      : 'À définir',
                ),
                const SizedBox(height: 14),
                _buildDetailRow(
                  icon: Icons.cake_outlined,
                  label: 'Tranche d’âge',
                  value: user.ageRange.isNotEmpty
                      ? user.ageRange
                      : 'Non renseigné',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Centres d’intérêt',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: interests.isNotEmpty
                ? interests.map((interest) => _buildTagChip(interest)).toList()
                : [
                    _buildTagChip('Conversation'),
                    _buildTagChip('Prononciation'),
                    _buildTagChip('Culture'),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard(
    models.User user,
    List<_MilestoneData> milestones,
  ) {
    final completedCount = milestones.where((item) => item.completed).length;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'JALONS',
            title: 'Objectifs en cours',
            subtitle:
                'Une vue ultra lisible sur ce que tu as déjà débloqué et ce qui arrive ensuite.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$completedCount/${milestones.length} terminés',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...milestones.map(
            (milestone) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMilestoneTile(milestone),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.streak >= 7
                        ? 'Très bon rythme. Ta régularité est déjà un vrai levier de progression.'
                        : 'Le streak est le raccourci le plus rentable pour progresser vite. Une courte session par jour suffit.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile(_MilestoneData milestone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: milestone.completed
            ? milestone.color.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: milestone.completed
              ? milestone.color.withValues(alpha: 0.25)
              : AppColors.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: milestone.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(milestone.icon, color: milestone.color),
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
                        milestone.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      milestone.completed
                          ? 'Acquis'
                          : '${(milestone.progress * 100).round()}%',
                      style: TextStyle(
                        color: milestone.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.subtitle,
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.62),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: milestone.progress,
                    minHeight: 9,
                    backgroundColor: milestone.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(milestone.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(models.User user) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            eyebrow: 'PARAMÈTRES',
            title: 'Confort et sécurité',
            subtitle:
                'Tes réglages rapides, tes préférences d’apprentissage et tes informations de compte.',
          ),
          const SizedBox(height: 18),
          _buildActionTile(
            icon: Icons.person_outline_rounded,
            label: 'Informations du compte',
            subtitle:
                'Consulter les détails du profil, de l’abonnement et de l’inscription.',
            onTap: () => _showAccountDialog(user),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.auto_awesome_rounded,
            label: 'Préférences d’apprentissage',
            subtitle: 'Langue native, objectif principal et tranche d’âge.',
            onTap: () => _showLearningPreferencesSheet(user),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            icon: Icons.help_outline_rounded,
            label: 'Centre d’aide',
            subtitle:
                'Raccourcis, bonnes pratiques et repères utiles pour mieux avancer.',
            onTap: _showSupportSheet,
          ),
          const SizedBox(height: 18),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications utiles',
            subtitle:
                'Recevoir les rappels importants et les évolutions de progression.',
            value: _notificationsEnabled,
            onChanged: (value) =>
                _updateLocalPreference(_notificationsPrefKey, value),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.calendar_view_week_outlined,
            title: 'Récap hebdomadaire',
            subtitle:
                'Garder un oeil sur tes scores et ton rythme de pratique.',
            value: _weeklyDigestEnabled,
            onChanged: (value) =>
                _updateLocalPreference(_weeklyDigestPrefKey, value),
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.self_improvement_outlined,
            title: 'Rappels focus',
            subtitle: 'Mettre l’accent sur ton axe d’amélioration principal.',
            value: _focusRemindersEnabled,
            onChanged: (value) =>
                _updateLocalPreference(_focusReminderPrefKey, value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.onSurface),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.62),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.62),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _handleLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quitter la session en toute sécurité.',
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
            ],
          ),
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

  Widget _buildMetricBadge({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppColors.onSurface.withValues(alpha: 0.38),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _showEditProfileSheet(models.User user) async {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final phoneController = TextEditingController(text: user.phone);
    final countryController = TextEditingController(text: user.country);
    final bioController = TextEditingController(text: user.bio);
    final interestsController = TextEditingController(text: user.interests);
    final avatarController = TextEditingController(text: user.avatarUrl);
    bool isSaving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> submit() async {
                if (!formKey.currentState!.validate()) return;

                setSheetState(() => isSaving = true);

                final success =
                    await this.context.read<UserService>().updateProfile({
                  'first_name': firstNameController.text.trim(),
                  'last_name': lastNameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'country': countryController.text.trim(),
                  'bio': bioController.text.trim(),
                  'interests': interestsController.text.trim(),
                  'avatar_url': avatarController.text.trim(),
                });

                if (!mounted) return;

                if (!success) {
                  setSheetState(() => isSaving = false);
                  _showInfoSnackBar(
                    'Impossible de mettre à jour le profil pour le moment.',
                    isError: true,
                  );
                  return;
                }

                Navigator.of(sheetContext).pop();
                await _refreshProfile();
                _showInfoSnackBar('Profil mis à jour avec succès.');
              }

              return _buildSheetContainer(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSheetHeader(
                        title: 'Modifier le profil',
                        subtitle:
                            'Ajuste ton identité, ton image et la façon dont tu te présentes.',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetTextField(
                              controller: firstNameController,
                              label: 'Prénom',
                              icon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSheetTextField(
                              controller: lastNameController,
                              label: 'Nom',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: phoneController,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: countryController,
                        label: 'Pays',
                        icon: Icons.public_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: avatarController,
                        label: 'Photo de profil (URL)',
                        icon: Icons.image_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return null;
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null ||
                              !uri.hasScheme ||
                              !uri.hasAuthority) {
                            return 'Entre une URL valide ou laisse le champ vide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: bioController,
                        label: 'Bio',
                        icon: Icons.auto_awesome_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _buildSheetTextField(
                        controller: interestsController,
                        label: 'Centres d’intérêt',
                        icon: Icons.interests_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : submit,
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enregistrer'),
                        ),
                      ),
                      SizedBox(
                          height:
                              MediaQuery.of(sheetContext).viewInsets.bottom),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      firstNameController.dispose();
      lastNameController.dispose();
      phoneController.dispose();
      countryController.dispose();
      bioController.dispose();
      interestsController.dispose();
      avatarController.dispose();
    }
  }

  Future<void> _showLearningPreferencesSheet(models.User user) async {
    String selectedLanguage =
        user.nativeLanguage.isNotEmpty ? user.nativeLanguage : 'french';
    String selectedGoal = user.learningGoal;
    String selectedAgeRange = user.ageRange;
    bool isSaving = false;

    const ageRanges = ['13-17', '18-24', '25-34', '35-44', '45+'];

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> submit() async {
                setSheetState(() => isSaving = true);

                final success =
                    await this.context.read<UserService>().updateProfile({
                  'native_language': selectedLanguage,
                  'learning_goal': selectedGoal,
                  'age_range': selectedAgeRange,
                });

                if (!mounted) return;

                if (!success) {
                  setSheetState(() => isSaving = false);
                  _showInfoSnackBar(
                    'Impossible de sauvegarder tes préférences.',
                    isError: true,
                  );
                  return;
                }

                Navigator.of(sheetContext).pop();
                await _refreshProfile();
                _showInfoSnackBar('Préférences mises à jour.');
              }

              return _buildSheetContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetHeader(
                      title: 'Préférences d’apprentissage',
                      subtitle:
                          'Affiner le contexte pour que T.Speak ajuste mieux les recommandations.',
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLanguage,
                      decoration: _dropdownDecoration(
                        label: 'Langue native',
                        icon: Icons.language_rounded,
                      ),
                      items: _languageOptions.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedLanguage = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedGoal.isNotEmpty ? selectedGoal : null,
                      decoration: _dropdownDecoration(
                        label: 'Objectif principal',
                        icon: Icons.flag_outlined,
                      ),
                      items: _goalOptions.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() => selectedGoal = value ?? '');
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedAgeRange.isNotEmpty ? selectedAgeRange : null,
                      decoration: _dropdownDecoration(
                        label: 'Tranche d’âge',
                        icon: Icons.cake_outlined,
                      ),
                      items: ageRanges
                          .map(
                            (ageRange) => DropdownMenuItem<String>(
                              value: ageRange,
                              child: Text(ageRange),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() => selectedAgeRange = value ?? '');
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : submit,
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enregistrer les préférences'),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(sheetContext).viewInsets.bottom),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {}
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
    );
  }

  Future<void> _showAccountDialog(models.User user) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: const Text(
            'Informations du compte',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogRow(Icons.person_outline_rounded, 'Nom',
                  user.name.isNotEmpty ? user.name : 'Non renseigné'),
              const SizedBox(height: 12),
              _buildDialogRow(Icons.mail_outline_rounded, 'Email',
                  user.email.isNotEmpty ? user.email : 'Non renseigné'),
              const SizedBox(height: 12),
              _buildDialogRow(Icons.workspace_premium_rounded, 'Abonnement',
                  user.isPremiumActive ? 'Premium actif' : 'Plan standard'),
              const SizedBox(height: 12),
              _buildDialogRow(Icons.calendar_month_outlined, 'Membre depuis',
                  _formatDate(user.joinedAt)),
              const SizedBox(height: 12),
              _buildDialogRow(
                  Icons.flag_outlined,
                  'Objectif',
                  user.learningGoal.isNotEmpty
                      ? _goalLabel(user.learningGoal)
                      : 'À définir'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPrivacyDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: const Text(
            'Confidentialité',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrivacyLine(
                  'Tes informations de profil servent à personnaliser les recommandations et les parcours.'),
              const SizedBox(height: 10),
              _buildPrivacyLine(
                  'Les réglages de notifications de cet écran sont conservés localement sur l’appareil.'),
              const SizedBox(height: 10),
              _buildPrivacyLine(
                  'Tu peux modifier tes informations personnelles à tout moment depuis cet onglet.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivacyLine(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _showSupportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _buildSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHeader(
                title: 'Centre d’aide',
                subtitle:
                    'Quelques repères utiles pour garder une progression fluide.',
              ),
              const SizedBox(height: 18),
              _buildSupportTip(
                icon: Icons.mic_none_rounded,
                title: 'Voix plus stable',
                body:
                    'Des sessions courtes mais régulières donnent souvent de meilleurs résultats que de longues séances espacées.',
              ),
              const SizedBox(height: 12),
              _buildSupportTip(
                icon: Icons.bolt_outlined,
                title: 'Monter en score',
                body:
                    'Travaille la régularité du débit et la clarté des attaques de mots pour faire grimper prononciation et fluidité ensemble.',
              ),
              const SizedBox(height: 12),
              _buildSupportTip(
                icon: Icons.refresh_rounded,
                title: 'Rafraîchir les données',
                body:
                    'Tire l’écran vers le bas pour recharger le profil après une session ou une mise à jour.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportTip({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.62),
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

  Widget _buildDialogRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.onSurface.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSheetContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  Widget _buildSheetHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 52,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.onSurface.withValues(alpha: 0.62),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  String _buildHeadline(models.User user) {
    final pieces = <String>[
      _levelLabel(user.level),
      _languageLabel(user.nativeLanguage),
    ];

    if (user.country.isNotEmpty) {
      pieces.add(user.country);
    }

    return pieces.join(' • ');
  }

  List<Widget> _buildHeroTags(models.User user) {
    final tags = <String>[
      'Membre depuis ${_formatDate(user.joinedAt)}',
      if (user.learningGoal.isNotEmpty) _goalLabel(user.learningGoal),
      if (user.streak > 0) '${user.streak} jours de série',
    ];

    return tags
        .map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        )
        .toList();
  }

  List<_SkillMetric> _buildSkills(models.User user) {
    return [
      _SkillMetric(
        label: 'Prononciation',
        shortLabel: 'Pron.',
        score: _safeScore(user.avgPronunciation),
        color: AppColors.primary,
        icon: Icons.record_voice_over_rounded,
      ),
      _SkillMetric(
        label: 'Fluidité',
        shortLabel: 'Fluid.',
        score: _safeScore(user.avgFluency),
        color: AppColors.secondary,
        icon: Icons.waves_rounded,
      ),
      _SkillMetric(
        label: 'Grammaire',
        shortLabel: 'Gram.',
        score: _safeScore(user.avgGrammar),
        color: AppColors.tertiary,
        icon: Icons.menu_book_rounded,
      ),
      _SkillMetric(
        label: 'Vocabulaire',
        shortLabel: 'Lexique',
        score: _safeScore(user.avgVocabulary),
        color: const Color(0xFF3F51B5),
        icon: Icons.auto_stories_rounded,
      ),
    ];
  }

  _SkillMetric _bestSkill(models.User user) {
    final skills = _buildSkills(user)
      ..sort((a, b) => b.score.compareTo(a.score));
    return skills.first;
  }

  _SkillMetric _lowestSkill(models.User user) {
    final skills = _buildSkills(user)
      ..sort((a, b) => a.score.compareTo(b.score));
    return skills.first;
  }

  List<_MilestoneData> _buildMilestones(models.User user) {
    final profileProgress = _profileCompletion(user);
    final overallScore = (_safeScore(user.averageScore) / 80).clamp(0.0, 1.0);

    return [
      _MilestoneData(
        title: 'Profil complet',
        subtitle: 'Remplir identité, pays, bio et préférences de base.',
        progress: profileProgress,
        completed: profileProgress >= 1,
        icon: Icons.account_circle_outlined,
        color: AppColors.primary,
      ),
      _MilestoneData(
        title: 'Série de 7 jours',
        subtitle: 'Installer une vraie routine de pratique quotidienne.',
        progress: (user.streak / 7).clamp(0.0, 1.0),
        completed: user.streak >= 7,
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF7043),
      ),
      _MilestoneData(
        title: '10 sessions terminées',
        subtitle: 'Accumuler assez de matière pour lire une tendance fiable.',
        progress: (user.sessions / 10).clamp(0.0, 1.0),
        completed: user.sessions >= 10,
        icon: Icons.mic_external_on_rounded,
        color: AppColors.secondary,
      ),
      _MilestoneData(
        title: 'Score moyen de 80+',
        subtitle:
            'Stabiliser un niveau très solide sur l’ensemble des compétences.',
        progress: overallScore,
        completed: _safeScore(user.averageScore) >= 80,
        icon: Icons.emoji_events_outlined,
        color: AppColors.tertiary,
      ),
    ];
  }

  double _safeScore(double value) => value.clamp(0.0, 100.0);

  double _profileCompletion(models.User user) {
    final fields = [
      user.firstName,
      user.lastName,
      user.phone,
      user.country,
      user.bio,
      user.interests,
      user.learningGoal,
      user.ageRange,
      user.avatarUrl,
    ];

    final filled = fields.where((field) => field.trim().isNotEmpty).length;
    return (filled / fields.length).clamp(0.0, 1.0);
  }

  int _currentLevelFloor(int level) {
    const thresholds = [0, 500, 1500, 3500, 7500];
    final index = (level - 1).clamp(0, thresholds.length - 1);
    return thresholds[index];
  }

  int _nextLevelCeiling(models.User user) {
    return user.xpToNextLevel >= 99999 ? 99999 : user.xpToNextLevel;
  }

  double _levelProgress(models.User user) {
    final minXp = _currentLevelFloor(user.level);
    final maxXp = _nextLevelCeiling(user);

    if (maxXp <= minXp || maxXp >= 99999) {
      return 1;
    }

    final progress = (user.xp - minXp) / (maxXp - minXp);
    return progress.clamp(0.0, 1.0);
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1:
        return 'Apprenant';
      case 2:
        return 'Élémentaire';
      case 3:
        return 'Intermédiaire';
      case 4:
        return 'Avancé';
      case 5:
        return 'Expert vocal';
      default:
        return 'Apprenant';
    }
  }

  String _goalLabel(String goal) {
    return _goalOptions[goal] ?? goal;
  }

  String _languageLabel(String language) {
    return _languageOptions[language] ?? language;
  }

  List<String> _splitInterests(String interests) {
    if (interests.trim().isEmpty) return [];

    return interests
        .split(RegExp(r'[,;/•]+'))
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Aujourd’hui';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static const Map<String, String> _goalOptions = {
    'travel': 'Voyager et explorer',
    'work': 'Opportunités professionnelles',
    'study': 'Études à l’étranger',
    'culture': 'Découvrir une culture',
    'family': 'Communication familiale',
  };

  static const Map<String, String> _languageOptions = {
    'wolof': 'Wolof',
    'pulaar': 'Pulaar / Peul',
    'bambara': 'Bambara',
    'dioula': 'Dioula',
    'serer': 'Sérère',
    'french': 'Français',
    'other': 'Autre',
  };
}

class _SkillMetric {
  final String label;
  final String shortLabel;
  final double score;
  final Color color;
  final IconData icon;

  const _SkillMetric({
    required this.label,
    required this.shortLabel,
    required this.score,
    required this.color,
    required this.icon,
  });
}

class _MilestoneData {
  final String title;
  final String subtitle;
  final double progress;
  final bool completed;
  final IconData icon;
  final Color color;

  const _MilestoneData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.completed,
    required this.icon,
    required this.color,
  });
}
