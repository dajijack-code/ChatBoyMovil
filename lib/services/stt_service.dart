import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef PartialCb = void Function(String partial);
typedef FinalCb = void Function(String finalText);
typedef StatusCb = void Function(String status);

enum SttState { idle, listening, unavailable }

class SttService {
  SttService() {
    _speech = stt.SpeechToText();
  }

  late final stt.SpeechToText _speech;
  final StreamController<String> _partialController = StreamController.broadcast();
  final StreamController<String> _finalController = StreamController.broadcast();
  final StreamController<String> _statusController = StreamController.broadcast();

  Stream<String> get partialStream => _partialController.stream;
  Stream<String> get finalStream => _finalController.stream;
  Stream<String> get statusStream => _statusController.stream;

  SttState state = SttState.idle;
  bool _initialized = false;

  Future<bool> ensurePermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      state = SttState.unavailable;
      return false;
    }
    return true;
  }

  Future<bool> init({StatusCb? onStatus, StatusCb? onError}) async {
    if (_initialized) return true;
    final hasPermission = await ensurePermission();
    if (!hasPermission) return false;

    _initialized = await _speech.initialize(
      onStatus: (s) {
        _statusController.add(s);
        onStatus?.call(s);
      },
      onError: (e) {
        _statusController.add('error:${e.errorMsg}');
        onError?.call(e.errorMsg);
      },
    );
    state = _initialized ? SttState.idle : SttState.unavailable;
    return _initialized;
  }

  Future<bool> start({
    String localeId = 'es_MX',
    PartialCb? onPartial,
    FinalCb? onFinal,
    Duration listenFor = const Duration(seconds: 60),
    bool partialResults = true,
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    if (state == SttState.listening) return true;
    final initialized = await init();
    if (!initialized) return false;

    final available = await _speech.initialize();
    if (!available) {
      state = SttState.unavailable;
      return false;
    }

    state = SttState.listening;
    try {
      await _speech.listen(
        onResult: (r) {
          final txt = r.recognizedWords.trim();
          if (txt.isEmpty) return;

          if (r.finalResult) {
            _finalController.add(txt);
            onFinal?.call(txt);
          } else if (partialResults) {
            _partialController.add(txt);
            onPartial?.call(txt);
          }
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        localeId: localeId,
        partialResults: partialResults,
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      state = SttState.idle;
      return false;
    }
  }

  Future<void> stop({bool cancel = false}) async {
    if (state == SttState.idle) return;
    state = SttState.idle;
    if (cancel) {
      await _speech.cancel();
    } else {
      await _speech.stop();
    }
  }

  void dispose() {
    _partialController.close();
    _finalController.close();
    _statusController.close();
  }
}
