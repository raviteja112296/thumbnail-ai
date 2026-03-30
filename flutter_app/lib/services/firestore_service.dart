import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveGeneration({
    required String userId,
    required String prompt,
    required String description,
  }) async {
    await _db.collection('generations').add({
      'userId': userId,
      'prompt': prompt,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment user's usage count
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
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }
}