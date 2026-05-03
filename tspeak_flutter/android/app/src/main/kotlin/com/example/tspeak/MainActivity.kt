package com.example.tspeak

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val channelName = "tspeak/tts"
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var pendingText: String? = null
    private var pendingLanguage: String = "en-US"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tts = TextToSpeech(this, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text").orEmpty()
                    val language = call.argument<String>("language") ?: "en-US"
                    if (text.isBlank()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    speak(text, language)
                    result.success(null)
                }
                "stop" -> {
                    tts?.stop()
                    pendingText = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        ttsReady = status == TextToSpeech.SUCCESS
        if (!ttsReady) return

        val text = pendingText
        if (!text.isNullOrBlank()) {
            speak(text, pendingLanguage)
            pendingText = null
        }
    }

    private fun speak(text: String, language: String) {
        if (!ttsReady) {
            pendingText = text
            pendingLanguage = language
            return
        }

        val locale = Locale.forLanguageTag(language)
        tts?.language = locale
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "tspeak-question")
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }
}
