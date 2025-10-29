class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final DateTime? editedAt; // Add this
  final String? originalContent; // Add this

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.editedAt,
    this.originalContent,
  });

  bool get isEdited => editedAt != null;
  bool get canEdit => DateTime.now().difference(timestamp).inMinutes <= 15;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'recipientId': recipientId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'imageUrl': imageUrl,
    'editedAt': editedAt?.toIso8601String(),
    'originalContent': originalContent,
  };

  factory Message.fromMap(Map<String, dynamic> map, String id) => Message(
    id: id,
    senderId: map['senderId'],
    recipientId: map['recipientId'],
    content: map['content'],
    timestamp: DateTime.parse(map['timestamp']),
    isRead: map['isRead'] ?? false,
    imageUrl: map['imageUrl'],
    editedAt: map['editedAt'] != null ? DateTime.parse(map['editedAt']) : null,
    originalContent: map['originalContent'],
  );

  Message copyWith({
    String? content,
    DateTime? editedAt,
    String? originalContent,
  }) => Message(
    id: id,
    senderId: senderId,
    recipientId: recipientId,
    content: content ?? this.content,
    timestamp: timestamp,
    isRead: isRead,
    imageUrl: imageUrl,
    editedAt: editedAt ?? this.editedAt,
    originalContent: originalContent ?? this.originalContent,
  );
}