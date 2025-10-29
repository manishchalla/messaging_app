class Conversation {
  final String id;
  final List<String> participants;
  final DateTime lastMessageTime;
  final String lastMessageContent;
  final bool hasUnreadMessages;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessageTime,
    required this.lastMessageContent,
    this.hasUnreadMessages = false,
  });

  Map<String, dynamic> toMap() => {
    'participants': participants,
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'lastMessageContent': lastMessageContent,
    'hasUnreadMessages': hasUnreadMessages,
  };

  factory Conversation.fromMap(Map<String, dynamic> map, String id) => Conversation(
    id: id,
    participants: List<String>.from(map['participants']),
    lastMessageTime: DateTime.parse(map['lastMessageTime']),
    lastMessageContent: map['lastMessageContent'],
    hasUnreadMessages: map['hasUnreadMessages'] ?? false,
  );
}