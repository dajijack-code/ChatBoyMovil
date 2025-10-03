import 'package:flutter/material.dart';

enum ChatMode {
  pushToTalk,
  dictation,
  openChat,
  hotword,
}

extension ChatModeExt on ChatMode {
  String get label {
    switch (this) {
      case ChatMode.pushToTalk:
        return 'PTT';
      case ChatMode.dictation:
        return 'Dictado';
      case ChatMode.openChat:
        return 'Chat';
      case ChatMode.hotword:
        return 'Hotword';
    }
  }

  IconData get icon {
    switch (this) {
      case ChatMode.pushToTalk:
        return Icons.mic_none;
      case ChatMode.dictation:
        return Icons.record_voice_over;
      case ChatMode.openChat:
        return Icons.chat_bubble_outline;
      case ChatMode.hotword:
        return Icons.hearing;
    }
  }
}
