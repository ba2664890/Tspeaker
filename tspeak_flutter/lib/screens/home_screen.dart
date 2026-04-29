import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart' as models;
import '../services/simulation_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/url_validator.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/patterns_painter.dart';
import 'catalogue_screen.dart';
import 'classement_screen.dart';
import 'profil_screen.dart';
import 'session_vocale_screen.dart';
import '../utils/safe_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _freeSessionVersion = 0;

  void _handleTabChange(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
  }

  late Widget _homeScreen;
  late Widget _practiceScreen;
  late Widget _ranksScreen;
  late Widget _profileScreen;

  @override
  void initState() {
    super.initState();
    _homeScreen = HomeContent(
      onTabChange: _handleTabChange,
      onOpenFreeSession: _openFreeSessionTab,
    );
    _practiceScreen = const CatalogueScreen();
    _ranksScreen = const ClassementScreen();
    _profileScreen = const ProfilScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleTabChange,
      ),
      floatingActionButton: _currentIndex == 0 ? _buildHomeFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _openFreeSessionTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _freeSessionVersion += 1;
          _currentIndex = 2;
        });
      }
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _homeScreen;
      case 1:
        return _practiceScreen;
      case 2:
        return SessionVocaleScreen(
          key: ValueKey('free-session-$_freeSessionVersion'),
          title: 'Session libre',
          openingMessage:
              'Prends la parole librement sur ton sujet du jour et développe ton idée avec naturel.',
          embeddedInHome: true,
          onClose: () => _handleTabChange(0),
          onComplete: () => _handleTabChange(0),
        );
      case 3:
        return _ranksScreen;
      case 4:
        return _profileScreen;
      default:
        return _homeScreen;
    }
  }

  Widget _buildHomeFab() {
    return Container(
      height: 74,
      width: 74,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFFE46C2F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _openFreeSessionTab,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 34),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final ValueChanged<int> onTabChange;
  final VoidCallback onOpenFreeSession;

  const HomeContent({
    super.key,
    required this.onTabChange,
    required this.onOpenFreeSession,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  static const _favoritesKey = 'practice.favorite_simulations';
  static const _lastStartedKey = 'practice.last_started_simulation';

  late Future<_HomeBundle> _bundleFuture;
  Set<String> _favoriteIds = <String>{};
  String? _lastStartedSimulationId;
  String? _launchingSimulationId;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
    _loadLocalPrefs();
  }

  Future<_HomeBundle> _loadBundle() async {
    final results = await Future.wait([
      context.read<UserService>().getUserProfile(),
      context.read<SimulationService>().getSimulations(),
    ]);

    return _HomeBundle(
      user: results[0] as models.User,
      simulations: results[1] as List<models.Simulation>,
    );
  }

  Future<void> _refreshData() async {
    final future = _loadBundle();
    SafeUI.run(() {
      if (mounted) {
        setState(() => _bundleFuture = future);
      }
    });
    await future;
  }

  Future<void> _loadLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoritesKey) ?? const <String>[];
    final lastStarted = prefs.getString(_lastStartedKey);

    if (!mounted) return;

    setState(() {
      _favoriteIds = favoriteIds.toSet();
      _lastStartedSimulationId = lastStarted;
    });
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
  }

  Future<void> _persistLastStarted(String simulationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStartedKey, simulationId);
    if (!mounted) return;
    setState(() => _lastStartedSimulationId = simulationId);
  }

  Future<void> _toggleFavorite(String simulationId) async {
    SafeUI.run(() {
      if (mounted) {
        setState(() {
          if (_favoriteIds.contains(simulationId)) {
            _favoriteIds.remove(simulationId);
          } else {
            _favoriteIds.add(simulationId);
          }
        });
      }
    });
    await _persistFavorites();
  }

  void _openTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onTabChange(index);
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

  void _launchSimulation(models.Simulation simulation) {
    if (!simulation.isAccessible) {
      _showInfoSnackBar(
        'Cette simulation est réservée aux abonnés Premium.',
        isError: true,
      );
      return;
    }

    if (_launchingSimulationId != null) return;

    SafeUI.run(() {
      if (mounted) {
        setState(() => _launchingSimulationId = simulation.id);
      }
    });

    // Schedule async work to avoid pointer event timing issues
    _performLaunch(simulation);
  }

  Future<void> _performLaunch(models.Simulation simulation) async {
    try {
      final launch = await context
          .read<SimulationService>()
          .startSimulation(simulation.id);

      await _persistLastStarted(simulation.id);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionVocaleScreen(
            sessionId: launch.sessionId,
            title: launch.simulation.title,
            openingMessage: launch.openingMessage,
          ),
        ),
      );

      if (mounted) {
        await _refreshData();
      }
    } catch (_) {
      if (mounted) {
        _showInfoSnackBar(
          'Impossible de démarrer la simulation pour le moment.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
      SafeUI.run(() {
        if (mounted) {
          setState(() => _launchingSimulationId = null);
        }
      });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeBundle>(
      future: _bundleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState();
        }

        final bundle = snapshot.data!;
        final user = bundle.user;
        final accessibleSimulations = bundle.simulations
            .where((simulation) => simulation.isAccessible)
            .toList();
        final continueSimulation = bundle.simulations
            .where((simulation) => simulation.id == _lastStartedSimulationId)
            .cast<models.Simulation?>()
            .firstOrNull;
        final favorites = bundle.simulations
            .where((simulation) => _favoriteIds.contains(simulation.id))
            .toList();
        final recommended = _recommended(bundle);
        final spotlight = continueSimulation ??
            recommended.firstOrNull ??
            accessibleSimulations.firstOrNull;
        final skills = _buildSkills(user);
        final bestSkill = _bestSkill(user);
        final lowestSkill = _lowestSkill(user);
        final levelProgress = _levelProgress(user);
        final xpRemaining = _xpRemaining(user);

        return Stack(
          children: [
            _buildAmbientBackground(),
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshData,
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
                        _buildHeroCard(
                          user: user,
                          spotlight: spotlight,
                          focusSkill: lowestSkill,
                        ),
                        const SizedBox(height: 20),
                        _buildProgressHub(
                          user: user,
                          levelProgress: levelProgress,
                          xpRemaining: xpRemaining,
                        ),
                        if (continueSimulation != null) ...[
                          const SizedBox(height: 20),
                          _buildPrioritySection(
                            eyebrow: 'CONTINUER',
                            title: 'Reprendre ton dernier terrain',
                            subtitle:
                                'Relance une session déjà repérée pour garder ton élan.',
                            simulation: continueSimulation,
                            focusSkill: lowestSkill,
                            primaryLabel: 'Reprendre',
                            onPrimaryTap: () => _launchSimulation(
                              continueSimulation,
                            ),
                            onSecondaryTap: () => _openTab(1),
                          ),
                        ] else if (spotlight != null) ...[
                          const SizedBox(height: 20),
                          _buildPrioritySection(
                            eyebrow: 'PROCHAIN PAS',
                            title: 'Le bon scénario pour aujourd’hui',
                            subtitle:
                                'Une suggestion simple pour transformer ton prochain passage vocal en vrai progrès.',
                            simulation: spotlight,
                            focusSkill: lowestSkill,
                            primaryLabel: 'Lancer',
                            onPrimaryTap: () => _launchSimulation(spotlight),
                            onSecondaryTap: () => _openTab(1),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildSkillSection(
                          skills: skills,
                          bestSkill: bestSkill,
                          lowestSkill: lowestSkill,
                        ),
                        const SizedBox(height: 20),
                        _buildQuickAccessSection(),
                        if (recommended.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildHorizontalSection(
                            title: 'Recommandé pour toi',
                            subtitle:
                                'Des simulations concrètes choisies selon ton niveau et ton rythme.',
                            simulations: recommended,
                          ),
                        ],
                        if (favorites.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildHorizontalSection(
                            title: 'Tes favoris',
                            subtitle:
                                'Les scénarios que tu gardes sous la main pour rejouer sans chercher.',
                            simulations: favorites,
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
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
            'Le tableau de bord se prépare...',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 78, sigmaY: 78),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 74, sigmaY: 74),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 70,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tertiary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(models.User user) {
    final caption =
        '${_levelLabel(user.level)} • ${_languageLabel(user.nativeLanguage)}';

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openTab(4),
            child: Row(
              children: [
                _buildProfileAvatar(user),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour,',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppColors.onSurface.withValues(alpha: 0.52),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user.firstName.isNotEmpty ? user.firstName : 'toi'} 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppColors.onSurface.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusBadge(user),
        const SizedBox(width: 10),
        _buildNotificationBell(),
      ],
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
            image: DecorationImage(
              image: UrlValidator.getSafeImage(user.avatarUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildStatusBadge(models.User user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: user.isPremiumActive
            ? AppColors.tertiary.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: user.isPremiumActive
              ? AppColors.tertiary.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.isPremiumActive
                ? Icons.workspace_premium_rounded
                : Icons.bolt_rounded,
            size: 16,
            color:
                user.isPremiumActive ? AppColors.tertiary : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            user.isPremiumActive ? 'Premium' : 'Focus',
            style: TextStyle(
              color:
                  user.isPremiumActive ? AppColors.tertiary : AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: IconButton(
        onPressed: () => _showInfoSnackBar(
          'Pas de nouvelles notifications pour le moment.',
        ),
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.onSurface,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required models.User user,
    required models.Simulation? spotlight,
    required _HomeSkill focusSkill,
  }) {
    final firstName = user.firstName.isNotEmpty ? user.firstName : 'toi';
    final goal = user.learningGoal.isNotEmpty
        ? _goalLabel(user.learningGoal)
        : 'Progression orale régulière';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF13252D),
            Color(0xFF006B55),
            Color(0xFFE46C2F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -12,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHeroPill(
                    icon: Icons.auto_awesome_rounded,
                    label: _levelLabel(user.level),
                  ),
                  _buildHeroPill(
                    icon: Icons.local_fire_department_rounded,
                    label: '${user.streak} jours',
                  ),
                  _buildHeroPill(
                    icon: Icons.flag_rounded,
                    label: _languageLabel(user.nativeLanguage),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Bonjour $firstName,\non garde le rythme.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                spotlight != null
                    ? 'Objectif du moment: $goal. Le meilleur prochain pas semble être ${spotlight.title}, avec un focus utile sur ${focusSkill.label.toLowerCase()}.'
                    : 'Objectif du moment: $goal. Relance une session libre ou explore le practice lab pour continuer à progresser sans friction.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHeroTag(
                    user.country.isNotEmpty ? user.country : 'Dashboard perso',
                  ),
                  if (user.joinedAt != null)
                    _buildHeroTag(
                        'Membre depuis ${_formatDate(user.joinedAt)}'),
                  if (user.sessions > 0)
                    _buildHeroTag('${user.sessions} sessions terminées'),
                ],
              ),
              if (spotlight != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          spotlight.iconEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spotlight.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_difficultyLabel(spotlight.difficulty)} • ${spotlight.duration} min',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _launchingSimulationId == spotlight.id
                            ? null
                            : () => _launchSimulation(spotlight),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.onSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: _launchingSimulationId == spotlight.id
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Lancer'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 430;
                  final primaryButton = ElevatedButton.icon(
                    onPressed: widget.onOpenFreeSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Session libre'),
                  );
                  final secondaryButton = OutlinedButton.icon(
                    onPressed: () => _openTab(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: const Text('Practice Lab'),
                  );

                  if (stacked) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: primaryButton,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: secondaryButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: primaryButton),
                      const SizedBox(width: 12),
                      Expanded(child: secondaryButton),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
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

  Widget _buildProgressHub({
    required models.User user,
    required double levelProgress,
    required int xpRemaining,
  }) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'MOMENTUM',
            title: 'Ta progression en clair',
            subtitle:
                'Un point rapide pour voir ce qui avance et ce qui mérite encore un peu d’attention.',
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
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Niveau ${user.level} • ${_levelLabel(user.level)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            xpRemaining == 0
                                ? 'Tu as atteint le plafond connu du niveau actuel.'
                                : 'Encore $xpRemaining XP pour passer à l’étape suivante.',
                            style: TextStyle(
                              color:
                                  AppColors.onSurface.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: levelProgress,
                    minHeight: 12,
                    backgroundColor:
                        AppColors.onSurface.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 520
                      ? 2
                      : 1;
              const spacing = 12.0;
              final tileWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _buildStatCard(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Série',
                      value: '${user.streak}',
                      hint: 'jours consécutifs',
                      color: const Color(0xFFFF7043),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildStatCard(
                      icon: Icons.mic_external_on_rounded,
                      label: 'Sessions',
                      value: '${user.sessions}',
                      hint: 'déjà terminées',
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildStatCard(
                      icon: Icons.insights_rounded,
                      label: 'Score moyen',
                      value: '${_safeScore(user.averageScore).round()}/100',
                      hint: 'sur tes dernières performances',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildStatCard(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Badges',
                      value: '${user.badgesCount}',
                      hint: user.isPremiumActive
                          ? 'premium actif'
                          : 'distinctions obtenues',
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String hint,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection({
    required String eyebrow,
    required String title,
    required String subtitle,
    required models.Simulation simulation,
    required _HomeSkill focusSkill,
    required String primaryLabel,
    required VoidCallback onPrimaryTap,
    required VoidCallback onSecondaryTap,
  }) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final visual = ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: compact ? double.infinity : 170,
                  height: compact ? 180 : 170,
                  child: Image(
                    image: UrlValidator.getSafeImage(
                      simulation.imageUrl,
                      placeholder: 'assets/images/logo.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              );

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        simulation.iconEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          simulation.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${simulation.description} Conseil du moment: travaille ${focusSkill.label.toLowerCase()} pour équilibrer encore mieux ta voix.',
                    style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.64),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetaChip(_categoryLabel(simulation.category)),
                      _buildMetaChip(_difficultyLabel(simulation.difficulty)),
                      _buildMetaChip('${simulation.duration} min'),
                      _buildMetaChip(
                        simulation.isPremium ? 'Premium' : 'Accessible',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, buttonConstraints) {
                      final stacked = buttonConstraints.maxWidth < 350;

                      if (stacked) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _buildLaunchButton(
                                simulation,
                                label: primaryLabel,
                                onTap: onPrimaryTap,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onSecondaryTap,
                                icon: const Icon(Icons.auto_stories_rounded),
                                label: const Text('Voir le lab'),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildLaunchButton(
                              simulation,
                              label: primaryLabel,
                              onTap: onPrimaryTap,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onSecondaryTap,
                              icon: const Icon(Icons.auto_stories_rounded),
                              label: const Text('Voir le lab'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    visual,
                    const SizedBox(height: 16),
                    content,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visual,
                  const SizedBox(width: 18),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSection({
    required List<_HomeSkill> skills,
    required _HomeSkill bestSkill,
    required _HomeSkill lowestSkill,
  }) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'SKILLS',
            title: 'Ton mix de compétences',
            subtitle:
                '${bestSkill.label} mène la danse à ${bestSkill.score.round()}/100. ${lowestSkill.label} mérite encore un peu de répétition.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              const spacing = 12.0;
              final tileWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: skills
                    .map(
                      (skill) => SizedBox(
                        width: tileWidth,
                        child: _buildSkillCard(skill),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(_HomeSkill skill) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: skill.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(skill.icon, color: skill.color, size: 20),
              ),
              const SizedBox(width: 12),
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
                '${skill.score.round()}',
                style: TextStyle(
                  color: skill.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (skill.score / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(skill.color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            skill.score >= 80
                ? 'Très bon signal, continue à consolider.'
                : skill.score >= 60
                    ? 'Base solide, encore un peu de régularité.'
                    : 'Zone prioritaire pour créer un vrai saut de niveau.',
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.58),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    final shortcuts = [
      _HomeShortcut(
        title: 'Session libre',
        subtitle: 'Parler tout de suite sans scénario imposé.',
        icon: Icons.mic_rounded,
        color: AppColors.primary,
        onTap: widget.onOpenFreeSession,
      ),
      _HomeShortcut(
        title: 'Practice Lab',
        subtitle: 'Explorer tout le catalogue et les filtres.',
        icon: Icons.auto_stories_rounded,
        color: AppColors.secondary,
        onTap: () => _openTab(1),
      ),
      _HomeShortcut(
        title: 'Classement',
        subtitle: 'Voir ton rang et garder la motivation.',
        icon: Icons.emoji_events_rounded,
        color: AppColors.tertiary,
        onTap: () => _openTab(3),
      ),
    ];

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'RACCOURCIS',
            title: 'Accès rapides',
            subtitle:
                'Trois portes d’entrée utiles selon ton énergie et le temps que tu as.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 560
                      ? 2
                      : 1;
              const spacing = 12.0;
              final tileWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: shortcuts
                    .map(
                      (shortcut) => SizedBox(
                        width: tileWidth,
                        child: _buildShortcutCard(shortcut),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard(_HomeShortcut shortcut) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: shortcut.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: shortcut.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(shortcut.icon, color: shortcut.color),
              ),
              const SizedBox(height: 16),
              Text(
                shortcut.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shortcut.subtitle,
                style: TextStyle(
                  color: AppColors.onSurface.withValues(alpha: 0.62),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection({
    required String title,
    required String subtitle,
    required List<models.Simulation> simulations,
  }) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'PICKS',
            title: title,
            subtitle: subtitle,
            trailing: TextButton.icon(
              onPressed: () => _openTab(1),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Voir tout'),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 1100
                  ? 292.0
                  : constraints.maxWidth >= 720
                      ? 258.0
                      : max(220.0, min(286.0, constraints.maxWidth * 0.8));

              return SizedBox(
                height: 340,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: simulations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final simulation = simulations[index];
                    return SizedBox(
                      width: cardWidth,
                      child: _buildSimulationCard(simulation),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationCard(models.Simulation simulation) {
    final isFavorite = _favoriteIds.contains(simulation.id);
    final isLaunching = _launchingSimulationId == simulation.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLaunching ? null : () => _launchSimulation(simulation),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 158,
                      width: double.infinity,
                      child: Image(
                        image: UrlValidator.getSafeImage(
                          simulation.imageUrl,
                          placeholder: 'assets/images/logo.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.58),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _buildOverlayTag(
                        simulation.isPremium ? 'PREMIUM' : 'OPEN',
                        simulation.isPremium
                            ? AppColors.tertiary
                            : AppColors.secondary,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _toggleFavorite(simulation.id),
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Row(
                        children: [
                          Text(
                            simulation.iconEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              simulation.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        simulation.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.62),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetaChip(
                              _difficultyLabel(simulation.difficulty)),
                          _buildMetaChip('${simulation.duration} min'),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${simulation.rating.toStringAsFixed(1)} / 5 • ${simulation.completionsCount} lancements',
                        style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.56),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildLaunchButton(
                          simulation,
                          label: simulation.isAccessible ? 'Lancer' : 'Premium',
                          onTap: () => _launchSimulation(simulation),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaunchButton(
    models.Simulation simulation, {
    required String label,
    required VoidCallback onTap,
  }) {
    final isLaunching = _launchingSimulationId == simulation.id;

    if (!simulation.isAccessible) {
      return OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tertiary,
          side: BorderSide(
            color: AppColors.tertiary.withValues(alpha: 0.3),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.lock_rounded, size: 18),
        label: Text(label),
      );
    }

    return ElevatedButton(
      onPressed: isLaunching ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: isLaunching
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildOverlayTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 1.2,
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

  Widget _buildSectionTitle({
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
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
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

  Widget _buildErrorState() {
    return Center(
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
                  Icons.home_outlined,
                  color: AppColors.error,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Impossible de charger Home',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rafraîchis pour récupérer ton profil, tes simulations et tes repères de progression.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onSurface.withValues(alpha: 0.64),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<models.Simulation> _recommended(_HomeBundle bundle) {
    final targetDifficulty = _difficultyForLevel(bundle.user.level);
    final accessible = bundle.simulations
        .where((simulation) => simulation.isAccessible)
        .toList();

    accessible.sort((left, right) {
      final leftScore = _recommendationScore(left, targetDifficulty);
      final rightScore = _recommendationScore(right, targetDifficulty);
      return rightScore.compareTo(leftScore);
    });

    return accessible.take(6).toList();
  }

  int _recommendationScore(
    models.Simulation simulation,
    String targetDifficulty,
  ) {
    var score = 0;
    if (simulation.difficulty == targetDifficulty) score += 40;
    if (_favoriteIds.contains(simulation.id)) score += 12;
    score += (simulation.rating * 10).round();
    score += min(simulation.completionsCount, 24);
    if (simulation.duration <= 12) score += 8;
    return score;
  }

  List<_HomeSkill> _buildSkills(models.User user) {
    return [
      _HomeSkill(
        label: 'Prononciation',
        score: _safeScore(user.avgPronunciation),
        color: AppColors.primary,
        icon: Icons.record_voice_over_rounded,
      ),
      _HomeSkill(
        label: 'Fluidité',
        score: _safeScore(user.avgFluency),
        color: AppColors.secondary,
        icon: Icons.waves_rounded,
      ),
      _HomeSkill(
        label: 'Grammaire',
        score: _safeScore(user.avgGrammar),
        color: AppColors.tertiary,
        icon: Icons.menu_book_rounded,
      ),
      _HomeSkill(
        label: 'Vocabulaire',
        score: _safeScore(user.avgVocabulary),
        color: const Color(0xFF3F51B5),
        icon: Icons.auto_stories_rounded,
      ),
    ];
  }

  _HomeSkill _bestSkill(models.User user) {
    final skills = _buildSkills(user)
      ..sort((a, b) => b.score.compareTo(a.score));
    return skills.first;
  }

  _HomeSkill _lowestSkill(models.User user) {
    final skills = _buildSkills(user)
      ..sort((a, b) => a.score.compareTo(b.score));
    return skills.first;
  }

  double _safeScore(double value) => value.clamp(0.0, 100.0);

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

  int _xpRemaining(models.User user) {
    final next = _nextLevelCeiling(user);
    if (next >= 99999) return 0;
    return max(next - user.xp, 0);
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

  String _difficultyForLevel(int level) {
    if (level <= 2) return 'beginner';
    if (level <= 4) return 'intermediate';
    return 'advanced';
  }

  String _difficultyLabel(String difficulty) {
    const labels = {
      'beginner': 'Débutant',
      'intermediate': 'Intermédiaire',
      'advanced': 'Avancé',
    };
    return labels[difficulty] ?? difficulty;
  }

  String _categoryLabel(String category) {
    const labels = {
      'pitch': 'Pitch',
      'interview': 'Entretien',
      'client_call': 'Appel client',
      'crisis': 'Crise',
      'negotiation': 'Négociation',
      'presentation': 'Présentation',
      'networking': 'Networking',
    };
    return labels[category] ?? category;
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

class _HomeBundle {
  final models.User user;
  final List<models.Simulation> simulations;

  const _HomeBundle({
    required this.user,
    required this.simulations,
  });
}

class _HomeSkill {
  final String label;
  final double score;
  final Color color;
  final IconData icon;

  const _HomeSkill({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });
}

class _HomeShortcut {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
