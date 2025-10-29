import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:cocolab_messaging/widgets/image_editor.dart';
import '../mocks.mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;
  late MockUploadTask mockUploadTask;
  late MockUser mockUser;

  setUp(() {
    // Initialize mock objects
    mockAuth = MockFirebaseAuth();
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();
    mockUploadTask = MockUploadTask();
    mockUser = MockUser();

    // Mock authentication: Assume a user is logged in
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_uid');

    // Mock Firebase Storage references
    when(mockStorage.ref()).thenReturn(mockRef);
  });
  testWidgets('Image Editor renders correctly', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: ImageEditor(
          imageUrl: 'https://test.com/image.png',
          onImageSaved: (url) {},
        ),
      ),
    );

    // Verify if the ImageEditor widget appears on the screen
    expect(find.byType(ImageEditor), findsOneWidget);
  });
}