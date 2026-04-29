import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'resultats_screen.dart';

class SimulationActiveScreen extends StatefulWidget {
  const SimulationActiveScreen({super.key});

  @override
  State<SimulationActiveScreen> createState() => _SimulationActiveScreenState();
}

class _SimulationActiveScreenState extends State<SimulationActiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        title: Row(
          children: [
            Text(
              'T.Speak',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 24,
              width: 1,
              color: AppColors.surfaceContainerHigh,
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer,
                    size: 14,
                    color: AppColors.onErrorContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '4:32',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.onSurface,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=100&h=100&fit=crop',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: AppColors.surfaceContainerLow,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Progress header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIMULATION EN COURS',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pitch Investisseur',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Question 2/5',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 128,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Meeting room environment
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1C1B).withOpacity(0.1),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop',
                            fit: BoxFit.cover,
                            color: Colors.white.withOpacity(0.6),
                            colorBlendMode: BlendMode.overlay,
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.surfaceContainerLow.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Investor avatars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Investor 1
                            _buildInvestorAvatar(
                              name: 'Dr. Kofi',
                              imageUrl:
                                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
                              isActive: false,
                            ),
                            const SizedBox(width: 24),
                            // Active investor (center)
                            _buildInvestorAvatar(
                              name: 'Sarah C.',
                              imageUrl:
                                  'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&h=150&fit=crop',
                              isActive: true,
                            ),
                            const SizedBox(width: 24),
                            // Investor 3
                            _buildInvestorAvatar(
                              name: 'Mr. W.',
                              imageUrl:
                                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop',
                              isActive: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Dialogue bubble
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(32),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A1C1B).withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '"Votre modèle de revenus semble solide, mais comment prévoyez-vous de gérer la montée en charge technologique dans les zones à faible connectivité ?"',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: AppColors.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                      // Arrow
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.surfaceContainerHigh,
                              ),
                              left: BorderSide(
                                color: AppColors.surfaceContainerHigh,
                              ),
                            ),
                          ),
                          transform: Matrix4.rotationZ(0.785),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Recording zone
                  Column(
                    children: [
                      // Waveform
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(12, (index) {
                          final heights = [24, 48, 64, 32, 56, 40, 72, 54, 36, 48, 28, 16];
                          return AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              final offset = index * 0.1;
                              final scale = 0.8 + (0.4 * ((_waveController.value + offset) % 1.0));
                              return Container(
                                width: 6,
                                height: heights[index] * scale,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: index % 2 == 0
                                      ? AppColors.primaryContainer
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pause button
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.pause,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Mic button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isRecording = !_isRecording;
                              });
                              // Navigate to results after "recording"
                              if (_isRecording) {
                                Future.delayed(const Duration(seconds: 2), () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ResultatsScreen(),
                                    ),
                                  );
                                });
                              }
                            },
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Skip button
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.skip_next,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Appuyez pour répondre'.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestorAvatar({
    required String name,
    required String imageUrl,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            Container(
              width: isActive ? 120 : 90,
              height: isActive ? 120 : 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.surface,
                  width: isActive ? 4 : 3,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 40,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                        ),
                      ],
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            name,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
