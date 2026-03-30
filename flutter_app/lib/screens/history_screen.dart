import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().userId;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        actions: [
          // Usage count badge
          StreamBuilder<QuerySnapshot>(
            stream: firestore.getUserHistory(userId),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '$count generated',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.getUserHistory(userId),
        builder: (context, snapshot) {

          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF)));
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                    color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                    size: 80,
                    color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text(
                    'No thumbnails yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Generate your first thumbnail!',
                    style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Generate Now',
                      style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF))),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _HistoryCard(
                docId: doc.id,
                data: data,
                firestore: firestore,
              );
            },
          );
        },
      ),
    );
  }
}


class _HistoryCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirestoreService firestore;

  const _HistoryCard({
    required this.docId,
    required this.data,
    required this.firestore,
  });

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown date';
    }
  }

  @override
Widget build(BuildContext context) {
  final prompt = data['prompt'] as String? ?? 'No prompt';
  final description = data['description'] as String? ?? '';
  final createdAt = data['createdAt'];
  final imageBase64 = data['imageBase64'] as String?;  // ← get image

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HistoryDetailScreen(
            docId: docId,
            prompt: prompt,
            description: description,
            createdAt: _formatDate(createdAt),
            imageBase64: imageBase64,    // ← pass image
          ))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Thumbnail image preview ──────────────────────────
          if (imageBase64 != null && imageBase64.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(
                  base64Decode(imageBase64),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                        color: Colors.grey, size: 40))),
                ),
              ),
            )
          else
            // Placeholder when no image saved
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12)),
              child: Container(
                height: 120,
                color: Colors.grey.shade900,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                        color: Colors.grey.shade600, size: 36),
                      const SizedBox(height: 8),
                      Text('No preview saved',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Card content ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Top row — date + delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.access_time,
                        size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500)),
                    ]),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Prompt
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.auto_awesome,
                        color: Color(0xFF6C63FF), size: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600))),
                  ],
                ),

                const SizedBox(height: 10),

                // View details chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                      child: const Row(children: [
                        Text('View details',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios,
                          size: 10, color: Color(0xFF6C63FF)),
                      ]),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text(
          'This will permanently remove this generation from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // await firestore.deleteGeneration(docId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deleted successfully'),
                    behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Delete',
              style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
