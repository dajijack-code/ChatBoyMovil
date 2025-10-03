import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ChatboyResponse {
  ChatboyResponse({
    required this.response,
    this.conversation,
    this.sessionId,
    this.meta,
    this.voice,
    this.usedFallback,
    this.audioUrl,
  });

  final String response;
  final Map<String, dynamic>? conversation;
  final String? sessionId;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? voice;
  final bool? usedFallback;
  final String? audioUrl;
}

class ChatboyApiService {
  ChatboyApiService({required http.Client client}) : _client = client;

  final http.Client _client;
  final Logger _logger = Logger();

  String? _token;
  String? _endpoint;
  String? _hotword;
  String? _stopPhrase;
  String? _selectedVoice;
  String? _googleTtsApiKey;

  void configure({
    required String token,
    required String endpoint,
    String? hotword,
    String? stopPhrase,
    String? voice,
    String? googleTtsApiKey,
  }) {
    _token = token;
    _endpoint = endpoint;
    _hotword = hotword;
    _stopPhrase = stopPhrase;
    _selectedVoice = voice;
    _googleTtsApiKey = googleTtsApiKey;
  }

  String? get hotword => _hotword;
  String? get stopPhrase => _stopPhrase;
  String? get selectedVoice => _selectedVoice;
  String? get googleTtsApiKey => _googleTtsApiKey;
  String? get token => _token;
  String? get endpoint => _endpoint;

  Future<ChatboyResponse> sendMessage({
    required String message,
    String? sessionId,
    Map<String, dynamic>? meta,
  }) async {
    if (_token == null || _endpoint == null) {
      throw StateError('Token o endpoint no configurados');
    }

    final uri = Uri.parse(_endpoint!);
    final payload = {
      'message': message,
      if (sessionId != null) 'session_id': sessionId,
      if (meta != null) 'meta': meta,
      if (_selectedVoice != null) 'voice': _selectedVoice,
      if (_googleTtsApiKey != null) 'google_tts_key': _googleTtsApiKey,
    };

    _logger.i('Enviando mensaje a ChatBoy: ${jsonEncode(payload)}');

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 400) {
      _logger.e('Error ${response.statusCode}: ${response.body}');
      throw http.ClientException('Error al comunicarse con ChatBoy', uri);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatboyResponse(
      response: body['response'] as String? ?? '',
      conversation: body['conversation'] as Map<String, dynamic>?,
      sessionId: body['session_id'] as String? ?? body['sessionId'] as String?,
      meta: body['meta'] as Map<String, dynamic>?,
      voice: body['voice'] as Map<String, dynamic>?,
      usedFallback: body['usedFallback'] as bool?,
      audioUrl: body['audio'] as String? ?? body['audio_url'] as String?,
    );
  }
}
