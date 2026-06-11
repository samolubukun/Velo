enum MessageType { user, ai, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? imagePath;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.imagePath,
  });

  factory ChatMessage.user({required String content, String? imagePath}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.user,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      );

  factory ChatMessage.ai({required String content}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.ai,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.system({required String content}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.system,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '',
    content: json['content'] ?? '',
    type: MessageType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => MessageType.system,
    ),
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    imagePath: json['imagePath'],
  );

  bool get hasImage => imagePath != null;
}
