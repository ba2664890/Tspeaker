"""
T.Speak — Tâches Celery : Pipeline de traitement audio
Whisper (transcription) → Wav2Vec (scoring phonétique) → LLM (feedback)
"""

import logging
import os
import time
import concurrent.futures

from celery import shared_task
from django.core.cache import cache

logger = logging.getLogger("tspeak.ai")


@shared_task(
    bind=True,
    name="sessions.process_audio_exchange",
    max_retries=3,
    default_retry_delay=5,
    queue="audio",
    acks_late=True,
    reject_on_worker_lost=True,
)
def process_audio_exchange(self, exchange_id: str, audio_path: str, native_language: str):
    """
    Pipeline principal de traitement audio.

    1. Conversion + normalisation audio (FFmpeg)
    2. Transcription Whisper
    3. Scoring phonétique Wav2Vec
    4. Analyse grammaticale NLP
    5. Génération feedback LLM
    6. Calcul score global
    7. Sauvegarde PostgreSQL + cache Redis
    """
    try:
        return process_audio_exchange_now(exchange_id, audio_path, native_language)

    except Exception as exc:
        logger.error("❌ Erreur traitement audio: exchange=%s — %s", exchange_id, exc, exc_info=True)
        try:
            raise self.retry(exc=exc)
        except Exception:
            # Marquer la session comme échouée après 3 tentatives
            try:
                from apps.sessions.models import AudioExchange
                exchange = AudioExchange.objects.get(id=exchange_id)
                exchange.ai_feedback = "Une erreur s'est produite. Veuillez réessayer."
                exchange.session.status = "active"
                exchange.save(update_fields=["ai_feedback"])
                exchange.session.save(update_fields=["status"])
            except Exception:
                logger.exception("Impossible de marquer l'échange %s en erreur", exchange_id)
            return {"status": "error", "message": str(exc)}


def process_audio_exchange_now(exchange_id: str, audio_path: str, native_language: str):
    """Exécute le pipeline audio immédiatement, sans passer par un worker Celery."""
    from apps.sessions.models import AudioExchange
    from ai.whisper_asr.transcriber import get_transcriber

    start_time = time.monotonic()
    logger.info("🎙️ Traitement audio démarré: exchange=%s", exchange_id)

    try:
        exchange = AudioExchange.objects.select_related("session__user").get(id=exchange_id)
        if exchange.transcription:
            logger.info("Échange déjà traité (skip): %s", exchange_id)
            return {"status": "success", "already_processed": True}
    except AudioExchange.DoesNotExist:
        logger.error("Échange introuvable: %s", exchange_id)
        return {"status": "error", "message": "Exchange not found"}

    if not os.path.exists(audio_path):
        exchange.refresh_from_db()
        if exchange.transcription:
            return {"status": "success", "already_processed": True}
        logger.error("Fichier audio introuvable (et non traité): %s", audio_path)
        return {"status": "error", "message": f"Audio file not found: {audio_path}"}

    wav_path = None
    processing_succeeded = False
    try:
        # ── Étape 1 : Conversion audio ─────────────────────────────────────
        wav_path = _convert_to_wav(audio_path)

        # ── Étape 2 : Transcription & Détection All-in-One ───────────────
        transcriber = get_transcriber()
        trans_res = transcriber.transcribe(wav_path, language=None)
        
        detected_lang = trans_res.get("language", "en")
        lang_prob = trans_res.get("language_probability", 0.0)
        transcription = trans_res["text"].strip()
        
        logger.info("Détection/Transcription Whisper: lang=%s (%.2f) text='%s...'", 
                    detected_lang, lang_prob, transcription[:40])

        # Critères pour rejeter la langue: plus strict (0.30 au lieu de 0.45)
        # Si c'est PAS de l'anglais et que Whisper est un minimum sûr, on rejette.
        is_wrong_language = (detected_lang != 'en') and (lang_prob > 0.30)
        
        # Initialisation des variables de pipeline (toutes à 0 par défaut)
        pronunciation_score = 0.0
        fluency_score = 0.0
        grammar_score = 0.0
        vocabulary_score = 0.0
        phoneme_analysis = {}
        grammar_analysis = {"grammar_score": 0.0}
        vocabulary_analysis = {"vocabulary_score": 0.0}
        llm_error_hint = None
        mistakes = {}

        if is_wrong_language:
            logger.warning("Langue incorrecte détectée: %s (prob=%.2f). Scoring annulé.", 
                           detected_lang, lang_prob)
            llm_error_hint = f"WRONG_LANGUAGE:{detected_lang}"
            phoneme_analysis = {"error": "wrong_language", "detected": detected_lang}
            mistakes = {"detected_language": detected_lang, "status": "wrong_language"}
            # Les scores restent à 0.0
        else:
            if not transcription or len(transcription.split()) < 2:
                logger.warning("Audio vide ou trop court (exchange=%s)", exchange_id)
                transcription = "[Silence ou inaudible]" if not transcription else transcription
                llm_error_hint = "SILENCE"
                phoneme_analysis = {"error": "silence"}
                mistakes = {"status": "silence_or_too_short"}
            else:
                # ── Étape 4 : Pipeline Parallèle ───────────────────────────
                from ai.wav2vec_scoring.scorer import get_scorer
                from ai.wav2vec_scoring.nlp_analyzer import GrammarAnalyzer, VocabularyAnalyzer
                
                scorer = get_scorer()
                grammar_tool = GrammarAnalyzer()
                vocab_tool = VocabularyAnalyzer()

                with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
                    future_phoneme = executor.submit(
                        scorer.score_pronunciation, 
                        wav_path, 
                        reference_text=exchange.ai_question, 
                        user_text=transcription
                    )
                    future_grammar = executor.submit(grammar_tool.analyze, transcription)
                    future_vocab = executor.submit(vocab_tool.analyze, transcription)

                    phoneme_analysis = future_phoneme.result()
                    grammar_analysis = future_grammar.result()
                    vocabulary_analysis = future_vocab.result()

                pronunciation_score = phoneme_analysis["pronunciation_score"]
                grammar_score = grammar_analysis["grammar_score"]
                vocabulary_score = vocabulary_analysis["vocabulary_score"]

                # SECURITE: Si la prononciation est catastrophique (< 15%), 
                # c'est probablement du charabia ou une langue non détectée.
                if pronunciation_score < 15.0:
                    logger.warning("Prononciation trop basse (%.1f). On force les autres scores à 0.", pronunciation_score)
                    grammar_score = 0.0
                    vocabulary_score = 0.0
                    fluency_score = 0.0
                    grammar_analysis["grammar_score"] = 0.0
                    vocabulary_analysis["vocabulary_score"] = 0.0
                else:
                    fluency_score = _compute_fluency_score(
                        transcription,
                        duration_sec=exchange.user_audio_duration_sec,
                    )

                # Extraction des erreurs pour le LLM
                mistakes = {
                    "mispronounced_words": [w for w, s in phoneme_analysis.get("word_scores", {}).items() if s < 55],
                    "difficult_phonemes": [p["phoneme"] for p in phoneme_analysis.get("difficult_phonemes", [])],
                    "grammar_errors": [e["description"] for e in grammar_analysis.get("errors", [])],
                    "cefr_level": vocabulary_analysis.get("cefr_level"),
                }

        # ── Étape 5 : Feedback LLM ────────────────────────────────────────
        from ai.llm_conversation.generator import get_generator
        generator = get_generator()
        session = exchange.session
        history = _get_session_history(session)

        # On enrichit la transcription pour le LLM si erreur
        llm_input_text = transcription
        if llm_error_hint:
            llm_input_text = f"[{llm_error_hint}]\n{transcription}"

        llm_response = generator.generate_feedback(
            user_transcription=llm_input_text,
            ai_question=exchange.ai_question,
            pronunciation_score=pronunciation_score,
            fluency_score=fluency_score,
            native_language=native_language,
            session_type=session.session_type,
            history=history,
            user_level=session.user.level,
            mistakes=mistakes,
        )

        # ── Étape 6 : Sauvegarde ──────────────────────────────────────────
        processing_ms = int((time.monotonic() - start_time) * 1000)

        exchange.transcription = transcription
        exchange.pronunciation_score = pronunciation_score
        exchange.fluency_score = fluency_score
        exchange.phoneme_analysis = phoneme_analysis
        exchange.ai_feedback = llm_response["feedback"]
        exchange.ai_response = llm_response["next_question"]
        exchange.processing_time_ms = processing_ms
        exchange.save()

        from apps.scoring.models import Score
        score, _ = Score.objects.update_or_create(
            session=session,
            defaults={
                "user": session.user,
                "pronunciation": pronunciation_score,
                "fluency": fluency_score,
                "grammar": grammar_score,
                "vocabulary": vocabulary_score,
                "feedback_text": llm_response["feedback"],
            },
        )

        session.status = "active"
        session.save(update_fields=["status"])

        result_data = {
            "exchange_id": exchange_id,
            "transcription": transcription,
            "pronunciation_score": pronunciation_score,
            "fluency_score": fluency_score,
            "grammar_score": grammar_score,
            "vocabulary_score": vocabulary_score,
            "global_score": float(score.global_score),
            "ai_feedback": llm_response["feedback"],
            "ai_response": llm_response["next_question"],
            "phoneme_analysis": phoneme_analysis,
            "grammar_analysis": grammar_analysis,
            "vocabulary_analysis": vocabulary_analysis,
            "processing_time_ms": processing_ms,
        }
        if is_wrong_language:
            result_data["error"] = "wrong_language"
            result_data["detected_language"] = detected_lang
        elif llm_error_hint == "SILENCE":
            result_data["error"] = "silence_detected"

        cache.set(f"exchange_result:{exchange_id}", result_data, timeout=600)
        logger.info("✅ Traitement finalisé: exchange=%s — score=%.1f", exchange_id, score.global_score)
        
        processing_succeeded = True
        return result_data

    finally:
        if processing_succeeded and wav_path:
            _cleanup_audio(wav_path)
        if processing_succeeded and audio_path != wav_path:
            _cleanup_audio(audio_path)


@shared_task(name="sessions.cleanup_audio_files")
def cleanup_audio_files():
    """Nettoyage RGPD : supprime les fichiers audio > 24h."""
    import glob
    import time

    audio_dir = "/tmp/tspeak_audio"
    if not os.path.exists(audio_dir):
        return

    count = 0
    cutoff = time.time() - (24 * 3600)
    for filepath in glob.glob(os.path.join(audio_dir, "*.wav")):
        if os.path.getmtime(filepath) < cutoff:
            os.remove(filepath)
            count += 1

    logger.info("Nettoyage audio: %d fichiers supprimés", count)
    return {"deleted": count}


# ─── Helpers privés ──────────────────────────────────────────────────────────

def _convert_to_wav(input_path: str) -> str:
    """Convertit n'importe quel format audio en WAV 16kHz mono (requis par Whisper)."""
    import subprocess

    if input_path.endswith(".wav"):
        return input_path  # Déjà en WAV

    output_path = input_path.rsplit(".", 1)[0] + "_16k.wav"
    cmd = [
        "ffmpeg", "-i", input_path,
        "-ar", "16000",  # Sample rate 16kHz
        "-ac", "1",      # Mono
        "-c:a", "pcm_s16le",  # Format PCM 16-bit
        output_path,
        "-y",  # Écraser si existe
        "-loglevel", "error",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"FFmpeg conversion failed: {result.stderr}")
    return output_path


def _compute_fluency_score(transcription: str, duration_sec: float) -> float:
    """
    Calcule un score de fluidité basé sur :
    - Débit de parole (mots par minute)
    - Ratio de pauses (estimé via longueur vs durée)
    """
    if not transcription or not transcription.strip():
        return 0.0  # Audio vide/silencieux -> fluidité = 0
    
    if duration_sec <= 0:
        return 5.0  # Très court mais non-vide

    words = transcription.split()
    
    # Très peu de mots (< 3) = mauvais score
    if len(words) < 3:
        return max(10.0, len(words) * 5.0)  # 0 mots=10, 1 mot=10, 2 mots=10, pas 28 comme avant
    
    wpm = (len(words) / duration_sec) * 60

    # Débit idéal pour l'anglais : 120-180 wpm
    if 120 <= wpm <= 180:
        score = 90.0
    elif 90 <= wpm < 120 or 180 < wpm <= 210:
        score = 75.0
    elif 60 <= wpm < 90 or 210 < wpm <= 240:
        score = 60.0
    else:
        score = 40.0

    return round(score, 2)


def _get_session_history(session) -> list:
    """Récupère les 10 derniers échanges pour le contexte LLM."""
    return list(
        session.exchanges.filter(transcription__isnull=False)
        .exclude(transcription="")
        .order_by("-exchange_index")[:10]
        .values("ai_question", "transcription", "ai_response")
    )


def _cleanup_audio(filepath: str):
    """Supprime un fichier audio de façon sécurisée."""
    try:
        if os.path.exists(filepath):
            os.remove(filepath)
    except OSError as e:
        logger.warning("Impossible de supprimer %s: %s", filepath, e)
