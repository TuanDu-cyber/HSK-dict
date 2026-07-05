import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

// Repository đồng bộ từ đã lưu giữa cache local và Firestore theo uid.
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class FavoritesRepository {
  FavoritesRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _keySuffix = 'favorites';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  String get _key => UserStorageKeyHelper.key(_keySuffix);

  String? get _uid {
    final uid = _firebaseAuth.currentUser?.uid.trim();

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return uid;
  }

  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  Future<Set<String>> getFavoriteIds() async {
    final uid = _uid;

    if (uid == null) {
      return _loadLocalFavoriteIds();
    }

    try {
      final snapshot = await _favoritesRef(uid).get();
      final ids = snapshot.docs
          .map((doc) => doc.data()['wordId']?.toString() ?? doc.id)
          .where((wordId) => wordId.trim().isNotEmpty)
          .toSet();

      await _saveLocalFavoriteIds(ids);

      return ids;
    } catch (error) {
      debugPrint('Không thể tải favorites từ Firestore: $error');
      return _loadLocalFavoriteIds();
    }
  }

  Future<Set<String>> _loadLocalFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? const [];

    return ids.toSet();
  }

  Future<void> _saveLocalFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }

  Future<bool> isFavorite(String wordId) async {
    final ids = await getFavoriteIds();
    return ids.contains(wordId);
  }

  Future<Set<String>> toggleFavorite(String wordId) async {
    final ids = await getFavoriteIds();
    final shouldSave = !ids.contains(wordId);

    await _setFavoriteWithIds(wordId, shouldSave, ids);

    return ids;
  }

  Future<void> setFavorite(String wordId, bool isFavorite) async {
    final ids = await getFavoriteIds();

    await _setFavoriteWithIds(wordId, isFavorite, ids);
  }

  Future<void> _setFavoriteWithIds(
    String wordId,
    bool isFavorite,
    Set<String> ids,
  ) async {
    final normalizedWordId = wordId.trim();

    if (normalizedWordId.isEmpty) {
      return;
    }

    if (isFavorite) {
      ids.add(normalizedWordId);
    } else {
      ids.remove(normalizedWordId);
    }

    await _saveLocalFavoriteIds(ids);

    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      final docRef = _favoritesRef(uid).doc(normalizedWordId);

      if (isFavorite) {
        await docRef.set({
          'wordId': normalizedWordId,
          'savedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.delete();
      }
    } catch (error) {
      debugPrint('Không thể đồng bộ favorite lên Firestore: $error');
    }
  }

  Future<void> clearFavorites() async {
    await _saveLocalFavoriteIds({});

    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      final snapshot = await _favoritesRef(uid).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (error) {
      debugPrint('Không thể xóa favorites trên Firestore: $error');
    }
  }
}
