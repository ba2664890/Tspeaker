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
import 'session_vocale_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  static const _favoritesKey = 'practice.favorite_simulations';
  static const _lastStartedKey = 'practice.last_started_simulation';

  final TextEditingController _searchController = TextEditingController();
  late Future<_PracticeBundle> _bundleFuture;

  Set<String> _favoriteIds = <String>{};
  String? _lastStartedSimulationId;
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _searchQuery = '';
  String? _launchingSimulationId;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
    _loadLocalPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_PracticeBundle> _loadBundle() async {
    final results = await Future.wait([
      context.read<UserService>().getUserProfile(),
      context.read<SimulationService>().getSimulations(),
    ]);

    return _PracticeBundle(
      user: results[0] as models.User,
      simulations: results[1] as List<models.Simulation>,
    );
  }

  Future<void> _refresh() async {
    final future = _loadBundle();
    setState(() {
      _bundleFuture = future;
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

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != 'all' ||
      _selectedDifficulty != 'all';

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = 'all';
      _selectedDifficulty = 'all';
      _searchQuery = '';
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

  Future<void> _toggleFavorite(String simulationId) async {
    setState(() {
      if (_favoriteIds.contains(simulationId)) {
        _favoriteIds.remove(simulationId);
      } else {
        _favoriteIds.add(simulationId);
      }
    });
    await _persistFavorites();
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

    setState(() => _launchingSimulationId = simulation.id);

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
        await _refresh();
      }
    } catch (e) {
      if (mounted) {
        _showInfoSnackBar(
          'Impossible de démarrer la simulation pour le moment.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _launchingSimulationId = null);
      }
    }
  }

  void _openSimulationSheet(models.Simulation simulation) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isFavorite = _favoriteIds.contains(simulation.id);
        final isLaunching = _launchingSimulationId == simulation.id;

        return Container(
          margin: const EdgeInsets.only(top: 24),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      simulation.iconEmoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            simulation.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            simulation.description,
                            style: TextStyle(
                              color:
                                  AppColors.onSurface.withValues(alpha: 0.64),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Cette simulation a déjà été lancée ${simulation.completionsCount} fois et garde une note moyenne de ${simulation.rating.toStringAsFixed(1)} / 5.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _toggleFavorite(simulation.id);
                          if (mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        label: Text(
                          isFavorite ? 'Retirer' : 'Favori',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLaunching
                            ? null
                            : () {
                                Navigator.of(sheetContext).pop();
                                _launchSimulation(simulation);
                              },
                        icon: isLaunching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          simulation.isAccessible ? 'Lancer' : 'Premium',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PracticeBundle>(
      future: _bundleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorState();
        }

        final bundle = snapshot.data!;
        final filteredSimulations = _filteredSimulations(bundle.simulations);
        final accessibleSimulations = bundle.simulations
            .where((simulation) => simulation.isAccessible)
            .toList();
        final continueSimulation = bundle.simulations
            .where((simulation) => simulation.id == _lastStartedSimulationId)
            .cast<models.Simulation?>()
            .firstOrNull;
        final featured = _featuredSimulation(bundle.simulations);
        final dailyChallenge = _dailyChallenge(accessibleSimulations);
        final quickWin = _quickWin(accessibleSimulations);
        final recommended = _recommended(bundle);
        final favorites = bundle.simulations
            .where((simulation) => _favoriteIds.contains(simulation.id))
            .toList();
        final premiumCount = bundle.simulations
            .where((simulation) => simulation.isPremium)
            .length;
        final averageDuration = _averageDuration(bundle.simulations);
        final averageRating = _averageRating(
          accessibleSimulations.isEmpty
              ? bundle.simulations
              : accessibleSimulations,
        );

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
                          child: _buildTopBar(bundle.user),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeroCard(
                            user: bundle.user,
                            dailyChallenge: dailyChallenge,
                            quickWin: quickWin,
                            accessibleCount: accessibleSimulations.length,
                          ),
                          const SizedBox(height: 20),
                          _buildPracticeDigest(
                            accessibleCount: accessibleSimulations.length,
                            premiumCount: premiumCount,
                            favoritesCount: favorites.length,
                            averageDuration: averageDuration,
                            averageRating: averageRating,
                          ),
                          const SizedBox(height: 20),
                          _buildSearchCard(
                            filteredCount: filteredSimulations.length,
                            totalCount: bundle.simulations.length,
                          ),
                          const SizedBox(height: 20),
                          _buildQuickActions(
                            dailyChallenge: dailyChallenge,
                            quickWin: quickWin,
                            favoritesCount: favorites.length,
                            filteredSimulations: filteredSimulations,
                          ),
                          if (continueSimulation != null) ...[
                            const SizedBox(height: 20),
                            _buildContinueCard(continueSimulation),
                          ],
                          if (featured != null) ...[
                            const SizedBox(height: 20),
                            _buildFeaturedSection(featured),
                          ],
                          if (recommended.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildHorizontalSection(
                              title: 'Recommandé pour toi',
                              subtitle:
                                  'Des scénarios alignés avec ton niveau et ton rythme actuel.',
                              simulations: recommended,
                            ),
                          ],
                          if (favorites.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildHorizontalSection(
                              title: 'Tes favoris',
                              subtitle:
                                  'Retrouve rapidement les simulations que tu veux rejouer.',
                              simulations: favorites,
                            ),
                          ],
                          const SizedBox(height: 20),
                          _buildLibrarySection(
                            allSimulations: bundle.simulations,
                            filteredSimulations: filteredSimulations,
                          ),
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
              'Le practice lab se prépare...',
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
                    Icons.auto_stories_outlined,
                    color: AppColors.error,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Impossible de charger les pratiques',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rafraîchis pour récupérer le catalogue et les recommandations.',
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
            top: -90,
            right: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            top: 260,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 68, sigmaY: 68),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: 70,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 72, sigmaY: 72),
              child: Container(
                width: 210,
                height: 210,
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
        Expanded(
          child: Row(
            children: [
              Image.asset('assets/images/logo.png', width: 34, height: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Lab',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'Ton terrain d’entraînement intelligent',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildTopIconButton(
          icon: Icons.bolt_rounded,
          onTap: () => _showInfoSnackBar(
            'Astuce: utilise “Surprends-moi” pour sortir de ta zone de confort.',
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _showInfoSnackBar(
              'Ton niveau actuel influence déjà les recommandations.'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: UrlValidator.getSafeImage(user.avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
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

  Widget _buildHeroCard({
    required models.User user,
    required models.Simulation? dailyChallenge,
    required models.Simulation? quickWin,
    required int accessibleCount,
  }) {
    final levelLabel = _levelLabel(user.level);

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
            color: AppColors.secondary.withValues(alpha: 0.26),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -24,
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
            bottom: -34,
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
                    icon: Icons.auto_awesome_rounded,
                    label: levelLabel,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  const Spacer(),
                  _buildHeroPill(
                    icon: Icons.sports_score_rounded,
                    label: '$accessibleCount scénarios prêts',
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Pratique ciblée,\nplus vivante, plus utile.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                dailyChallenge != null
                    ? 'Défi du jour: ${dailyChallenge.title}. Objectif: répondre avec plus de précision et de naturel.'
                    : 'Choisis une simulation et transforme chaque prise de parole en progression concrète.',
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
                  if (dailyChallenge != null)
                    _buildHeroTag('Défi: ${dailyChallenge.iconEmoji}'),
                  if (quickWin != null)
                    _buildHeroTag('Quick win: ${quickWin.duration} min'),
                  _buildHeroTag(
                      'Langue native: ${_nativeLanguageLabel(user.nativeLanguage)}'),
                ],
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

  Widget _buildPracticeDigest({
    required int accessibleCount,
    required int premiumCount,
    required int favoritesCount,
    required int averageDuration,
    required double averageRating,
  }) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPÈRES',
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Le lab en un coup d’œil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quelques repères rapides pour choisir le bon niveau d’intensité avant de lancer ta prochaine session.',
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.64),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOTE MOY.',
                      style: const TextStyle(
                        color: AppColors.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${averageRating.toStringAsFixed(1)}/5',
                      style: const TextStyle(
                        color: AppColors.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                    child: _buildDigestStat(
                      icon: Icons.rocket_launch_rounded,
                      label: 'Ouvertes',
                      value: '$accessibleCount',
                      hint: 'prêtes à démarrer',
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildDigestStat(
                      icon: Icons.lock_open_rounded,
                      label: 'Premium',
                      value: '$premiumCount',
                      hint: 'capsules à débloquer',
                      color: AppColors.tertiary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildDigestStat(
                      icon: Icons.favorite_rounded,
                      label: 'Favoris',
                      value: '$favoritesCount',
                      hint: 'raccourcis personnels',
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _buildDigestStat(
                      icon: Icons.timer_outlined,
                      label: 'Tempo',
                      value: '$averageDuration min',
                      hint: 'durée type par session',
                      color: AppColors.onSurface,
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

  Widget _buildDigestStat({
    required IconData icon,
    required String label,
    required String value,
    required String hint,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
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
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.76),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(
              color: AppColors.onSurface.withValues(alpha: 0.56),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard({
    required int filteredCount,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Affiner la prochaine session',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasActiveFilters
                          ? '$filteredCount scénario${filteredCount > 1 ? 's' : ''} sur $totalCount correspondent à ton filtre actuel.'
                          : '$totalCount scénarios sont prêts à être explorés selon ton objectif du moment.',
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.62),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Réinitialiser'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Chercher un scénario, une ambiance ou un objectif',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          _buildFilterWrap(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchMetaChip(
                icon: Icons.dataset_rounded,
                label: '$filteredCount/$totalCount scénarios',
                highlighted: true,
              ),
              if (_selectedCategory != 'all')
                _buildSearchMetaChip(
                  icon: Icons.sell_outlined,
                  label: _categoryLabel(_selectedCategory),
                ),
              if (_selectedDifficulty != 'all')
                _buildSearchMetaChip(
                  icon: Icons.tune_rounded,
                  label: _difficultyLabel(_selectedDifficulty),
                  color: AppColors.secondary,
                ),
              if (_searchQuery.isNotEmpty)
                _buildSearchMetaChip(
                  icon: Icons.search_rounded,
                  label: '"$_searchQuery"',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchMetaChip({
    required IconData icon,
    required String label,
    Color color = AppColors.primary,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlighted
                ? color
                : AppColors.onSurface.withValues(alpha: 0.64),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? color : AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterWrap() {
    final categories = <MapEntry<String, String>>[
      const MapEntry('all', 'Tous'),
      const MapEntry('pitch', 'Pitch'),
      const MapEntry('interview', 'Entretiens'),
      const MapEntry('networking', 'Networking'),
      const MapEntry('negotiation', 'Négociation'),
      const MapEntry('presentation', 'Présentation'),
      const MapEntry('client_call', 'Client'),
    ];
    final difficulties = <MapEntry<String, String>>[
      const MapEntry('all', 'Tous niveaux'),
      const MapEntry('beginner', 'Débutant'),
      const MapEntry('intermediate', 'Intermédiaire'),
      const MapEntry('advanced', 'Avancé'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterGroup(
          label: 'Contextes',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories
                .map(
                  (entry) => _buildToggleChip(
                    label: entry.value,
                    selected: _selectedCategory == entry.key,
                    onTap: () => setState(() => _selectedCategory = entry.key),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildFilterGroup(
          label: 'Niveaux',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: difficulties
                .map(
                  (entry) => _buildToggleChip(
                    label: entry.value,
                    selected: _selectedDifficulty == entry.key,
                    onTap: () =>
                        setState(() => _selectedDifficulty = entry.key),
                    useSecondaryColor: true,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterGroup({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.onSurface.withValues(alpha: 0.48),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool useSecondaryColor = false,
  }) {
    final selectedColor =
        useSecondaryColor ? AppColors.secondary : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : AppColors.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions({
    required models.Simulation? dailyChallenge,
    required models.Simulation? quickWin,
    required int favoritesCount,
    required List<models.Simulation> filteredSimulations,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          eyebrow: 'MOMENTUM',
          title: 'Actions rapides',
          subtitle: 'Trois entrées immédiates pour te lancer sans friction.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 540
                    ? 2
                    : 1;
            const spacing = 12.0;
            final itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            final cards = [
              _buildQuickActionCard(
                title: 'Défi du jour',
                subtitle: dailyChallenge?.title ?? 'Aucune suggestion',
                icon: Icons.emoji_events_rounded,
                color: AppColors.primary,
                onTap: dailyChallenge == null
                    ? null
                    : () => _openSimulationSheet(dailyChallenge),
              ),
              _buildQuickActionCard(
                title: 'Surprends-moi',
                subtitle: 'Choix aléatoire intelligent',
                icon: Icons.casino_rounded,
                color: AppColors.secondary,
                onTap: filteredSimulations.isEmpty
                    ? null
                    : () => _openSimulationSheet(
                          filteredSimulations[
                              Random().nextInt(filteredSimulations.length)],
                        ),
              ),
              _buildQuickActionCard(
                title: 'Favoris',
                subtitle: '$favoritesCount sauvegardés',
                icon: Icons.favorite_rounded,
                color: AppColors.tertiary,
                onTap: favoritesCount == 0
                    ? null
                    : () => _showInfoSnackBar(
                          'Descends vers la section “Tes favoris” pour les relancer.',
                        ),
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: itemWidth,
                      child: card,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        if (quickWin != null) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openSimulationSheet(quickWin),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Win',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quickWin.title} • ${quickWin.duration} min pour débloquer un gain rapide de pratique.',
                          style: TextStyle(
                            color: AppColors.onSurface.withValues(alpha: 0.66),
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.58 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 164),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.62),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
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

  Widget _buildContinueCard(models.Simulation simulation) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'CONTINUER',
            title: 'Reprendre rapidement',
            subtitle: 'Ton dernier terrain de pratique reste à portée de main.',
          ),
          const SizedBox(height: 18),
          _buildVerticalSimulationCard(simulation, emphasizeResume: true),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(models.Simulation simulation) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'FEATURED',
            title: 'Scénario phare',
            subtitle:
                'Le plus fort potentiel d’impact si tu veux progresser sur une session marquante.',
          ),
          const SizedBox(height: 18),
          _buildLargeFeatureCard(simulation),
        ],
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
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 1100
                  ? 280.0
                  : constraints.maxWidth >= 720
                      ? 250.0
                      : max(210.0, min(280.0, constraints.maxWidth * 0.76));

              return SizedBox(
                height: 300,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: simulations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final simulation = simulations[index];
                    return SizedBox(
                      width: cardWidth,
                      child: _buildCompactSimulationCard(simulation),
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

  Widget _buildLibrarySection({
    required List<models.Simulation> allSimulations,
    required List<models.Simulation> filteredSimulations,
  }) {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            eyebrow: 'LIBRARY',
            title: 'Bibliothèque de pratique',
            subtitle:
                'Toutes tes simulations disponibles, filtrées selon ton envie du moment.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${filteredSimulations.length}/${allSimulations.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (filteredSimulations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aucun scénario trouvé',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essaie un autre filtre ou élargis ta recherche pour découvrir plus de contextes.',
                    style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.62),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredSimulations.map(
              (simulation) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildVerticalSimulationCard(simulation),
              ),
            ),
        ],
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

  Widget _buildLargeFeatureCard(models.Simulation simulation) {
    return GestureDetector(
      onTap: () => _openSimulationSheet(simulation),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border:
              Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 220,
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
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildOverlayTag(
                      simulation.isPremium ? 'PREMIUM' : 'OPEN',
                      simulation.isPremium
                          ? AppColors.tertiary
                          : AppColors.secondary,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(simulation.id),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _favoriteIds.contains(simulation.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          simulation.iconEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          simulation.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          simulation.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackActions = constraints.maxWidth < 430;
                  final metadata = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetaChip(_categoryLabel(simulation.category)),
                      _buildMetaChip(_difficultyLabel(simulation.difficulty)),
                      _buildMetaChip('${simulation.duration} min'),
                    ],
                  );
                  final cta = _buildSimulationCta(simulation);

                  if (stackActions) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        metadata,
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: cta,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: metadata),
                      const SizedBox(width: 12),
                      cta,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSimulationCard(models.Simulation simulation) {
    return GestureDetector(
      onTap: () => _openSimulationSheet(simulation),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border:
              Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: Image(
                      image: UrlValidator.getSafeImage(
                        simulation.imageUrl,
                        placeholder: 'assets/images/logo.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildOverlayTag(
                      simulation.iconEmoji,
                      Colors.black.withValues(alpha: 0.72),
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
                      simulation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      simulation.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMetaChip(_difficultyLabel(simulation.difficulty)),
                        _buildMetaChip('${simulation.duration} min'),
                      ],
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

  Widget _buildVerticalSimulationCard(
    models.Simulation simulation, {
    bool emphasizeResume = false,
  }) {
    final isFavorite = _favoriteIds.contains(simulation.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  simulation.iconEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    simulation.title,
                    maxLines: isCompact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              simulation.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.6),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaChip(_categoryLabel(simulation.category)),
                _buildMetaChip(_difficultyLabel(simulation.difficulty)),
                _buildMetaChip('${simulation.duration} min'),
              ],
            ),
          ],
        );
        final actionButton = _buildSimulationCta(
          simulation,
          label: emphasizeResume ? 'Reprendre' : null,
        );
        final favoriteButton = _buildSimulationIconAction(
          onTap: () => _toggleFavorite(simulation.id),
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => _openSimulationSheet(simulation),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: emphasizeResume
                    ? AppColors.secondary.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: emphasizeResume
                      ? AppColors.secondary.withValues(alpha: 0.2)
                      : AppColors.onSurface.withValues(alpha: 0.05),
                  width: emphasizeResume ? 2 : 1,
                ),
              ),
              child: isCompact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox(
                                width: 84,
                                height: 84,
                                child: Image(
                                  image: UrlValidator.getSafeImage(
                                    simulation.imageUrl,
                                    placeholder: 'assets/images/logo.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: details),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            favoriteButton,
                            const SizedBox(width: 12),
                            Expanded(child: actionButton),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: Image(
                              image: UrlValidator.getSafeImage(
                                simulation.imageUrl,
                                placeholder: 'assets/images/logo.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            favoriteButton,
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 132,
                              child: actionButton,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulationIconAction({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildSimulationCta(
    models.Simulation simulation, {
    String? label,
  }) {
    final isLaunching = _launchingSimulationId == simulation.id;
    final buttonLabel =
        label ?? (simulation.isAccessible ? 'Lancer' : 'Premium');

    if (!simulation.isAccessible) {
      return OutlinedButton.icon(
        onPressed: () => _launchSimulation(simulation),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tertiary,
          side: BorderSide(
            color: AppColors.tertiary.withValues(alpha: 0.3),
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        icon: const Icon(Icons.lock_rounded, size: 18),
        label: Text(buttonLabel),
      );
    }

    return ElevatedButton(
      onPressed: isLaunching ? null : () => _launchSimulation(simulation),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          : Text(buttonLabel),
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

  List<models.Simulation> _filteredSimulations(
    List<models.Simulation> simulations,
  ) {
    final query = _searchQuery.toLowerCase();

    return simulations.where((simulation) {
      final matchesCategory = _selectedCategory == 'all' ||
          simulation.category == _selectedCategory;
      final matchesDifficulty = _selectedDifficulty == 'all' ||
          simulation.difficulty == _selectedDifficulty;
      final haystack = [
        simulation.title,
        simulation.description,
        _categoryLabel(simulation.category),
        _difficultyLabel(simulation.difficulty),
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || haystack.contains(query);

      return matchesCategory && matchesDifficulty && matchesSearch;
    }).toList()
      ..sort(
        (left, right) => right.rating.compareTo(left.rating) != 0
            ? right.rating.compareTo(left.rating)
            : right.completionsCount.compareTo(left.completionsCount),
      );
  }

  models.Simulation? _featuredSimulation(List<models.Simulation> simulations) {
    if (simulations.isEmpty) return null;

    final ordered = [...simulations]..sort((left, right) {
        if (left.isAccessible != right.isAccessible) {
          return left.isAccessible ? -1 : 1;
        }
        if (right.rating.compareTo(left.rating) != 0) {
          return right.rating.compareTo(left.rating);
        }
        return right.completionsCount.compareTo(left.completionsCount);
      });
    return ordered.first;
  }

  models.Simulation? _dailyChallenge(List<models.Simulation> simulations) {
    if (simulations.isEmpty) return null;

    final index = DateTime.now().difference(DateTime(2026, 1, 1)).inDays.abs() %
        simulations.length;
    return simulations[index];
  }

  models.Simulation? _quickWin(List<models.Simulation> simulations) {
    if (simulations.isEmpty) return null;

    final ordered = [...simulations]..sort((left, right) {
        if (left.duration != right.duration) {
          return left.duration.compareTo(right.duration);
        }
        return right.rating.compareTo(left.rating);
      });
    return ordered.first;
  }

  List<models.Simulation> _recommended(_PracticeBundle bundle) {
    final targetDifficulty = _difficultyForLevel(bundle.user.level);
    final accessible = bundle.simulations
        .where((simulation) => simulation.isAccessible)
        .toList();

    accessible.sort((left, right) {
      final leftScore = _recommendationScore(left, targetDifficulty);
      final rightScore = _recommendationScore(right, targetDifficulty);
      return rightScore.compareTo(leftScore);
    });

    return accessible.take(5).toList();
  }

  int _recommendationScore(
    models.Simulation simulation,
    String targetDifficulty,
  ) {
    var score = 0;
    if (simulation.difficulty == targetDifficulty) score += 50;
    if (_favoriteIds.contains(simulation.id)) score += 12;
    score += (simulation.rating * 10).round();
    score += min(simulation.completionsCount, 30);
    if (simulation.duration <= 10) score += 8;
    return score;
  }

  int _averageDuration(List<models.Simulation> simulations) {
    if (simulations.isEmpty) return 0;
    final total = simulations.fold<int>(
      0,
      (sum, simulation) => sum + simulation.duration,
    );
    return (total / simulations.length).round();
  }

  double _averageRating(List<models.Simulation> simulations) {
    if (simulations.isEmpty) return 0;
    final total = simulations.fold<double>(
      0,
      (sum, simulation) => sum + simulation.rating,
    );
    return total / simulations.length;
  }

  String _difficultyForLevel(int level) {
    if (level <= 2) return 'beginner';
    if (level <= 4) return 'intermediate';
    return 'advanced';
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

  String _difficultyLabel(String difficulty) {
    const labels = {
      'beginner': 'Débutant',
      'intermediate': 'Intermédiaire',
      'advanced': 'Avancé',
    };
    return labels[difficulty] ?? difficulty;
  }

  String _nativeLanguageLabel(String language) {
    const labels = {
      'wolof': 'Wolof',
      'pulaar': 'Pulaar',
      'bambara': 'Bambara',
      'dioula': 'Dioula',
      'serer': 'Sérère',
      'french': 'Français',
      'other': 'Autre',
    };
    return labels[language] ?? language;
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1:
        return 'Départ guidé';
      case 2:
        return 'Base solide';
      case 3:
        return 'Montée en impact';
      case 4:
        return 'Voix affirmée';
      default:
        return 'Mode expert';
    }
  }
}

class _PracticeBundle {
  final models.User user;
  final List<models.Simulation> simulations;

  const _PracticeBundle({
    required this.user,
    required this.simulations,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
