// lib/widgets/image_editor.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ImageEditor extends StatefulWidget {
  final String imageUrl;
  final Function(String) onImageSaved;

  const ImageEditor({
    Key? key,
    required this.imageUrl,
    required this.onImageSaved,
  }) : super(key: key);

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  late List<DrawingPoint?> points;
  Color selectedColor = Colors.red;
  double strokeWidth = 5.0;
  bool isLoading = false;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    points = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit Image'),
        elevation: 0,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: points.isEmpty ? null : _undoLastStroke,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : _saveImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Image with drawing overlay
                RepaintBoundary(
                  key: _repaintKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base image
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.white70,
                        ),
                      ),
                      // Drawing layer
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            points.add(
                              DrawingPoint(
                                details.localPosition,
                                Paint()
                                  ..color = selectedColor
                                  ..strokeCap = StrokeCap.round
                                  ..strokeWidth = strokeWidth
                                  ..isAntiAlias = true,
                              ),
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            points.add(
                              DrawingPoint(
                                details.localPosition,
                                Paint()
                                  ..color = selectedColor
                                  ..strokeCap = StrokeCap.round
                                  ..strokeWidth = strokeWidth
                                  ..isAntiAlias = true,
                              ),
                            );
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            // Add null to separate strokes
                            points.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(points: points),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          // Color palette and tools
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stroke width slider
                Row(
                  children: [
                    const Icon(Icons.line_weight, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: strokeWidth,
                        min: 1,
                        max: 20,
                        onChanged: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                // Color palette
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildColorButton(Colors.red),
                      _buildColorButton(Colors.blue),
                      _buildColorButton(Colors.green),
                      _buildColorButton(Colors.yellow),
                      _buildColorButton(Colors.purple),
                      _buildColorButton(Colors.orange),
                      _buildColorButton(Colors.pink),
                      _buildColorButton(Colors.teal),
                      _buildColorButton(Colors.white),
                      _buildColorButton(Colors.black),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  void _undoLastStroke() {
    if (points.isEmpty) return;

    setState(() {
      // Find the last null (which marks the end of a stroke)
      int lastNull = points.lastIndexOf(null);

      if (lastNull != -1 && lastNull == points.length - 1) {
        // If the last element is null, find the previous null
        int prevNull = points.sublist(0, lastNull).lastIndexOf(null);
        if (prevNull != -1) {
          points.removeRange(prevNull + 1, points.length);
        } else {
          // If there is no previous null, remove all points
          points.clear();
        }
      } else if (lastNull != -1) {
        // Remove from last null to end
        points.removeRange(lastNull, points.length);
      } else {
        // No nulls, clear all
        points.clear();
      }
    });
  }

  Future<void> _saveImage() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Capture the image with drawings
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save image to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${const Uuid().v4()}.png');
      await tempFile.writeAsBytes(bytes);

      // Upload to Firebase Storage with proper authorization
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images/${currentUser.uid}')
          .child('${DateTime.now().millisecondsSinceEpoch}.png');

      // Set metadata to ensure proper permissions
      final metadata = SettableMetadata(
        contentType: 'image/png',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'timestamp': DateTime.now().toIso8601String(),
          'originalImage': widget.imageUrl,
        },
      );

      await storageRef.putFile(tempFile, metadata);
      final newImageUrl = await storageRef.getDownloadURL();

      // Call the callback with the new image URL
      widget.onImageSaved(newImageUrl);

      // Clean up temp file
      await tempFile.delete();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
          points[i]!.position,
          points[i + 1]!.position,
          points[i]!.paint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        // For single point touches
        canvas.drawPoints(
          ui.PointMode.points,
          [points[i]!.position],
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class DrawingPoint {
  final Offset position;
  final Paint paint;

  DrawingPoint(this.position, this.paint);
}