import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePictureEditor extends StatefulWidget {
  final String? photoUrl;
  final Function(File?) onImagePicked;

  const ProfilePictureEditor({
    super.key,
    required this.photoUrl,
    required this.onImagePicked,
  });

  @override
  State<ProfilePictureEditor> createState() => _ProfilePictureEditorState();
}

class _ProfilePictureEditorState extends State<ProfilePictureEditor> {
  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedImage != null) {
      setState(() => _imageFile = File(pickedImage.path));
      widget.onImagePicked(_imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null),
          child: _imageFile == null && widget.photoUrl == null
              ? const Icon(Icons.camera_alt, size: 40)
              : null,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.camera_alt,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}