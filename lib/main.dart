// lib/main.dart
import 'package:cocolab_messaging/screens/onboarding/onboarding_screen.dart';
import 'package:cocolab_messaging/services/local_notification_service.dart';
import 'package:cocolab_messaging/services/notification_navigation_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/contacts_grid/contacts_grid_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  // Request notification permissions
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Initialize local notifications
  await LocalNotificationService.initialize();
  LocalNotificationService.createNotificationChannel();

  // Register the background message handler
  await LocalNotificationService.handleBackgroundNotifications();

  // Handle foreground notifications
  LocalNotificationService.handleForegroundNotifications();

  // Initialize the notification navigation service
  await NotificationNavigationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoColab Messaging',
      navigatorKey: NotificationNavigationService.navigatorKey, // Use the navigator key
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[400]!,
          secondary: Colors.blueGrey[400]!,
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If user not logged in, show auth screen
        if (!authSnapshot.hasData) {
          return const AuthScreen();
        }

        // User is logged in, check if profile is completed
        final user = authSnapshot.data!;
        return FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance.ref('users/${user.uid}').get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // If snapshot doesn't exist or doesn't have a value, profile is not completed
            if (!profileSnapshot.hasData ||
                !profileSnapshot.data!.exists ||
                profileSnapshot.data!.value == null) {
              return const OnboardingScreen();
            }

            // Check if user has phone number (which means profile is completed)
            try {
              final userData = profileSnapshot.data!.value as Map<dynamic, dynamic>;
              final hasPhoneNumber = userData.containsKey('phoneNumber') &&
                  userData['phoneNumber'] != null &&
                  userData['phoneNumber'].toString().isNotEmpty;

              // If profile is completed, show contacts screen
              // Otherwise, show onboarding screen
              return hasPhoneNumber
                  ? const ContactsGridScreen()
                  : const OnboardingScreen();
            } catch (e) {
              // If there's any error parsing the data, show onboarding screen
              print('Error checking user profile: $e');
              return const OnboardingScreen();
            }
          },
        );
      },
    );
  }
}