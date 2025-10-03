import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService() {
    _tts = FlutterTts();
    _tts.setCompletionHandler(() => _completionController.add(null));
    _tts.setErrorHandler((msg) => _errorController.add(msg));
  }

  late final FlutterTts _tts;
  final StreamController<void> _completionController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();

  Stream<void> get onComplete => _completionController.stream;
  Stream<String> get onError => _errorController.stream;

  Future<void> configure({
    String language = 'es-MX',
    String? voiceName,
    double volume = 0.8,
    double pitch = 1.0,
    double rate = 0.5,
  }) async {
    await _tts.setLanguage(language);
    await _tts.setVolume(volume);
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(rate);
    if (voiceName != null) {
      await _tts.setVoice({'name': voiceName, 'locale': language});
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _completionController.close();
    _errorController.close();
    _tts.stop();
  }
}
