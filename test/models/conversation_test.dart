// test/models/conversation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/models/conversation.dart';

void main() {
  group('Conversation Tests', () {
    test('creates Conversation from map', () {
      final now = DateTime.now();
      final map = {
        'participants': ['user1', 'user2'],
        'lastMessageTime': now.toIso8601String(),
        'lastMessageContent': 'Hello there!',
        'hasUnreadMessages': true,
      };

      final conversation = Conversation.fromMap(map, 'conv123');

      expect(conversation.id, 'conv123');
      expect(conversation.participants, ['user1', 'user2']);
      expect(conversation.lastMessageTime.toIso8601String(), now.toIso8601String());
      expect(conversation.lastMessageContent, 'Hello there!');
      expect(conversation.hasUnreadMessages, true);
    });

    test('converts Conversation to map', () {
      final now = DateTime.now();
      final conversation = Conversation(
        id: 'conv123',
        participants: ['user1', 'user2'],
        lastMessageTime: now,
        lastMessageContent: 'Hello there!',
        hasUnreadMessages: true,
      );

      final map = conversation.toMap();

      expect(map['participants'], ['user1', 'user2']);
      expect(map['lastMessageTime'], now.toIso8601String());
      expect(map['lastMessageContent'], 'Hello there!');
      expect(map['hasUnreadMessages'], true);
    });

    test('handles missing hasUnreadMessages in map', () {
      final now = DateTime.now();
      final map = {
        'participants': ['user1', 'user2'],
        'lastMessageTime': now.toIso8601String(),
        'lastMessageContent': 'Hello there!',
      };

      final conversation = Conversation.fromMap(map, 'conv123');

      expect(conversation.hasUnreadMessages, false); // Default value
    });
  });
}