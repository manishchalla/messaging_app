// test/helpers/test_helpers.dart
import 'package:mockito/mockito.dart';
import 'package:cocolab_messaging/models/message.dart';
import '../mocks.mocks.dart';

class TestHelpers {
  static MockUser createMockUser() {
    final mockUser = MockUser();
    when(mockUser.uid).thenReturn('test-user-id');
    when(mockUser.displayName).thenReturn('Test User');
    return mockUser;
  }

  static MockContact createMockContact() {
    final mockContact = MockContact();
    when(mockContact.displayName).thenReturn('Test Contact');
    return mockContact;
  }

  static MockAuthService createMockAuthService(MockUser mockUser) {
    final mockAuthService = MockAuthService();
    when(mockAuthService.currentUser).thenReturn(mockUser);
    return mockAuthService;
  }

  static MockMessageService createMockMessageService() {
    final mockMessageService = MockMessageService();

    // Setup the message stream
    when(mockMessageService.getMessages(any, any)).thenAnswer((_) =>
        Stream.value([
          Message(
            id: 'msg1',
            senderId: 'other-user-id',
            recipientId: 'test-user-id',
            content: 'Test message',
            timestamp: DateTime.now(),
          ),
        ])
    );

    // Setup sending messages
    when(mockMessageService.sendMessage(any)).thenAnswer((_) async {});

    // Setup editing messages
    when(mockMessageService.editMessage(any, any, any, any)).thenAnswer((_) async {});

    return mockMessageService;
  }
}