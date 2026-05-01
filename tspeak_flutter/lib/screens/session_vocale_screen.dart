import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/user.dart' as models;
import '../services/speech_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/url_validator.dart';
import '../widgets/patterns_painter.dart';
import 'resultats_screen.dart';
import '../utils/safe_ui.dart';

class SessionVocaleScreen extends StatefulWidget {
  final String? sessionId;
  final String title;
  final String openingMessage;
  final bool embeddedInHome;
  final VoidCallback? onClose;
  final VoidCallback? onComplete;

  const SessionVocaleScreen({
    super.key,
    this.sessionId,
    this.title = 'Conversation guidée',
    this.openingMessage = 'Hello! Tell me about yourself and your goals today.',
    this.embeddedInHome = false,
    this.onClose,
    this.onComplete,
  });

  @override
  State<SessionVocaleScreen> createState() => _SessionVocaleScreenState();
}

class _SessionVocaleScreenState extends State<SessionVocaleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final AudioRecorder _audioRecorder = AudioRecorder();

  late Future<models.User> _userFuture;
  Timer? _timer;

  bool _isRecording = false;
  bool _isPreparingSession = true;
  bool _isProcessing = false;
  int _recordingSeconds = 0;
  String? _sessionId;
  String? _currentPath;
  String? _errorMessage;
  late String _currentQuestion;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
    _userFuture = context.read<UserService>().getUserProfile();
    _currentQuestion = widget.openingMessage;
    _bootstrapSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    SafeUI.handleAnimationReassemble(_pulseController, state: this);
  }

  Future<void> _bootstrapSession() async {
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _sessionId = widget.sessionId;
            _isPreparingSession = false;
          });
        }
      });
      return;
    }

    try {
      final session = await context.read<SpeechService>().startSessionDetails();

      if (!mounted) return;

      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _sessionId = session?.sessionId;
            if (session != null) {
              _currentQuestion = session.firstQuestion;
            }
            _isPreparingSession = false;
            _errorMessage =
                session == null ? 'Impossible de créer la session vocale.' : null;
          });
        }
      });
    } catch (_) {
      if (!mounted) return;
      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _isPreparingSession = false;
            _errorMessage = 'Impossible de préparer la session vocale.';
          });
        }
      });
    }
  }

  Future<void> _retrySession() async {
    _stopTimer();

    if (mounted) {
    SafeUI.run(() {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPreparingSession = true;
          _isProcessing = false;
          _recordingSeconds = 0;
          _sessionId = null;
          _currentPath = null;
          _errorMessage = null;
          _currentQuestion = widget.openingMessage;
        });
      }
    });
    }

    await _bootstrapSession();
  }

  Future<void> _handleExit() async {
    if (_isRecording) {
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      _stopTimer();
    }

    if (mounted) {
      if (_pulseController.isAnimating) _pulseController.stop();
      SafeUI.setState(this, () => _isRecording = false);
    }

    if (widget.onClose != null) {
      widget.onClose!.call();
      return;
    }

    await Navigator.of(context).maybePop();
  }

  void _startTimer() {
    _recordingSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      SafeUI.setState(this, () => _recordingSeconds += 1);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _startRecording() async {
    if (_sessionId == null || _isPreparingSession || _isProcessing) return;

    try {
      if (!await _audioRecorder.hasPermission()) {
        _showInfoSnackBar('Autorise le micro pour commencer la pratique.',
            isError: true);
        return;
      }

      final directory = await getTemporaryDirectory();
      _currentPath =
          '${directory.path}/practice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig();
      await _audioRecorder.start(config, path: _currentPath!);

      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _isRecording = true;
            _errorMessage = null;
          });
        }
      });
      _startTimer();
    } catch (e) {
      _showInfoSnackBar('Impossible de démarrer l’enregistrement.',
          isError: true);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _stopTimer();

      if (!mounted) return;

      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _isRecording = false;
          });
        }
      });

      if (path == null || _sessionId == null) {
        _showInfoSnackBar('Aucun audio à analyser.', isError: true);
        return;
      }

      await _processRecording(path);
    } catch (e) {
      _showInfoSnackBar('Erreur pendant l’arrêt de l’enregistrement.',
          isError: true);
    }
  }

  Future<void> _processRecording(String path) async {
    SafeUI.run(() {
      if (mounted) {
        setState(() {
          _isProcessing = true;
          _errorMessage = null;
        });
      }
    });

    try {
      final speechService = context.read<SpeechService>();
      final upload = await speechService.uploadAudio(
        _sessionId!,
        path,
        question: _currentQuestion,
        durationSec: _recordingSeconds.toDouble(),
      );

      final exchangeId = upload?['exchange_id']?.toString();
      if (exchangeId == null || exchangeId.isEmpty) {
        throw Exception('Upload échoué');
      }

      final uploadStatus = upload?['status']?.toString();
      final exchangeResult = uploadStatus == 'completed'
          ? upload
          : await speechService.waitForExchangeResult(exchangeId);
      if (exchangeResult == null) {
        throw Exception('Résultat indisponible');
      }
      if (exchangeResult['success'] == false ||
          exchangeResult['status'] == 'failed') {
        final error = exchangeResult['error'];
        final message = error is Map
            ? error['message']?.toString()
            : 'Traitement audio échoué';
        throw Exception(message ?? 'Traitement audio échoué');
      }

      final exchangeData =
          (exchangeResult['data'] ?? exchangeResult) as Map<String, dynamic>;

      final endResponse = await speechService.endSession(
        _sessionId!,
        durationSec: _recordingSeconds,
      );
      final scoreResponse = await speechService.getSessionScores(_sessionId!);
      final scoreData = (scoreResponse?['data'] ?? const <String, dynamic>{})
          as Map<String, dynamic>;

      final pronunciation = (scoreData['pronunciation'] ??
              exchangeData['pronunciation_score'] ??
              0)
          .round();
      final fluency =
          (scoreData['fluency'] ?? exchangeData['fluency_score'] ?? 0).round();
      final grammar =
          (scoreData['grammar'] ?? exchangeData['grammar_score'] ?? 0).round();
      final vocabulary =
          (scoreData['vocabulary'] ?? exchangeData['vocabulary_score'] ?? 0)
              .round();
      final overall =
          (scoreData['global_score'] ?? exchangeData['global_score'] ?? 0)
              .round();
      final xpEarned = (endResponse?['xp_earned'] ?? 0) as int;
      final streak = (endResponse?['streak_days'] ?? 0) as int;

      if (!mounted) return;

      final resultsScreen = MaterialPageRoute<void>(
        builder: (_) => ResultatsScreen(
          sessionTitle: widget.title,
          primaryActionLabel: 'Retour au Home',
          returnToPreviousRoute: widget.embeddedInHome,
          result: models.SessionResult(
            overallScore: overall,
            xpEarned: xpEarned,
            streak: streak,
            metrics: {
              'Prononciation': pronunciation,
              'Fluidité': fluency,
              'Grammaire': grammar,
              'Vocabulaire': vocabulary,
            },
            aiFeedback: (scoreData['feedback_text'] ??
                    exchangeData['ai_feedback'] ??
                    'Bonne base. Continue pour stabiliser tes progrès.')
                .toString(),
          ),
          onContinueSession: () {
            // Reset state so user can record another exchange in same session
            if (mounted) {
              SafeUI.run(() {
                if (mounted) {
                  setState(() {
                    _isRecording = false;
                    _isProcessing = false;
                    _recordingSeconds = 0;
                    _errorMessage = null;
                    _currentPath = null;
                    // sessionId is preserved to continue the same backend session
                  });
                  if (!_pulseController.isAnimating) {
                    _pulseController.repeat();
                  }
                }
              });
            }
          },
        ),
      );

      if (widget.embeddedInHome) {
        SafeUI.navigate(context, (ctx) async {
          if (_pulseController.isAnimating) _pulseController.stop();
          await Navigator.of(ctx).push(resultsScreen);
          if (mounted) {
            // Give extra frame for the pop transition to settle
            await Future.delayed(const Duration(milliseconds: 32));
            if (mounted) {
              widget.onComplete?.call();
            }
          }
        }, extended: true);
      } else {
        SafeUI.navigate(context, (ctx) {
          if (_pulseController.isAnimating) _pulseController.stop();
          Navigator.of(ctx).pushReplacement(resultsScreen);
        }, extended: true);
      }
    } catch (e) {
      if (!mounted) return;
      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Le traitement a échoué. Réessaie avec une réponse plus courte et plus claire.';
          });
        }
      });
      _showInfoSnackBar(
        'Le traitement de la réponse n’a pas abouti.',
        isError: true,
      );
    } finally {
      if (mounted) {
      SafeUI.run(() {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
      }
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
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
        final user = snapshot.data;

        return Scaffold(
          body: BackgroundWrapper(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  children: [
                    _buildTopBar(user),
                    const SizedBox(height: 18),
                    _buildHeaderCard(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
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
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPulseRingStack(user),
                              const SizedBox(height: 34),
                              _buildQuestionCard(),
                              const SizedBox(height: 34),
                              _buildStatusPanel(),
                              const SizedBox(height: 28),
                              _buildTimerDisplay(),
                              const SizedBox(height: 22),
                              _buildMicButton(),
                              const SizedBox(height: 16),
                              _buildInstructionText(),
                              if (!_isPreparingSession &&
                                  !_isProcessing &&
                                  (_errorMessage != null ||
                                      _sessionId == null)) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: _retrySession,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Relancer la session'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(models.User? user) {
    return Row(
      children: [
        GestureDetector(
          onTap: _handleExit,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                _sessionId != null ? 'Session active' : 'Session en attente',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (user != null)
          CircleAvatar(
            radius: 20,
            backgroundImage: UrlValidator.getSafeImage(user.avatarUrl),
          ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Objectif de cette prise',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Réponds naturellement, avec une phrase claire et une intention solide.',
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

  Widget _buildStatusPanel() {
    final statusText = _errorMessage ??
        (_isPreparingSession
            ? 'Création de la session...'
            : _isProcessing
                ? 'Traitement de ta réponse par l’IA...'
                : _sessionId == null
                    ? 'Session indisponible'
                    : 'Micro prêt, respire et lance ta réponse.');

    final statusColor = _errorMessage != null
        ? AppColors.error
        : _isProcessing
            ? AppColors.tertiary
            : AppColors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _errorMessage != null
                  ? Icons.error_outline_rounded
                  : _isProcessing
                      ? Icons.auto_awesome_rounded
                      : Icons.check_circle_outline_rounded,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPulseRingStack(models.User? user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildPulseRing(1.0, 0.0),
        _buildPulseRing(1.35, 0.25),
        _buildPulseRing(1.7, 0.5),
        Container(
          width: 138,
          height: 138,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 8,
            ),
            image: DecorationImage(
              image: UrlValidator.getSafeImage(
                user?.avatarUrl,
                placeholder: 'assets/images/logo.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.onSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'YOUR TURN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: const Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 4,
          ),
        ),
      ),
      child: Text(
        '"$_currentQuestion"',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Text(
      '00:${_recordingSeconds.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _isPreparingSession || _isProcessing
          ? null
          : (_isRecording ? _stopRecording : _startRecording),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 98,
        height: 98,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isRecording
                ? [
                    AppColors.onSurface,
                    AppColors.onSurface.withValues(alpha: 0.82),
                  ]
                : [
                    AppColors.primary,
                    AppColors.primaryContainer,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? AppColors.onSurface : AppColors.primary)
                  .withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }

  Widget _buildInstructionText() {
    return Text(
      _isPreparingSession
          ? 'Préparation de la session...'
          : _isProcessing
              ? 'Analyse en cours...'
              : _isRecording
                  ? 'Appuie pour terminer'
                  : 'Appuie pour répondre',
      style: TextStyle(
        color: AppColors.onSurface.withValues(alpha: 0.6),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildPulseRing(double scale, double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = (_pulseController.value + delay) % 1.0;
        return Container(
          width: 138 * (1 + value * 0.4 * scale),
          height: 138 * (1 + value * 0.4 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2 * (1 - value)),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
