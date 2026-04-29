import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/url_validator.dart';
import 'home_screen.dart';

class TestNiveauScreen extends StatefulWidget {
  const TestNiveauScreen({super.key});

  @override
  State<TestNiveauScreen> createState() => _TestNiveauScreenState();
}

class _TestNiveauScreenState extends State<TestNiveauScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isRecording = false;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _pulseController.repeat();
      });
    }
  }

  void _toggleRecording() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isRecording = !_isRecording;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            backgroundImage: UrlValidator.getSafeImage(
              'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=100&h=100&fit=crop',
            ),
          ),
        ),
        title: Text(
          'T.Speak',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Calibrons ton niveau 🎯',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                // Progress dots
                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: EdgeInsets.only(
                          right: index < 4 ? 8 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppColors.primary
                              : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          // AI Persona
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.1),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(
                      image: UrlValidator.getSafeImage(
                        'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=100&h=100&fit=crop',
                        placeholder: 'assets/images/logo.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: AppColors.outlineVariant.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A1C1B).withOpacity(0.04),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      '"Bienvenue ! Pour commencer, présente-toi en anglais : ton nom, ce que tu aimes faire et pourquoi tu souhaites apprendre aujourd\'hui."',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Recording area
          Column(
            children: [
              // Microphone with pulsing animation
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing circles
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final delay = index * 0.3;
                        final progress =
                            ((_pulseController.value - delay) % 1.0)
                                .clamp(0.0, 1.0);
                        return Container(
                          width: 200 + (progress * 100),
                          height: 200 + (progress * 100),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withOpacity(0.1 * (1 - progress)),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                  // Circular waveform
                  CustomPaint(
                    size: const Size(280, 280),
                    painter: WaveformPainter(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  // Mic button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Recording text
              Text(
                _isRecording ? 'Enregistrement...' : 'Appuie pour parler',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '0:15',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Transcription preview
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Text(
              'Ta voix apparaîtra ici...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
          // Skip button
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              });
            },
            child: Text(
              'Passer le test',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;

  WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw dashed circle
    const dashCount = 40;
    const dashLength = 4;
    const gapLength = 8;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashLength + gapLength)) / radius;
      final endAngle = startAngle + (dashLength / radius);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }

    // Draw inner circle
    final innerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 15, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
