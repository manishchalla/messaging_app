import 'package:flutter/material.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const ProfileForm({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),

            helperText: 'Phone number cannot be changed',
            helperStyle: TextStyle(fontStyle: FontStyle.italic),
          ),
          readOnly: true,
          enabled: false,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}