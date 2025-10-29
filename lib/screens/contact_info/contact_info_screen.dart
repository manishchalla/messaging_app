import 'package:flutter/material.dart';
import './contact_info_box.dart'; // Import the extracted widget

class ContactInfoScreen extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final String? photoUrl;

  const ContactInfoScreen({
    super.key,
    required this.displayName,
    required this.phoneNumber,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background (closes on tap)
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // Foreground info box
        Center(
          child: ContactInfoBox(
            displayName: displayName,
            phoneNumber: phoneNumber,
            photoUrl: photoUrl,
          ),
        ),
      ],
    );
  }
}