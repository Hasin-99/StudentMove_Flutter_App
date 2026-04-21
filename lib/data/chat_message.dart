class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderRole,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String senderRole;
  final DateTime createdAt;

  bool get fromAdmin => senderRole.toLowerCase() == 'admin';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawTime = json['createdAt'] ?? json['created_at'];
    return ChatMessage(
      id: '${json['id'] ?? ''}',
      text: '${json['text'] ?? json['message'] ?? ''}',
      senderRole: '${json['senderRole'] ?? json['sender_role'] ?? 'user'}',
      createdAt: DateTime.tryParse('$rawTime') ?? DateTime.now(),
    );
  }
}
