import 'package:flutter/material.dart';

class ContactInfoBox extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final String? photoUrl;

  const ContactInfoBox({
    Key? key,
    required this.displayName,
    required this.phoneNumber,
    this.photoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      width: MediaQuery.of(context).size.width * 0.65,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black45,
              blurRadius: 15,
              offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            backgroundColor: Colors.blue[900],
            child: photoUrl == null
                ? Text(
              _getInitials(displayName),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            phoneNumber,
            style: const TextStyle(
                fontSize: 18,
                color: Colors.white70
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: Colors.blue[400], size: 24),
              const SizedBox(width: 8),
              Icon(Icons.email, color: Colors.blue[400], size: 24),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final names = name.split(" ");
    return names.length > 1
        ? "${names[0][0]}${names[1][0]}".toUpperCase()
        : name[0].toUpperCase();
  }
}