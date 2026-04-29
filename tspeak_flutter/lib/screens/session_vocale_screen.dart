import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/patterns_painter.dart';
import '../widgets/top_app_bar.dart';
import '../services/speech_service.dart';
import '../services/user_service.dart';
import '../models/user.dart' as models;
import 'resultats_screen.dart';

class SessionVocaleScreen extends StatefulWidget {
  const SessionVocaleScreen({super.key});

  @override
  State<SessionVocaleScreen> createState() => _SessionVocaleScreenState();
}

class _SessionVocaleScreenState extends State<SessionVocaleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _currentPath;
  late Future<models.User> _userFuture;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _userFuture = context.read<UserService>().getUserProfile();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordingSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _currentPath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: _currentPath!);
        
        setState(() {
          _isRecording = true;
        });
        _startTimer();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _stopTimer();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _showLoadingDialog();
        await context.read<SpeechService>().uploadAudio('session_123', path);
        if (mounted) {
           Navigator.pop(context); // Pop loading
           Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultatsScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de traitement: $e')));
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Analyse par T.AI...',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User>(
      future: _userFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          body: BackgroundWrapper(
            child: Column(
              children: [
                TopAppBar(
                  showProfile: true,
                  profileImageUrl: user?.avatarUrl,
                  level: user?.level,
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.onSurface),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(),
                        // AI Avatar Section
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildPulseRing(1, 0.0),
                            _buildPulseRing(1.5, 0.3),
                            _buildPulseRing(2, 0.6),
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 8),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1677442136019-21780ecad995?w=300'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.onSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'T.AI',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        
                        // Interaction Bubble
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onSurface.withOpacity(0.04),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Text(
                            '"Comment se passe ta journée ?"',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        
                        // Transcription Zone
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildWord('Ma', isCorrect: true),
                            const SizedBox(width: 8),
                            _buildWord('journée', isCorrect: true),
                            const SizedBox(width: 8),
                            _buildWord('se', isCorrect: true),
                            const SizedBox(width: 8),
                            _buildWord('p... ', isCorrect: null, isFading: true),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Timer & Mic
                        Text(
                          '00:${_recordingSeconds.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontFamily: 'SpaceMono',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        GestureDetector(
                          onTap: _isRecording ? _stopRecording : _startRecording,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isRecording 
                                  ? [AppColors.onSurface, AppColors.onSurface.withOpacity(0.8)]
                                  : [AppColors.primary, AppColors.primaryContainer],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? AppColors.onSurface : AppColors.primary).withOpacity(0.3),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Footer Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFooterAction(Icons.pause_rounded),
                            const SizedBox(width: 24),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('TERMINER'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.onSurface,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseRing(double scale, double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final val = (_pulseController.value + delay) % 1.0;
        return Container(
          width: 140 * (1 + val * 0.5 * scale),
          height: 140 * (1 + val * 0.5 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2 * (1 - val)),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWord(String word, {bool? isCorrect, bool isFading = false}) {
    Color color = AppColors.onSurface;
    if (isFading) color = color.withOpacity(0.3);
    else if (isCorrect == true) color = AppColors.secondary;
    else if (isCorrect == false) color = AppColors.error;

    return Text(
      word,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        fontFamily: 'SpaceMono',
      ),
    );
  }

  Widget _buildFooterAction(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.onSurface.withOpacity(0.6)),
    );
  }
}
