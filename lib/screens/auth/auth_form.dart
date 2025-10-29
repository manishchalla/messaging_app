import 'package:flutter/material.dart';

class AuthForm extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleSignIn;

  const AuthForm({
    Key? key,
    required this.isLoading,
    required this.onGoogleSignIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to CoColab Messaging',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          if (isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: onGoogleSignIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}