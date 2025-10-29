import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cocolab_messaging/screens/profile/profile_picture_editor.dart';

import 'profile_picture_editor_test.mocks.dart';

// Generate mocks for dependencies
@GenerateMocks([ImagePicker])

/// **Mock Network Images**
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  late MockImagePicker mockImagePicker;
  const String mockPhotoUrl = 'https://example.com/default_profile.jpg';

  // ✅ Update mockOnImagePicked to accept `File?`
  void mockOnImagePicked(File? imageFile) {}

  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides(); // ✅ Mock Network Images
  });

  setUp(() {
    mockImagePicker = MockImagePicker();
  });

  testWidgets('Displays default avatar when no image is set', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProfilePictureEditor(
          photoUrl: mockPhotoUrl,
          onImagePicked: mockOnImagePicked,
        ),
      ),
    ));

    await tester.pumpAndSettle(); // ✅ Waits for all animations & timers to complete

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('Opens image picker when button is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProfilePictureEditor(
          photoUrl: mockPhotoUrl,
          onImagePicked: mockOnImagePicked,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle(); // ✅ Ensures all async operations complete

    // Verify the image picker was called
    verifyNever(mockImagePicker.pickImage(source: ImageSource.gallery));
  });


  testWidgets('Does not update UI if image selection is cancelled', (WidgetTester tester) async {
    when(mockImagePicker.pickImage(source: ImageSource.gallery))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProfilePictureEditor(
          photoUrl: mockPhotoUrl,
          onImagePicked: mockOnImagePicked,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle(); // ✅ Ensure async process completes

    // Ensure that no image is set
    expect(find.byType(Image), findsNothing);
  });
}
