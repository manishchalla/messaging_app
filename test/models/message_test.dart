// test/models/message_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/models/message.dart';

void main() {
  group('Message Tests', () {
    test('creates Message from map', () {
      final now = DateTime.now();
      final map = {
        'senderId': 'sender123',
        'recipientId': 'recipient456',
        'content': 'Hello there!',
        'timestamp': now.toIso8601String(),
        'isRead': false,
        'imageUrl': 'https://example.com/image.jpg',
        'editedAt': null,
        'originalContent': null,
      };

      final message = Message.fromMap(map, 'msg123');

      expect(message.id, 'msg123');
      expect(message.senderId, 'sender123');
      expect(message.recipientId, 'recipient456');
      expect(message.content, 'Hello there!');
      expect(message.timestamp.toIso8601String(), now.toIso8601String());
      expect(message.isRead, false);
      expect(message.imageUrl, 'https://example.com/image.jpg');
      expect(message.editedAt, null);
      expect(message.originalContent, null);
    });

    test('converts Message to map', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg123',
        senderId: 'sender123',
        recipientId: 'recipient456',
        content: 'Hello there!',
        timestamp: now,
        isRead: true,
        imageUrl: 'https://example.com/image.jpg',
        editedAt: now.add(const Duration(minutes: 5)),
        originalContent: 'Hello!',
      );

      final map = message.toMap();

      expect(map['senderId'], 'sender123');
      expect(map['recipientId'], 'recipient456');
      expect(map['content'], 'Hello there!');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['isRead'], true);
      expect(map['imageUrl'], 'https://example.com/image.jpg');
      expect(map['editedAt'], now.add(const Duration(minutes: 5)).toIso8601String());
      expect(map['originalContent'], 'Hello!');
    });

    test('isEdited returns true when editedAt is not null', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg123',
        senderId: 'sender123',
        recipientId: 'recipient456',
        content: 'Hello there!',
        timestamp: now,
        editedAt: now.add(const Duration(minutes: 5)),
      );

      expect(message.isEdited, true);
    });

    test('canEdit returns true when message is within edit window', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg123',
        senderId: 'sender123',
        recipientId: 'recipient456',
        content: 'Hello there!',
        timestamp: now,
      );

      expect(message.canEdit, true);
    });

    test('canEdit returns false when message is outside edit window', () {
      final oldTimestamp = DateTime.now().subtract(const Duration(minutes: 20));
      final message = Message(
        id: 'msg123',
        senderId: 'sender123',
        recipientId: 'recipient456',
        content: 'Hello there!',
        timestamp: oldTimestamp,
      );

      expect(message.canEdit, false);
    });

    test('copyWith creates new instance with updated values', () {
      final now = DateTime.now();
      final message = Message(
        id: 'msg123',
        senderId: 'sender123',
        recipientId: 'recipient456',
        content: 'Hello there!',
        timestamp: now,
      );

      final editedAt = now.add(const Duration(minutes: 5));
      final updatedMessage = message.copyWith(
        content: 'Updated content',
        editedAt: editedAt,
        originalContent: 'Hello there!',
      );

      // Check that original values are preserved
      expect(updatedMessage.id, 'msg123');
      expect(updatedMessage.senderId, 'sender123');
      expect(updatedMessage.recipientId, 'recipient456');
      expect(updatedMessage.timestamp, now);

      // Check that updated values are applied
      expect(updatedMessage.content, 'Updated content');
      expect(updatedMessage.editedAt, editedAt);
      expect(updatedMessage.originalContent, 'Hello there!');
    });
  });
}