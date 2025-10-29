import 'package:cocolab_messaging/models/message.dart';
import 'package:cocolab_messaging/models/conversation.dart';
import 'package:cocolab_messaging/services/message_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mock classes
@GenerateMocks([DatabaseReference, DataSnapshot, DatabaseEvent])
import 'message_service_test.mocks.dart';

void main() {
  late MessageService messageService;
  late MockDatabaseReference mockDb;
  late MockDatabaseReference mockMessagesRef;
  late MockDatabaseReference mockConversationsRef;
  late MockDatabaseReference mockConvoIdRef;
  late MockDatabaseReference mockPushRef;
  late MockDatabaseReference mockMessageIdRef;
  late MockDatabaseReference mockUnreadByRef;
  late MockDatabaseReference mockUserIdRef;
  late MockDataSnapshot mockSnapshot;
  late MockDatabaseEvent mockEvent;

  setUp(() {
    mockDb = MockDatabaseReference();
    mockMessagesRef = MockDatabaseReference();
    mockConversationsRef = MockDatabaseReference();
    mockConvoIdRef = MockDatabaseReference();
    mockPushRef = MockDatabaseReference();
    mockMessageIdRef = MockDatabaseReference();
    mockUnreadByRef = MockDatabaseReference();
    mockUserIdRef = MockDatabaseReference();
    mockSnapshot = MockDataSnapshot();
    mockEvent = MockDatabaseEvent();

    // Setup main refs
    when(mockDb.child('messages')).thenReturn(mockMessagesRef);
    when(mockDb.child('conversations')).thenReturn(mockConversationsRef);

    // Messages path
    when(mockMessagesRef.child(any)).thenReturn(mockConvoIdRef);
    when(mockConvoIdRef.child(any)).thenReturn(mockMessageIdRef);
    when(mockConvoIdRef.push()).thenReturn(mockPushRef);
    when(mockConvoIdRef.get()).thenAnswer((_) => Future.value(mockSnapshot));
    when(mockConvoIdRef.onValue).thenAnswer((_) => Stream.value(mockEvent));
    when(mockConvoIdRef.orderByChild(any)).thenReturn(mockConvoIdRef);
    when(mockConvoIdRef.equalTo(any)).thenReturn(mockConvoIdRef);

    // Conversations path
    when(mockConversationsRef.child(any)).thenReturn(mockConvoIdRef);
    when(mockConvoIdRef.child('unreadBy')).thenReturn(mockUnreadByRef);
    when(mockUnreadByRef.child(any)).thenReturn(mockUserIdRef);

    // General operations
    when(mockPushRef.set(any)).thenAnswer((_) => Future.value());
    when(mockMessageIdRef.update(any)).thenAnswer((_) => Future.value());
    when(mockConvoIdRef.update(any)).thenAnswer((_) => Future.value());
    when(mockUserIdRef.remove()).thenAnswer((_) => Future.value());

    // Data responses
    when(mockSnapshot.exists).thenReturn(true);
    when(mockEvent.snapshot).thenReturn(mockSnapshot);

    // Create service with mock
    messageService = MessageService(db: mockDb);
  });

  group('MessageService', () {
    test('sendMessage creates message and updates conversation', () async {
      // Arrange
      final message = Message(
        id: '',
        senderId: 'user1',
        recipientId: 'user2',
        content: 'Test message',
        timestamp: DateTime.now(),
      );

      // Act
      await messageService.sendMessage(message);

      // Assert
      verify(mockDb.child('messages')).called(1);
      verify(mockMessagesRef.child(any)).called(1);
      verify(mockConvoIdRef.push()).called(1);
      verify(mockPushRef.set(any)).called(1);
      verify(mockDb.child('conversations')).called(1);
      verify(mockConversationsRef.child(any)).called(1);
      verify(mockConvoIdRef.update(any)).called(1);
    });

    test('editMessage updates message content', () async {
      // Arrange
      final conversationId = 'convo123';
      final messageId = 'msg123';
      final newContent = 'Updated content';
      final originalContent = 'Original content';

      // Act
      await messageService.editMessage(
        conversationId,
        messageId,
        newContent,
        originalContent,
      );

      // Assert
      verify(mockDb.child('messages')).called(1);
      verify(mockMessagesRef.child(conversationId)).called(1);
      verify(mockConvoIdRef.child(messageId)).called(1);
      verify(mockMessageIdRef.update(any)).called(1);
    });

    test('getMessagesSnapshot returns data properly', () async {
      // Arrange
      final conversationId = 'convo123';
      when(mockSnapshot.value).thenReturn({
        'msg1': {'content': 'Hello'},
        'msg2': {'content': 'World'}
      });

      // Act
      final result = await messageService.getMessagesSnapshot(conversationId);

      // Assert
      expect(result, isA<Map<dynamic, dynamic>>());
      expect(result.length, 2);
      verify(mockDb.child('messages')).called(1);
      verify(mockMessagesRef.child(conversationId)).called(1);
      verify(mockConvoIdRef.get()).called(1);
    });

    test('getMessages returns stream of messages', () {
      // Arrange
      final userId1 = 'user1';
      final userId2 = 'user2';
      when(mockSnapshot.value).thenReturn({
        'msg1': {
          'senderId': userId1,
          'recipientId': userId2,
          'content': 'Hello',
          'timestamp': DateTime.now().toIso8601String(),
        }
      });

      // Act
      final result = messageService.getMessages(userId1, userId2);

      // Assert
      expect(result, isA<Stream<List<Message>>>());
      verify(mockDb.child('messages')).called(1);
      verify(mockMessagesRef.child(any)).called(1);
      verify(mockConvoIdRef.onValue).called(1);
    });

    test('getConversations returns stream of conversations', () {
      // Arrange
      final userId = 'user123';
      when(mockConversationsRef.orderByChild('participants/$userId')).thenReturn(mockConvoIdRef);
      when(mockConvoIdRef.equalTo(true)).thenReturn(mockConvoIdRef);
      when(mockConvoIdRef.onValue).thenAnswer((_) => Stream.value(mockEvent));
      when(mockSnapshot.value).thenReturn({
        'convo1': {
          'participants': {'user123': true, 'user456': true},
          'lastMessageTime': DateTime.now().toIso8601String(),
          'lastMessageContent': 'Hello',
        }
      });

      // Act
      final result = messageService.getConversations(userId);

      // Assert
      expect(result, isA<Stream<List<Conversation>>>());
      verify(mockDb.child('conversations')).called(1);
      verify(mockConversationsRef.orderByChild('participants/$userId')).called(1);
      verify(mockConvoIdRef.equalTo(true)).called(1);
      verify(mockConvoIdRef.onValue).called(1);
    });

    test('markMessagesAsRead updates messages and removes unreadBy', () async {
      // Arrange
      final conversationId = 'convo123';
      final userId = 'user1';

      when(mockSnapshot.value).thenReturn({
        'msg1': {
          'recipientId': userId,
          'isRead': false,
        }
      });

      // Act
      await messageService.markMessagesAsRead(conversationId, userId);

      // Assert
      verify(mockDb.child('messages')).called(1);
      verify(mockMessagesRef.child(conversationId)).called(1);
      verify(mockConvoIdRef.orderByChild('recipientId')).called(1);
      verify(mockConvoIdRef.equalTo(userId)).called(1);
      verify(mockConvoIdRef.update(any)).called(1);

      verify(mockDb.child('conversations')).called(1);
      verify(mockConversationsRef.child(conversationId)).called(1);
      verify(mockConvoIdRef.child('unreadBy')).called(1);
      verify(mockUnreadByRef.child(userId)).called(1);
      verify(mockUserIdRef.remove()).called(1);
    });

    test('createOrUpdateConversation creates conversation data', () async {
      // Arrange
      final userId1 = 'user1';
      final userId2 = 'user2';
      final content = 'New message';

      // Act
      await messageService.createOrUpdateConversation(userId1, userId2, content);

      // Assert
      verify(mockDb.child('conversations')).called(1);
      verify(mockConversationsRef.child(any)).called(1);
      verify(mockConvoIdRef.update(any)).called(1);
    });

    test('getConversationId returns consistent ID regardless of order', () {
      // Act & Assert
      expect(messageService.getConversationId('user1', 'user2'), 'user1_user2');
      expect(messageService.getConversationId('user2', 'user1'), 'user1_user2');
    });
  });
}