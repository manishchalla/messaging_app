// lib/widgets/custom_contact_avatar.dart
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class CustomContactAvatar extends StatelessWidget {
  final Contact contact;
  final double radius;
  final bool isIOS;

  static const List<Color> _avatarColors = [
    Color(0xFF1abc9c),
    Color(0xFF2ecc71),
    Color(0xFF3498db),
    Color(0xFF9b59b6),
    Color(0xFFf1c40f),
    Color(0xFFe67e22),
    Color(0xFFe74c3c),
    Color(0xFF34495e),
  ];

  const CustomContactAvatar({
    super.key,
    required this.contact,
    this.radius = 40,
    this.isIOS = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorIndex = _generateColorIndex(contact.displayName);
    final backgroundColor = _avatarColors[colorIndex];
    final textColor = _getContrastingTextColor(backgroundColor);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(contact.displayName),
          style: TextStyle(
            color: textColor,
            fontSize: radius * 0.8,
            fontWeight: isIOS ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String displayName) {
    if (displayName.isEmpty) return "?";
    final names = displayName.trim().split(" ");
    if (names.length >= 2) {
      return "${names[0][0]}${names[1][0]}".toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  int _generateColorIndex(String name) {
    if (name.isEmpty) return 0;
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash.abs() % _avatarColors.length;
  }

  Color _getContrastingTextColor(Color backgroundColor) {
    final luminance = (0.299 * backgroundColor.r +
        0.587 * backgroundColor.g +
        0.114 * backgroundColor.b) /
        255;
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}