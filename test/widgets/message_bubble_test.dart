// test/widgets/message_bubble_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cocolab_messaging/models/message.dart';
import 'package:cocolab_messaging/widgets/message_bubble.dart';

void main() {
  group('MessageBubble Tests', () {
    testWidgets('displays message content', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('aligns to right when isMe is true', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      // Find the alignment of the root align widget that wraps the message bubble
      // Use first() to get the specific alignment widget we want to test
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('aligns to left when isMe is false', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: false,
          ),
        ),
      ));

      // Use first() to get the specific alignment widget
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('shows edit button when isMe and message can be edited', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows edited indicator when message is edited', (WidgetTester tester) async {
      final now = DateTime.now();
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: now.subtract(const Duration(minutes: 10)),
        editedAt: now,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      expect(find.text('(edited)'), findsOneWidget);
    });



    // Testing message editing flow using GestureDetector
    testWidgets('can enter edit mode and save edited message', (WidgetTester tester) async {
      Message? editedMessage;
      bool? editingState;

      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
            onEdit: (msg) {
              editedMessage = msg;
            },
            onEditingStateChanged: (state) {
              editingState = state;
            },
          ),
        ),
      ));

      // Use longPress on the text
      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      // Verify edit mode is entered
      expect(editingState, isTrue);
      expect(find.byType(TextField), findsOneWidget);

      // Enter new text (need to find the TextField first)
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Edited message');
      await tester.pump();

      // Find and tap the save button
      final saveButton = find.byIcon(Icons.check);
      await tester.tap(saveButton);
      await tester.pump();

      // Verify edit was saved
      expect(editedMessage?.content, 'Edited message');
      expect(editingState, isFalse);
    });

    // Testing _saveEdit method with empty content
    testWidgets('does not save edit when content is empty', (WidgetTester tester) async {
      bool editCalled = false;

      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
            onEdit: (_) {
              editCalled = true;
            },
          ),
        ),
      ));

      // Enter edit mode
      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      // Clear the text
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      // Try to save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // onEdit should not be called
      expect(editCalled, isFalse);
    });

    // Testing keyboard submission for edit
    testWidgets('saves edit when pressing enter key', (WidgetTester tester) async {
      Message? editedMessage;

      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
            onEdit: (msg) {
              editedMessage = msg;
            },
          ),
        ),
      ));

      // Enter edit mode
      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      // Enter new text
      await tester.enterText(find.byType(TextField), 'Submitted message');
      await tester.pump();

      // Simulate keyboard submission
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify edit was saved
      expect(editedMessage?.content, 'Submitted message');
    });

    // Testing image visibility
    testWidgets('renders image container when imageUrl is provided', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: '',
        timestamp: DateTime.now(),
        imageUrl: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      // Find ClipRRect which should wrap the image
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    // Testing edited message indicator
    testWidgets('shows edited indicator for edited messages', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Edited content',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        editedAt: DateTime.now(),
        originalContent: 'Original content',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      expect(find.text('(edited)'), findsOneWidget);
    });

    // Testing that edit button isn't shown for messages with images


// Testing the _formatTimestamp method with various time formats
    testWidgets('formats different timestamps correctly', (WidgetTester tester) async {
      final morningTime = DateTime(2023, 1, 1, 9, 5);
      final eveningTime = DateTime(2023, 1, 1, 21, 15);

      await tester.pumpWidget(MaterialApp(
        home: Column(
          children: [
            MessageBubble(
              message: Message(
                id: '1',
                senderId: 'sender1',
                recipientId: 'recipient1',
                content: 'Morning message',
                timestamp: morningTime,
              ),
              isMe: true,
            ),
            MessageBubble(
              message: Message(
                id: '2',
                senderId: 'sender1',
                recipientId: 'recipient1',
                content: 'Evening message',
                timestamp: eveningTime,
              ),
              isMe: false,
            ),
          ],
        ),
      ));

      expect(find.text('09:05'), findsOneWidget);
      expect(find.text('21:15'), findsOneWidget);
    });

// Testing the widget when both text and image are present
    testWidgets('renders both image and text correctly', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Image description',
        timestamp: DateTime.now(),
        imageUrl: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      expect(find.text('Image description'), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

// Testing that edit button isn't shown when message is not from current user
    testWidgets('does not show edit button for received messages', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Received message',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: false,
          ),
        ),
      ));

      expect(find.byIcon(Icons.edit), findsNothing);
    });

// Testing the edit button direct tap

// Testing the disposeFocusNode and disposeController methods
    testWidgets('properly disposes resources when removed', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: message,
            isMe: true,
            key: const Key('bubble'),
          ),
        ),
      ));

      // Replace with empty container
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SizedBox(),
        ),
      ));

      // No errors should be thrown during disposal
      expect(find.byKey(const Key('bubble')), findsNothing);
    });

// Testing cancelEdit scenario


    testWidgets('shows spacing between image and text when both exist', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Image description',
        timestamp: DateTime.now(),
        imageUrl: 'https://example.com/image.jpg',
      );

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      // Find SizedBox that creates spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('calls onEditingStateChanged when entering edit mode', (WidgetTester tester) async {
      bool? editStateChanged;

      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: MessageBubble(
            message: message,
            isMe: true,
            onEditingStateChanged: (state) {
              editStateChanged = state;
            },
          ),
        ),
      ));

      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      expect(editStateChanged, isTrue);
    });

    testWidgets('exit edit mode when saving edit', (WidgetTester tester) async {
      bool? editingState;
      Message? editedMessage;

      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: MessageBubble(
            message: message,
            isMe: true,
            onEditingStateChanged: (state) {
              editingState = state;
            },
            onEdit: (msg) {
              editedMessage = msg;
            },
          ),
        ),
      ));

      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      expect(editingState, isTrue);

      // Find and tap check icon
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(editingState, isFalse);
      expect(editedMessage, isNotNull);
    });

    testWidgets('originalContent is preserved when editing', (WidgetTester tester) async {
      Message? editedMessage;

      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Original text',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: MessageBubble(
            message: message,
            isMe: true,
            onEdit: (msg) {
              editedMessage = msg;
            },
          ),
        ),
      ));

      await tester.longPress(find.text('Original text'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Updated text');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(editedMessage?.content, 'Updated text');
      expect(editedMessage?.originalContent, 'Original text');
    });

    testWidgets('edit controller text is initialized with current content', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Test content',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      await tester.longPress(find.text('Test content'));
      await tester.pump();

      // Check TextField has correct text
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Test content');
    });

    testWidgets('focus is requested when entering edit mode', (WidgetTester tester) async {
      final message = Message(
        id: '1',
        senderId: 'sender1',
        recipientId: 'recipient1',
        content: 'Hello world',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: MessageBubble(
            message: message,
            isMe: true,
          ),
        ),
      ));

      await tester.longPress(find.text('Hello world'));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);
    });




  });
}