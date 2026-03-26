import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService<T> {
  final CollectionReference ref;
  final T Function(String id, Map<String, dynamic> data) fromMap;
  final Map<String, dynamic> Function(T obj) toMap;

  FirestoreService({
    required this.ref,
    required this.fromMap,
    required this.toMap,
  });

  /// Create or overwrite document
  Future<void> add(String id, T obj) async {
    await ref.doc(id).set(toMap(obj));
  }

  /// Get single document by ID
  Future<T?> getById(String id) async {
    final doc = await ref.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map));
    }
    return null;
  }

  /// Get all documents
  Future<List<T>> getAll() async {
    final snapshot = await ref.get();
    return snapshot.docs
        .map((doc) => fromMap(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
        .toList();
  }

  /// Update document (merge fields)
  Future<void> update(String id, T obj) async {
    await ref.doc(id).update(toMap(obj));
  }

  /// Delete document
  Future<void> delete(String id) async {
    await ref.doc(id).delete();
  }
}