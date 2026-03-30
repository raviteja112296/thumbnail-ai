import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'generate_screen.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String docId;
  final String prompt;
  final String description;
  final String createdAt;
  final String? imageBase64;
  const HistoryDetailScreen({
    super.key,
    required this.docId,
    required this.prompt,
    required this.description,
    required this.createdAt, this.imageBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generation Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy description',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: description));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Description copied!'),
                  behavior: SnackBarBehavior.floating));
            }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Date
            Row(children: [
              const Icon(Icons.access_time,
                size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(createdAt,
                style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
            ]),

            const SizedBox(height: 20),
// Add after date row
if (imageBase64 != null && imageBase64!.isNotEmpty) ...[
  const SizedBox(height: 16),
  const Text('Generated Thumbnail',
    style: TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold)),
  const SizedBox(height: 8),
  ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.memory(
        base64Decode(imageBase64!),
        fit: BoxFit.cover,
      ),
    ),
  ),
  const SizedBox(height: 12),
  // Download button
  OutlinedButton.icon(
    onPressed: () => {},
    icon: const Icon(Icons.download),
    label: const Text('Save to Phone'),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 46)),
  ),
],
            // Prompt section
            const Text('Prompt used',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3))),
              child: Text(prompt,
                style: const TextStyle(
                  fontSize: 15, height: 1.6)),
            ),

            const SizedBox(height: 24),

            // Description section
            const Text('AI Design Description',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10)),
              child: Text(description,
                style: const TextStyle(
                  fontSize: 13, height: 1.6)),
            ),

            const SizedBox(height: 28),

            // Regenerate button
            ElevatedButton.icon(
              onPressed: () {
                // Go to generate screen with pre-filled prompt
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenerateScreen(
                      initialPrompt: prompt)));
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Regenerate This Thumbnail',
                style: TextStyle(color: Colors.white, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF6C63FF)),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to History'),
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