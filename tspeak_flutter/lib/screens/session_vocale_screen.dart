import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
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

class _SessionVocaleScreenState extends State<SessionVocaleScreen> {
  static const MethodChannel _ttsChannel = MethodChannel('tspeak/tts');
  final AudioRecorder _audioRecorder = AudioRecorder();

  late Future<models.User> _userFuture;
  Timer? _timer;

  bool _isRecording = false;
  bool _isPreparingSession = true;
  bool _isProcessing = false;
  int _recordingSeconds = 0;
  int _totalSessionSeconds = 0;
  String? _sessionId;
  String? _currentPath;
  String? _errorMessage;
  String _lastTranscription = '';
  bool _hasEndedSession = false;
  bool _isSpeakingQuestion = false;
  bool _hasAutoSpokenFirstQuestion = false;
  models.SessionResult? _lastSessionResult;
  String _lastNextQuestion = '';
  late String _currentQuestion;
  bool _showResultsOverlay = false;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserService>().getUserProfile();
    _currentQuestion = widget.openingMessage;
    _bootstrapSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopSpeakingQuestion(updateState: false);
    _audioRecorder.dispose();
    super.dispose();
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
      await _autoSpeakFirstQuestion();
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
            _errorMessage = session == null
                ? 'Impossible de créer la session vocale.'
                : null;
          });
        }
      });
      if (session != null) {
        await _autoSpeakFirstQuestion();
      }
    } on SpeechServiceException catch (e) {
      if (!mounted) return;
      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _isPreparingSession = false;
            _errorMessage = e.code == 'SESSION_LIMIT_REACHED'
                ? e.message
                : 'Impossible de préparer la session vocale. ${e.message}';
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
            _totalSessionSeconds = 0;
            _sessionId = null;
            _currentPath = null;
            _errorMessage = null;
            _lastTranscription = '';
            _hasEndedSession = false;
            _isSpeakingQuestion = false;
            _hasAutoSpokenFirstQuestion = false;
            _lastSessionResult = null;
            _lastNextQuestion = '';
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
    await _stopSpeakingQuestion();

    if (mounted) {
      SafeUI.setState(this, () => _isRecording = false);
    }

    await _endCurrentSession();

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
      await _stopSpeakingQuestion();
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
    final exchangeDurationSec = _recordingSeconds;
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
        durationSec: exchangeDurationSec.toDouble(),
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
      final transcription = (exchangeData['transcription'] ?? '').toString();
      final nextQuestion = (exchangeData['ai_response'] ??
              exchangeData['next_question'] ??
              _currentQuestion)
          .toString();
      _totalSessionSeconds += exchangeDurationSec;

      if (!mounted) return;

      final sessionResult = models.SessionResult(
        overallScore: overall,
        xpEarned: 0,
        streak: 0,
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
        transcription: transcription,
        durationSec: exchangeDurationSec,
        nextQuestion:
            nextQuestion.isNotEmpty ? nextQuestion : 'Can you tell me more?',
      );

      SafeUI.run(() {
        if (mounted) {
          setState(() {
            _lastSessionResult = sessionResult;
            _lastNextQuestion = sessionResult.nextQuestion;
          });
        }
      });

      _openResults(sessionResult, sessionResult.nextQuestion);
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

  void _continueWithQuestion(models.SessionResult result, String nextQuestion) {
    if (!mounted) return;

    // Fermer l'overlay de résultats
    SafeUI.run(() {
      if (mounted) {
        setState(() => _showResultsOverlay = false);
      }
    });

    // Réinitialiser pour la prochaine question
    SafeUI.run(() {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isProcessing = false;
          _recordingSeconds = 0;
          _errorMessage = null;
          _currentPath = null;
          _lastTranscription = result.transcription;
          _currentQuestion =
              nextQuestion.isNotEmpty ? nextQuestion : 'Can you tell me more?';
        });
      }
    });
  }

  void _openResults(
    models.SessionResult result,
    String nextQuestion, {
    bool previewOnly = false,
  }) {
    if (previewOnly) {
      // Mode preview: naviguer normalement
      final resultsScreen = MaterialPageRoute<void>(
        builder: (_) => ResultatsScreen(
          sessionTitle: widget.title,
          primaryActionLabel: 'Retour à la pratique',
          returnToPreviousRoute: true,
          result: result,
          onFinishSession: null,
          onContinueSession: () => _continueWithQuestion(result, nextQuestion),
        ),
      );
      SafeUI.navigate(context, (ctx) {
        Navigator.of(ctx).push(resultsScreen);
      }, extended: true);
    } else {
      // Mode normal: afficher en overlay fluide
      SafeUI.run(() {
        if (mounted) {
          setState(() => _showResultsOverlay = true);
        }
      });
    }
  }

  Future<void> _showLatestResults() async {
    final result = _lastSessionResult;
    if (result == null) {
      _showInfoSnackBar('Aucun résultat disponible pour cette session.');
      return;
    }
    _openResults(result, _lastNextQuestion, previewOnly: true);
  }

  Future<void> _autoSpeakFirstQuestion() async {
    if (_hasAutoSpokenFirstQuestion) return;
    _hasAutoSpokenFirstQuestion = true;
    await _speakCurrentQuestion();
  }

  Future<void> _speakCurrentQuestion() async {
    final question = _currentQuestion.trim();
    if (question.isEmpty) return;

    SafeUI.run(() {
      if (mounted) {
        setState(() => _isSpeakingQuestion = true);
      }
    });

    try {
      await _ttsChannel.invokeMethod<void>('speak', {
        'text': question,
        'language': 'en-US',
      });
    } catch (_) {
      _showInfoSnackBar('Lecture vocale indisponible sur cet appareil.',
          isError: true);
    } finally {
      SafeUI.run(() {
        if (mounted) {
          setState(() => _isSpeakingQuestion = false);
        }
      });
    }
  }

  Future<void> _stopSpeakingQuestion({bool updateState = true}) async {
    try {
      await _ttsChannel.invokeMethod<void>('stop');
    } catch (_) {}
    if (!updateState || !mounted) return;
    SafeUI.setState(this, () => _isSpeakingQuestion = false);
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

  Future<void> _endCurrentSession() async {
    if (_hasEndedSession || _sessionId == null || _totalSessionSeconds <= 0) {
      return;
    }
    _hasEndedSession = true;
    await context.read<SpeechService>().endSession(
          _sessionId!,
          durationSec: _totalSessionSeconds,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User>(
      future: _userFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Stack(
          children: [
            // Main scaffold
            Scaffold(
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
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildPracticeAvatar(user),
                                  const SizedBox(height: 34),
                                  _buildQuestionCard(),
                                  const SizedBox(height: 14),
                                  _buildQuestionActions(),
                                  if (_lastTranscription.isNotEmpty) ...[
                                    const SizedBox(height: 18),
                                    _buildLastTranscriptionCard(),
                                  ],
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
            ),

            // Results overlay
            if (_showResultsOverlay && _lastSessionResult != null)
              _buildResultsOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildResultsOverlay() {
    final result = _lastSessionResult!;

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // Empêche les tapotements sous l'overlay
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Résultats de ta réponse',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Score global circulaire
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.15),
                                AppColors.secondary.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${result.overallScore}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                ),
                                Text(
                                  '/100',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Métriques en grille
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: result.metrics.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${e.value}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Feedback AI
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.tertiary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          result.aiFeedback,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                SafeUI.run(() {
                                  if (mounted) {
                                    setState(() => _showResultsOverlay = false);
                                  }
                                });
                              },
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Fermer'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _continueWithQuestion(
                                result,
                                _lastNextQuestion,
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('Continuer'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // View full report button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            SafeUI.run(() {
                              if (mounted) {
                                setState(() => _showResultsOverlay = false);
                              }
                            });
                            // Naviguer vers le rapport complet
                            _openResults(result, _lastNextQuestion,
                                previewOnly: true);
                          },
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Voir le rapport complet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildPracticeAvatar(models.User? user) {
    return Stack(
      alignment: Alignment.center,
      children: [
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

  Widget _buildLastTranscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.subject_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _lastTranscription,
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.72),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildQuestionActions() {
    final canUseActions =
        !_isPreparingSession && !_isProcessing && _sessionId != null;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: canUseActions && !_isRecording
              ? (_isSpeakingQuestion
                  ? () => _stopSpeakingQuestion()
                  : _speakCurrentQuestion)
              : null,
          icon: Icon(
            _isSpeakingQuestion
                ? Icons.stop_circle_outlined
                : Icons.volume_up_rounded,
          ),
          label: Text(_isSpeakingQuestion ? 'Arrêter' : 'Lire la question'),
        ),
        if (_lastSessionResult != null)
          OutlinedButton.icon(
            onPressed:
                canUseActions && !_isRecording ? _showLatestResults : null,
            icon: const Icon(Icons.bar_chart_rounded),
            label: const Text('Voir les résultats'),
          ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
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
      child: Container(
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
}
