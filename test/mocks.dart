// test/mocks.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:cocolab_messaging/services/auth_service.dart';
import 'package:cocolab_messaging/services/message_service.dart';

@GenerateMocks([
  FirebaseAuth,
  User,
  DatabaseReference,
  FirebaseDatabase,
  FirebaseStorage,
  Reference,
  DataSnapshot,
  UploadTask,
  Contact,
  ImagePicker,
  AuthService,
  MessageService,
])
void main() {}