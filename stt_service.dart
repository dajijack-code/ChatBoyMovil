import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef PartialCb = void Function(String partial);
typedef FinalCb = void Function(String finalText);

enum SttState { idle, listening }

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  SttState state = SttState.idle;

  Future<bool> init() async {
    return _speech.initialize(onStatus: (_) {}, onError: (_) {});
  }

  Future<bool> start({
    String localeId = 'es_MX',
    PartialCb? onPartial,
    FinalCb? onFinal,
    Duration listenFor = const Duration(seconds: 60),
    bool partialResults = true,
  }) async {
    if (state == SttState.listening) return true;

    final available = await _speech.initialize(onStatus: (_) {}, onError: (_) {});
    if (!available) return false;

    state = SttState.listening;
    try {
      await _speech.listen(
        onResult: (r) {
          final txt = r.recognizedWords;
          if (r.finalResult) {
            onFinal?.call(txt);
          } else if (partialResults) {
            onPartial?.call(txt);
          }
        },
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 2),
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

  Future<void> stop() async {
    state = SttState.idle;
    await _speech.stop();
  }
}
