enum MessageSender { user, ai }

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.audioUrl,
    this.timestamp,
    this.isPlaying = false,
  });

  final String id;
  final MessageSender sender;
  final String text;
  final String? audioUrl;
  final DateTime? timestamp;
  bool isPlaying;
}
