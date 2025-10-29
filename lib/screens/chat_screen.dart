// Updated chat_screen.dart with image editing functionality
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../utils/notification_test_utils.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  final String recipientId;
  final MessageService? messageService;
  final AuthService? authService;
  final ImagePicker? imagePicker;
  final FirebaseStorage? firebaseStorage;

  const ChatScreen({
    Key? key,
    required this.contact,
    required this.recipientId,
    this.messageService,
    this.authService,
    this.imagePicker,
    this.firebaseStorage,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _messageController;
  late final FocusNode _focusNode;
  late final MessageService _messageService;
  late final AuthService _authService;
  late final ScrollController _scrollController;
  late final ImagePicker _imagePicker;
  late final DatabaseReference _db;
  bool _isUploading = false;
  bool _isEditingMessage = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _messageService = widget.messageService ?? MessageService();
    _authService = widget.authService ?? AuthService();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    _db = FirebaseDatabase.instance.ref();

    // Add this: Mark messages as read when opening the chat
    _markMessagesAsRead();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

// Add this method
  void _markMessagesAsRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // Get conversation ID
    final sortedIds = [currentUser.uid, widget.recipientId]..sort();
    final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

    // Mark messages as read
    await _messageService.markMessagesAsRead(conversationId, currentUser.uid);
  }

  void _sendMessage() async {
    if (_messageController.text
        .trim()
        .isEmpty) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final message = Message(
      id: '',
      senderId: currentUser.uid,
      recipientId: widget.recipientId,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await _messageService.sendMessage(message);
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Trigger notification to the recipient with dynamic content
      await sendTestNotification(
        widget.recipientId,
        title: "${currentUser.displayName} sent you a message",
        body: message.content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _editMessage(Message message) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Use the same sorting logic as in MessageService
      final sortedIds = [currentUser.uid, widget.recipientId]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      await _messageService.editMessage(
        conversationId,
        message.id,
        message.content,
        message.originalContent ?? '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit message: $e')),
        );
      }
    }
  }

  void _handleImageEdited(String oldImageUrl, String newImageUrl) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final sortedIds = [currentUser.uid, widget.recipientId]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      // Get all messages
      final messages = await _messageService.getMessagesSnapshot(
          conversationId);

      // Find the message with the matching image URL
      Message? messageToUpdate;
      String? messageId;

      messages.forEach((key, value) {
        final message = Message.fromMap(Map<String, dynamic>.from(value), key);
        if (message.imageUrl == oldImageUrl) {
          messageToUpdate = message;
          messageId = key;
        }
      });

      // Allow updating any image, not just ones the user sent
      if (messageToUpdate != null && messageId != null) {
        await _db.child('messages')
            .child(conversationId)
            .child(messageId!)
            .update({
          'imageUrl': newImageUrl,
          'editedAt': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image updated successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not find the original message')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Take Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      setState(() => _isUploading = true);
      try {
        // Use injected or default storage
        final storage = widget.firebaseStorage ?? FirebaseStorage.instance;
        final storageRef = storage
            .ref()
            .child('chat_images/${currentUser.uid}')
            .child('${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(File(pickedFile.path));
        final imageUrl = await storageRef.getDownloadURL();

        // Create and send the message with the image URL
        final message = Message(
          id: '',
          senderId: currentUser.uid,
          recipientId: widget.recipientId,
          content: '',
          timestamp: DateTime.now(),
          imageUrl: imageUrl,
        );
        await _messageService.sendMessage(message);

        // Trigger notification to the recipient with dynamic content
        await sendTestNotification(
          widget.recipientId,
          title: "${currentUser.displayName} sent you an image",
          body: "Tap to view the image",
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send image: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.displayName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageService.getMessages(
                currentUser.uid,
                widget.recipientId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser.uid;
                    return MessageBubble(
                        message: message,
                        isMe: isMe,
                        onEdit: isMe ? _editMessage : null,
                        onEditingStateChanged: (isEditing) {
                          setState(() {
                            _isEditingMessage = isEditing;
                          });
                        },
                        onImageEdited: _handleImageEdited
                    );
                  },
                );
              },
            ),
          ),
          if (!_isEditingMessage) // Only show message input when not editing
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: _isUploading
                          ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)
                      )
                          : const Icon(Icons.image),
                      onPressed: _isUploading ? null : _showImageSourceDialog,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isUploading ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}