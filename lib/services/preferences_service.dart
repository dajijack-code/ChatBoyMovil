import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _tokenKey = 'chatboy_token';
  static const _endpointKey = 'chatboy_endpoint';
  static const _hotwordKey = 'chatboy_hotword';
  static const _stopPhraseKey = 'chatboy_stop_phrase';
  static const _voiceKey = 'chatboy_voice';
  static const _ttsKey = 'chatboy_tts_key';
  static const _micPosKey = 'chatboy_mic_position';

  Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'endpoint': prefs.getString(_endpointKey),
      'hotword': prefs.getString(_hotwordKey),
      'stopPhrase': prefs.getString(_stopPhraseKey),
      'voice': prefs.getString(_voiceKey),
      'googleTtsKey': prefs.getString(_ttsKey),
      'micPosition': _decodeOffset(prefs.getString(_micPosKey)),
    };
  }

  Future<void> save({
    String? token,
    String? endpoint,
    String? hotword,
    String? stopPhrase,
    String? voice,
    String? googleTtsKey,
    ({double dx, double dy})? micPosition,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString(_tokenKey, token);
    if (endpoint != null) await prefs.setString(_endpointKey, endpoint);
    if (hotword != null) await prefs.setString(_hotwordKey, hotword);
    if (stopPhrase != null) await prefs.setString(_stopPhraseKey, stopPhrase);
    if (voice != null) await prefs.setString(_voiceKey, voice);
    if (googleTtsKey != null) await prefs.setString(_ttsKey, googleTtsKey);
    if (micPosition != null) {
      await prefs.setString(
        _micPosKey,
        jsonEncode({'dx': micPosition.dx, 'dy': micPosition.dy}),
      );
    }
  }

  ({double dx, double dy})? _decodeOffset(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (dx: (json['dx'] as num).toDouble(), dy: (json['dy'] as num).toDouble());
    } catch (_) {
      return null;
    }
  }
}
