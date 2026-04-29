import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ResultatsScreen extends StatefulWidget {
  final SessionResult? result;
  final String sessionTitle;
  final String primaryActionLabel;
  final bool returnToPreviousRoute;

  const ResultatsScreen({
    super.key,
    this.result,
    this.sessionTitle = 'Session vocale',
    this.primaryActionLabel = 'Prochaine session',
    this.returnToPreviousRoute = false,
  });

  @override
  State<ResultatsScreen> createState() => _ResultatsScreenState();
}

class _ResultatsScreenState extends State<ResultatsScreen> {
  late ConfettiController _confettiController;

  SessionResult get _result =>
      widget.result ??
      SessionResult(
        overallScore: 85,
        xpEarned: 150,
        streak: 5,
        metrics: const {
          'Prononciation': 92,
          'Fluidité': 78,
          'Grammaire': 88,
          'Vocabulaire': 81,
        },
        aiFeedback:
            'Ta prise de parole progresse bien. Continue à réduire les pauses et à varier ton vocabulaire pour gagner encore en impact.',
      );

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _result.metrics.entries.toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.tertiary,
                AppColors.primaryContainer,
                AppColors.secondaryContainer,
              ],
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                    child: Row(
                      children: [
                        Text(
                          'T.Speak',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.sessionTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeroScore(),
                      const SizedBox(height: 28),
                      _buildHighlights(),
                      const SizedBox(height: 28),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.25,
                        children: metrics.map((entry) {
                          return _buildMetricCard(
                            label: entry.key,
                            value: entry.value,
                            icon: _iconForMetric(entry.key),
                            color: _colorForMetric(entry.key),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      _buildFeedbackCard(),
                      const SizedBox(height: 28),
                      _buildActionButtons(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScore() {
    final score = _result.overallScore.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1C1B),
            Color(0xFF7A2A00),
            Color(0xFFE46C2F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 134,
            height: 134,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 134,
                  height: 134,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFD47A),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 44,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _headlineForScore(score),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ta session est enregistrée et l’IA a déjà préparé ton feedback de progression.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Row(
      children: [
        Expanded(
          child: _buildBadgeCard(
            icon: Icons.bolt_rounded,
            title: '+${_result.xpEarned} XP',
            subtitle: 'Récompense session',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBadgeCard(
            icon: Icons.local_fire_department_rounded,
            title: '${_result.streak} jours',
            subtitle: 'Série actuelle',
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
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

  Widget _buildMetricCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE6),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyse de l’IA',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _result.aiFeedback,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton(
            onPressed: () {
              if (widget.returnToPreviousRoute) {
                Navigator.of(context).pop();
                return;
              }

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.primaryActionLabel),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded),
            label: const Text('Partager mes progrès'),
            style: OutlinedButton.styleFrom(
              side: BorderSide.none,
              backgroundColor: AppColors.surfaceContainerHigh,
              foregroundColor: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _headlineForScore(int score) {
    if (score >= 90) return 'Très forte session';
    if (score >= 80) return 'Excellent travail';
    if (score >= 70) return 'Belle progression';
    if (score >= 60) return 'Base prometteuse';
    return 'Continue, tu progresses';
  }

  IconData _iconForMetric(String metric) {
    switch (metric) {
      case 'Prononciation':
        return Icons.record_voice_over_rounded;
      case 'Fluidité':
        return Icons.speed_rounded;
      case 'Grammaire':
        return Icons.spellcheck_rounded;
      case 'Vocabulaire':
        return Icons.menu_book_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  Color _colorForMetric(String metric) {
    switch (metric) {
      case 'Prononciation':
        return AppColors.secondary;
      case 'Fluidité':
        return AppColors.primary;
      case 'Grammaire':
        return AppColors.tertiary;
      case 'Vocabulaire':
        return AppColors.primaryContainer;
      default:
        return AppColors.primary;
    }
  }
}
