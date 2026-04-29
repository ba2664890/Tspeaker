import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ResultatsScreen extends StatefulWidget {
  const ResultatsScreen({super.key});

  @override
  State<ResultatsScreen> createState() => _ResultatsScreenState();
}

class _ResultatsScreenState extends State<ResultatsScreen> {
  late ConfettiController _confettiController;

  final Map<String, int> _metrics = {
    'Prononciation': 92,
    'Fluidité': 78,
    'Grammaire': 88,
    'Vocabulaire': 81,
  };

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
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Confetti
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
              colors: [
                AppColors.primary,
                AppColors.secondary,
                AppColors.tertiary,
                AppColors.primaryContainer,
                AppColors.secondaryContainer,
              ],
            ),
          ),
          // Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'T.Speak',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Level 12',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  'Alex K.',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=100&h=100&fit=crop',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Results content
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Score circle
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // SVG-like circle progress
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: 0.85,
                                strokeWidth: 8,
                                backgroundColor: AppColors.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryContainer,
                                ),
                              ),
                            ),
                            Text(
                              '85',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'Excellent travail !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge(
                            icon: Icons.bolt,
                            text: '+150 XP',
                            backgroundColor: AppColors.secondaryContainer,
                            textColor: AppColors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          _buildBadge(
                            icon: Icons.military_tech,
                            text: 'STREAK 5',
                            backgroundColor: AppColors.tertiaryFixed,
                            textColor: AppColors.onTertiaryFixedVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Metrics grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: _metrics.entries.map((entry) {
                          return _buildMetricCard(
                            label: entry.key,
                            value: entry.value,
                            icon: _getIconForMetric(entry.key),
                            color: _getColorForMetric(entry.key),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      // AI Feedback Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDE6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.outlineVariant.withOpacity(0.2),
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
                                Icons.smart_toy,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Analyse de l\'IA',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Votre prononciation des sons "th" s\'est nettement améliorée. Pour la prochaine session, essayez de réduire les pauses entre les connecteurs logiques pour augmenter votre score de fluidité.',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      fontSize: 14,
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // CTA Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Prochaine session',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: BorderSide.none,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text(
                            'Partager mes progrès',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
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

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
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
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1B).withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value%',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMetric(String metric) {
    switch (metric) {
      case 'Prononciation':
        return Icons.record_voice_over;
      case 'Fluidité':
        return Icons.speed;
      case 'Grammaire':
        return Icons.spellcheck;
      case 'Vocabulaire':
        return Icons.menu_book;
      default:
        return Icons.star;
    }
  }

  Color _getColorForMetric(String metric) {
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
