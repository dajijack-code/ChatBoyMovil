import 'dart:async';

class HotwordService {
  HotwordService();

  final StreamController<String> _hotwordController = StreamController.broadcast();
  String? _hotword;
  bool _listening = false;

  Stream<String> get events => _hotwordController.stream;

  void configure({String? hotword}) {
    _hotword = hotword?.toLowerCase();
  }

  void start() {
    _listening = true;
  }

  void stop() {
    _listening = false;
  }

  /// Simula la detección de la palabra clave desde otro servicio
  void simulateDetection(String phrase) {
    if (!_listening) return;
    final hotword = _hotword;
    if (hotword == null || hotword.isEmpty) return;
    if (phrase.toLowerCase().contains(hotword)) {
      _hotwordController.add(phrase);
    }
  }

  void dispose() {
    _hotwordController.close();
  }
}
