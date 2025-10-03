import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../models/chat_message.dart';
import '../models/chat_mode.dart';
import '../services/audio_player_service.dart';
import '../services/chatboy_api_service.dart';
import '../services/hotword_service.dart';
import '../services/preferences_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    ChatboyApiService? apiService,
    AudioPlayerService? audioPlayerService,
    PreferencesService? preferencesService,
    SttService? sttService,
    TtsService? ttsService,
    HotwordService? hotwordService,
  })  : _apiService = apiService ?? ChatboyApiService(client: http.Client()),
        _audioPlayerService = audioPlayerService ?? AudioPlayerService(),
        _preferencesService = preferencesService ?? PreferencesService(),
        _sttService = sttService ?? SttService(),
        _ttsService = ttsService ?? TtsService(),
        _hotwordService = hotwordService ?? HotwordService() {
    _sttService.partialStream.listen(_handlePartial);
    _sttService.finalStream.listen(_handleFinal);
    _audioPlayerService.stateStream.listen(_handleAudioState);
  }

  final ChatboyApiService _apiService;
  final AudioPlayerService _audioPlayerService;
  final PreferencesService _preferencesService;
  final SttService _sttService;
  final TtsService _ttsService;
  final HotwordService _hotwordService;

  final List<ChatMessage> _messages = [];
  ChatMode _mode = ChatMode.pushToTalk;
  String? _currentPartial;
  bool _isLoading = false;
  String? _sessionId;
  Map<String, dynamic>? _meta;
  String? _errorMessage;
  bool _isHotwordActive = false;
  bool _isAudioPlaying = false;
  Offset _micPosition = const Offset(24, 24);
  bool _hotwordDetected = false;
  final StringBuffer _hotwordBuffer = StringBuffer();

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatMode get mode => _mode;
  String? get currentPartial => _currentPartial;
  bool get isLoading => _isLoading;
  bool get isAudioPlaying => _isAudioPlaying;
  String? get errorMessage => _errorMessage;
  Offset get micPosition => _micPosition;
  bool get isListening => _sttService.state == SttState.listening;
  String? get apiToken => _apiService.token;
  String? get apiEndpoint => _apiService.endpoint;
  String? get hotword => _apiService.hotword;
  String? get stopPhrase => _apiService.stopPhrase;
  String? get voice => _apiService.selectedVoice;
  String? get googleTtsKey => _apiService.googleTtsApiKey;

  Future<void> loadPreferences() async {
    final prefs = await _preferencesService.load();
    final token = prefs['token'] as String?;
    final endpoint = prefs['endpoint'] as String?;
    if (token != null && endpoint != null) {
      _apiService.configure(
        token: token,
        endpoint: endpoint,
        hotword: prefs['hotword'] as String?,
        stopPhrase: prefs['stopPhrase'] as String?,
        voice: prefs['voice'] as String?,
        googleTtsApiKey: prefs['googleTtsKey'] as String?,
      );
    }
    final pos = prefs['micPosition'] as ({double dx, double dy})?;
    if (pos != null) {
      _micPosition = Offset(pos.dx, pos.dy);
    }
    notifyListeners();
  }

  Future<void> savePreferences({
    String? token,
    String? endpoint,
    String? hotword,
    String? stopPhrase,
    String? voice,
    String? googleTtsKey,
    Offset? micPosition,
  }) async {
    await _preferencesService.save(
      token: _normalize(token),
      endpoint: _normalize(endpoint),
      hotword: _normalize(hotword),
      stopPhrase: _normalize(stopPhrase),
      voice: _normalize(voice),
      googleTtsKey: _normalize(googleTtsKey),
      micPosition: micPosition != null
          ? (dx: micPosition.dx, dy: micPosition.dy)
          : null,
    );
    await loadPreferences();
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void selectMode(ChatMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    if (mode == ChatMode.hotword) {
      _hotwordService.start();
      _isHotwordActive = true;
      _hotwordDetected = false;
      _hotwordBuffer.clear();
    } else {
      _hotwordService.stop();
      _isHotwordActive = false;
      _hotwordDetected = false;
      _hotwordBuffer.clear();
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    final started = await _sttService.start(onPartial: _handlePartial, onFinal: _handleFinal);
    if (!started) {
      _errorMessage = 'No se pudo iniciar el reconocimiento de voz';
      notifyListeners();
    }
  }

  Future<void> stopListening({bool cancel = false}) async {
    await _sttService.stop(cancel: cancel);
    _currentPartial = null;
    notifyListeners();
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    _appendMessage(MessageSender.user, text);
    await _sendToApi(text);
  }

  Future<void> _sendToApi(String text) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(
        message: text,
        sessionId: _sessionId,
        meta: _meta,
      );
      _sessionId = response.sessionId ?? _sessionId;
      _meta = response.meta ?? _meta;
      await _handleAiResponse(response);
    } catch (e) {
      _errorMessage = 'Error al comunicarse con ChatBoy';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleAiResponse(ChatboyResponse response) async {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.ai,
      text: response.response,
      audioUrl: response.audioUrl,
      timestamp: DateTime.now(),
    );
    _messages.add(message);
    notifyListeners();

    if (response.audioUrl != null && response.audioUrl!.isNotEmpty) {
      await _playRemoteAudio(response.audioUrl!, message);
    } else {
      await _ttsService.speak(response.response);
    }
  }

  Future<void> _playRemoteAudio(String url, ChatMessage message) async {
    await _audioPlayerService.playRemote(url);
    _setPlaying(message, true);
  }

  void _handleAudioState(PlayerState state) {
    final playing = state.playing && state.processingState != ProcessingState.completed;
    _isAudioPlaying = playing;
    if (!playing) {
      _clearPlaying();
    }
    notifyListeners();
  }

  void interruptAudio() {
    _audioPlayerService.stop();
    _ttsService.stop();
    _clearPlaying();
  }

  void _handlePartial(String partial) {
    _currentPartial = partial;
    if (_mode == ChatMode.hotword && _isHotwordActive) {
      final hotword = _apiService.hotword?.toLowerCase();
      final stopPhrase = _apiService.stopPhrase?.toLowerCase();
      final normalized = partial.toLowerCase();
      if (!_hotwordDetected && hotword != null && hotword.isNotEmpty) {
        if (normalized.contains(hotword)) {
          _hotwordDetected = true;
          _hotwordBuffer.clear();
        }
      }

      if (_hotwordDetected) {
        _hotwordBuffer
          ..write(partial)
          ..write(' ');
        if (stopPhrase != null && stopPhrase.isNotEmpty && normalized.contains(stopPhrase)) {
          final text = _removePhrase(_hotwordBuffer.toString(), stopPhrase).trim();
          _hotwordDetected = false;
          _hotwordBuffer.clear();
          if (text.isNotEmpty) {
            _appendMessage(MessageSender.user, text);
            _sendToApi(text);
          }
        }
      }
    }
    notifyListeners();
  }

  void _handleFinal(String finalText) {
    _currentPartial = null;
    if (finalText.trim().isEmpty) return;
    final normalized = finalText.trim();
    if (_mode == ChatMode.hotword) {
      if (!_hotwordDetected) {
        final hotword = _apiService.hotword?.toLowerCase();
        if (hotword != null && hotword.isNotEmpty && normalized.toLowerCase().contains(hotword)) {
          _hotwordDetected = true;
          _hotwordBuffer.clear();
          _hotwordBuffer.write('$normalized ');
          return;
        }
      }
      final stopPhrase = _apiService.stopPhrase?.toLowerCase();
      var textToSend = normalized;
      if (stopPhrase != null && stopPhrase.isNotEmpty) {
        textToSend = _removePhrase(textToSend, stopPhrase).trim();
      }
      if (textToSend.isNotEmpty) {
        _appendMessage(MessageSender.user, textToSend);
        _sendToApi(textToSend);
      }
      _hotwordDetected = false;
      _hotwordBuffer.clear();
    } else {
      _appendMessage(MessageSender.user, normalized);
      if (_mode == ChatMode.dictation || _mode == ChatMode.pushToTalk || _mode == ChatMode.openChat) {
        _sendToApi(normalized);
      }
    }
    notifyListeners();
  }

  void _appendMessage(MessageSender sender, String text) {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sender,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  String _removePhrase(String source, String phrase) {
    final pattern = RegExp(RegExp.escape(phrase), caseSensitive: false);
    return source.replaceAll(pattern, '');
  }

  void updateMicPosition(Offset offset) {
    _micPosition = offset;
    notifyListeners();
    unawaited(
      _preferencesService.save(micPosition: (dx: offset.dx, dy: offset.dy)),
    );
  }

  void _clearPlaying() {
    for (final message in _messages) {
      message.isPlaying = false;
    }
  }

  void _setPlaying(ChatMessage message, bool isPlaying) {
    _clearPlaying();
    message.isPlaying = isPlaying;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    _hotwordService.dispose();
    super.dispose();
  }
}
