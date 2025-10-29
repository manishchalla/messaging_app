import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessageService {
  final DatabaseReference _db;

  MessageService({DatabaseReference? db})
      : _db = db ?? FirebaseDatabase.instance.ref();

  // Add this public method
  String getConversationId(String userId1, String userId2) {
    return _getConversationId(userId1, userId2);
  }

  Future<void> sendMessage(Message message) async {
    try {
      // Generate a unique conversation ID
      final conversationId = _getConversationId(message.senderId, message.recipientId);

      // Push the message to the database
      final messageRef = _db.child('messages').child(conversationId).push();
      await messageRef.set(message.toMap());

      // Update the conversation metadata
      await _updateConversation(conversationId, message);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> editMessage(String conversationId, String messageId, String newContent, String originalContent) async {
    try {
      await _db.child('messages')
          .child(conversationId)
          .child(messageId)
          .update({
        'content': newContent,
        'editedAt': DateTime.now().toIso8601String(),
        'originalContent': originalContent,
      });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // New method to update the image URL of a message
  Future<void> updateMessageImage(String conversationId, String messageId, String newImageUrl) async {
    try {
      // Get the current user ID to check permissions
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if the user is allowed to edit this message (message sender)
      final messageSnapshot = await _db.child('messages').child(conversationId).child(messageId).get();
      if (!messageSnapshot.exists) {
        throw Exception('Message not found');
      }

      final messageData = Map<String, dynamic>.from(messageSnapshot.value as Map);
      final senderId = messageData['senderId'] as String;

      // Only allow the sender to update their own message
      if (senderId != currentUser.uid) {
        throw Exception('Not authorized to update this message');
      }

      // Update the message with the new image URL
      await _db.child('messages')
          .child(conversationId)
          .child(messageId)
          .update({
        'imageUrl': newImageUrl,
        'editedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update message image: $e');
    }
  }



  // New method to get a snapshot of all messages in a conversation
  Future<Map<dynamic, dynamic>> getMessagesSnapshot(String conversationId) async {
    try {
      final snapshot = await _db.child('messages').child(conversationId).get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as Map<dynamic, dynamic>;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Stream<List<Message>> getMessages(String userId1, String userId2) {
    final conversationId = _getConversationId(userId1, userId2);

    return _db
        .child('messages')
        .child(conversationId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries.map((e) => Message.fromMap(
          Map<String, dynamic>.from(e.value as Map),
          e.key as String
      )).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Stream<List<Conversation>> getConversations(String userId) {
    return _db
        .child('conversations')
        .orderByChild('participants/$userId')
        .equalTo(true)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.entries.map((e) => Conversation.fromMap(
          Map<String, dynamic>.from(e.value as Map),
          e.key as String
      )).toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    });
  }

  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final messagesRef = _db.child('messages').child(conversationId);
      final snapshot = await messagesRef
          .orderByChild('recipientId')
          .equalTo(userId)
          .get();

      if (snapshot.value != null) {
        final updates = <String, dynamic>{};
        (snapshot.value as Map).forEach((key, value) {
          if (!(value['isRead'] as bool? ?? false)) {
            updates['$key/isRead'] = true;
          }
        });

        if (updates.isNotEmpty) {
          await messagesRef.update(updates);

          // Remove this user from the unreadBy map
          await _db
              .child('conversations')
              .child(conversationId)
              .child('unreadBy')
              .child(userId)
              .remove();
        }
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  String _getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> _updateConversation(String conversationId, Message message) async {
    // Create the base updates for the conversation
    final Map<String, dynamic> updates = {
      'participants': {
        message.senderId: true,
        message.recipientId: true,
      },
      'lastMessageTime': message.timestamp.toIso8601String(),
      'lastMessageContent': message.content,
    };

    // Instead of a general hasUnreadMessages flag, use a map to track which users have unread messages
    // Only mark as unread for the recipient, not the sender
    updates['unreadBy'] = {
      message.recipientId: true
    };

    await _db.child('conversations').child(conversationId).update(updates);
  }

  Future<void> createOrUpdateConversation(String userId1, String userId2, String lastMessageContent) async {
    try {
      final conversationId = _getConversationId(userId1, userId2);
      print('Creating/updating conversation with ID: $conversationId');

      await _db.child('conversations').child(conversationId).update({
        'participants': {
          userId1: true,
          userId2: true,
        },
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageContent': lastMessageContent,
        'hasUnreadMessages': false,
      });

      print('Conversation created/updated successfully.');
    } catch (e) {
      print('Error creating/updating conversation: $e');
      throw Exception('Failed to create/update conversation: $e');
    }
  }
}