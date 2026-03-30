import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

Future<void> saveGeneration({
    required String userId,
    required String prompt,
    required String description,
    String? imageBase64,        // ← add this
  }) async {

    // Compress base64 if too large — Firestore limit is 1MB per document
    String? imageToSave = imageBase64;
    if (imageBase64 != null && imageBase64.length > 700000) {
      // Image too large for Firestore — skip saving image
      print('[Firestore] Image too large to save: ${imageBase64.length} chars');
      imageToSave = null;
    }

    await _db.collection('generations').add({
      'userId': userId,
      'prompt': prompt,
      'description': description,
      'imageBase64': imageToSave,   // ← save image
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(userId).set({
      'thumbnailCount': FieldValue.increment(1),
      'lastUsed': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> getUserCount(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return 0;
    return doc.data()?['thumbnailCount'] ?? 0;
  }

  Stream<QuerySnapshot> getUserHistory(String userId) {
    return _db
        .collection('generations')
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }
  Future<void> deleteGeneration(String docId) async {
    await _db.collection('generations').doc(docId).delete();
  }
}