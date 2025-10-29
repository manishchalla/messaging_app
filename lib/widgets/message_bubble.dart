// Updated message_bubble.dart with image editing functionality
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import '../models/message.dart';
import '../widgets/image_editor.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final Function(Message)? onEdit;
  final Function(bool)? onEditingStateChanged;
  final Function(String, String)? onImageEdited;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onEdit,
    this.onEditingStateChanged,
    this.onImageEdited,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _editController;
  late FocusNode _editFocusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _editFocusNode = FocusNode();
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Everyone can edit any image
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => _editImage(context, imageUrl),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Save'),
                  onPressed: () => _saveImageToGallery(context, imageUrl),
                ),
                const SizedBox(width: 12),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editImage(BuildContext context, String imageUrl) {
    // Close the current dialog
    Navigator.pop(context);

    // Open the image editor
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          imageUrl: imageUrl,
          onImageSaved: (newImageUrl) {
            // Callback when the image is saved with edits
            if (widget.onImageEdited != null) {
              widget.onImageEdited!(imageUrl, newImageUrl);
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveImageToGallery(BuildContext context, String imageUrl) async {
    try {
      // Request appropriate permission based on Android version
      bool permissionGranted = false;

      if (Platform.isAndroid) {
        // For Android 13+
        if (await Permission.photos.request().isGranted) {
          permissionGranted = true;
        } else if (await Permission.storage.request().isGranted) {
          // For older Android versions
          permissionGranted = true;
        }
      } else {
        // For iOS
        if (await Permission.photos.request().isGranted) {
          permissionGranted = true;
        }
      }

      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required')),
        );
        return;
      }
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving image...'), duration: Duration(seconds: 1)),
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);

      // Save to gallery using the File
      await FlutterImageGallerySaver.saveFile(tempPath);

      // Clean up temp file
      await file.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _toggleEdit() {
    if (widget.isMe && widget.message.canEdit) {
      setState(() {
        _isEditing = !_isEditing;
        widget.onEditingStateChanged?.call(_isEditing);
        if (_isEditing) {
          _editController.text = widget.message.content;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusScope.of(context).requestFocus(_editFocusNode);
          });
        }
      });
    }
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty) {
      widget.onEdit?.call(widget.message.copyWith(
        content: _editController.text.trim(),
        editedAt: DateTime.now(),
        originalContent: widget.message.originalContent ?? widget.message.content,
      ));
      setState(() {
        _isEditing = false;
      });
      widget.onEditingStateChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.blue[700] : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.imageUrl != null)
                    GestureDetector(
                      onTap: () => _showFullImage(context, widget.message.imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: widget.message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  if (widget.message.content.isNotEmpty) ...[
                    if (widget.message.imageUrl != null) const SizedBox(height: 8),
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                              child: TextField(
                                controller: _editController,
                                focusNode: _editFocusNode,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                autofocus: true,
                                onSubmitted: (_) => _saveEdit(),
                              )
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.white, size: 16),
                            onPressed: _saveEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onLongPress: _toggleEdit,
                        child: Text(
                          widget.message.content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(widget.message.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      if (widget.message.isEdited) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '(edited)',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Only show edit button for text messages that have no images and were sent by the current user
            if (widget.isMe && widget.message.canEdit && !_isEditing && widget.message.content.isNotEmpty && widget.message.imageUrl == null)
              Positioned(
                bottom: -8,
                right: -15,
                child: Container(
                  width: 30,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10, width: 0.5),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                    onPressed: _toggleEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }
}