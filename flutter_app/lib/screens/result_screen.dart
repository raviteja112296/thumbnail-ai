import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ResultScreen extends StatefulWidget {
  final String prompt;
  final String description;
  final String? imageBase64;
  final bool hasImage;
  final String? message;

  const ResultScreen({
    super.key,
    required this.prompt,
    required this.description,
    this.imageBase64,
    this.hasImage = false,
    this.message,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveThumbnail() async {
    if (widget.imageBase64 == null) return;
    setState(() => _saving = true);

    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final bytes = base64Decode(widget.imageBase64!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Save to Downloads
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          final file = File('${downloadsDir.path}/thumbnail_$timestamp.png');
          await file.writeAsBytes(bytes);
        }
      } catch (_) {}

      // Fallback to app documents
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/thumbnail_$timestamp.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() { _saving = false; _saved = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thumbnail saved to Downloads!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'),
              backgroundColor: Colors.red.shade700));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Thumbnail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy description',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.description));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!')));
            }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Thumbnail image or warm-up notice ──
            if (widget.hasImage && widget.imageBase64 != null) ...[
              const Text('Generated Thumbnail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.memory(
                    base64Decode(widget.imageBase64!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveThumbnail,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_saved ? Icons.check : Icons.download,
                        color: Colors.white),
                label: Text(
                  _saving ? 'Saving...' : _saved
                      ? 'Saved!' : 'Save Thumbnail (PNG)',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: _saved
                      ? Colors.green.shade700 : const Color(0xFF6C63FF)),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700)),
                child: Column(children: [
                  const Icon(Icons.hourglass_top,
                      color: Colors.amber, size: 40),
                  const SizedBox(height: 12),
                  Text(widget.message ??
                      'Image model is warming up. Go back and try again in 20 seconds.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15)),
                ]),
              ),
            ],

            const SizedBox(height: 28),

            // ── AI Description ──
            const Text('AI Design Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10)),
              child: Text(widget.description,
                style: const TextStyle(fontSize: 13, height: 1.6)),
            ),

            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.refresh),
              label: const Text('Generate Another'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}