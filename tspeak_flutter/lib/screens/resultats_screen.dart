import 'dart:ui';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/patterns_painter.dart';

class ResultatsScreen extends StatefulWidget {
  final SessionResult? result;
  final String sessionTitle;
  final String primaryActionLabel;
  final bool returnToPreviousRoute;
  final VoidCallback? onContinueSession;

  const ResultatsScreen({
    super.key,
    this.result,
    this.sessionTitle = 'Session vocale',
    this.primaryActionLabel = 'Retour au Home',
    this.returnToPreviousRoute = false,
    this.onContinueSession,
  });

  @override
  State<ResultatsScreen> createState() => _ResultatsScreenState();
}

class _ResultatsScreenState extends State<ResultatsScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  SessionResult get _result =>
      widget.result ??
      SessionResult(
        overallScore: 0,
        xpEarned: 0,
        streak: 0,
        metrics: const {
          'Prononciation': 0,
          'Fluidité': 0,
          'Grammaire': 0,
          'Vocabulaire': 0,
        },
        aiFeedback: 'Aucun retour disponible pour cette session.',
      );

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    if ((_result.overallScore) >= 70) {
      _confettiController.play();
    }
    _animController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _confettiController.stop();
    _animController.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confettiController.play();
        _animController.forward(from: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: Stack(
          children: [
            // Ambient blobs
            _buildAmbientBlobs(),

            // Main scrollable content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Top bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _buildTopBar(),
                        ),
                      ),
                      // Content
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildScoreHeroCard(),
                            const SizedBox(height: 20),
                            _buildXpStreakRow(),
                            const SizedBox(height: 20),
                            _buildMetricsGrid(),
                            const SizedBox(height: 20),
                            _buildAiFeedbackCard(),
                            const SizedBox(height: 28),
                            _buildActionButtons(),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Confetti on top
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.04,
                numberOfParticles: 40,
                gravity: 0.18,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBlobs() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.08),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: IconButton(
                onPressed: () {
                  _confettiController.stop();
                  _animController.stop();
                  if (widget.returnToPreviousRoute) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
                  }
                },
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.onSurface),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RÉSULTATS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sessionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _scoreColor(_result.overallScore).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _scoreColor(_result.overallScore).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            _scoreBadge(_result.overallScore),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _scoreColor(_result.overallScore),
              letterSpacing: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHeroCard() {
    final score = _result.overallScore.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [Color(0xFF13252D), Color(0xFF006B55), Color(0xFFE46C2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 9,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD47A)),
                            strokeCap: StrokeCap.round,
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
                                fontSize: 36,
                                height: 1,
                              ),
                            ),
                            Text(
                              '/100',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _headlineForScore(score),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ta prise de parole a été analysée par l\'IA sur 4 critères.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpStreakRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.secondary,
            label: 'XP GAGNÉS',
            value: '+${_result.xpEarned}',
            bg: AppColors.secondary.withValues(alpha: 0.07),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.tertiary,
            label: 'SÉRIE',
            value: '${_result.streak} JOURS',
            bg: AppColors.tertiary.withValues(alpha: 0.07),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = _result.metrics.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DÉTAIL PAR CRITÈRE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 2,
            color: AppColors.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: metrics.map((entry) {
            return _buildMetricCard(
              label: entry.key,
              value: entry.value,
              icon: _iconForMetric(entry.key),
              color: _colorForMetric(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                '$value%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyse de l\'IA',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _result.aiFeedback,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
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
        // Primary: Continue Session
        if (widget.onContinueSession != null) ...[
          SizedBox(
            width: double.infinity,
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF00A882)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  _confettiController.stop();
                  _animController.stop();
                  Navigator.of(context).pop();
                  widget.onContinueSession!();
                },
                icon: const Icon(Icons.mic_rounded, color: Colors.white),
                label: const Text(
                  'Continuer la session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Secondary: Go Home
        SizedBox(
          width: double.infinity,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF13252D), AppColors.onSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                _confettiController.stop();
                _animController.stop();
                if (widget.returnToPreviousRoute) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
                }
              },
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: Text(
                widget.primaryActionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tertiary: Share
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Partager mes progrès'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _headlineForScore(int score) {
    if (score >= 90) return 'Session exceptionnelle ! 🔥';
    if (score >= 80) return 'Excellent travail !';
    if (score >= 70) return 'Belle progression ! 💪';
    if (score >= 60) return 'Base prometteuse';
    if (score > 0) return 'Continue, tu progresses';
    return 'Session enregistrée';
  }

  String _scoreBadge(int score) {
    if (score >= 90) return '🏆 EXCELLENT';
    if (score >= 75) return '⭐ TRÈS BON';
    if (score >= 60) return '✓ BON';
    if (score > 0) return 'EN PROGRÈS';
    return 'COMPLET';
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.secondary;
    if (score >= 50) return AppColors.tertiary;
    return AppColors.primary;
  }

  IconData _iconForMetric(String metric) {
    switch (metric) {
      case 'Prononciation': return Icons.record_voice_over_rounded;
      case 'Fluidité': return Icons.speed_rounded;
      case 'Grammaire': return Icons.spellcheck_rounded;
      case 'Vocabulaire': return Icons.menu_book_rounded;
      default: return Icons.insights_rounded;
    }
  }

  Color _colorForMetric(String metric) {
    switch (metric) {
      case 'Prononciation': return AppColors.secondary;
      case 'Fluidité': return AppColors.primary;
      case 'Grammaire': return AppColors.tertiary;
      case 'Vocabulaire': return const Color(0xFF6750A4);
      default: return AppColors.primary;
    }
  }
}
