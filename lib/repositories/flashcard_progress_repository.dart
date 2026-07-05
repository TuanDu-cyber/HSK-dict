import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

final flashcardProgressRepositoryProvider =
    Provider<FlashcardProgressRepository>((ref) {
      return FlashcardProgressRepository(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
    });

class FlashcardProgressData {
  const FlashcardProgressData({
    required this.currentIndex,
    required this.knownWordIds,
    required this.unknownWordIds,
    required this.favoriteWordIds,
  });

  /// currentIndex là index thật trong list, bắt đầu từ 0.
  /// Ví dụ:
  /// - Đang ở thẻ 1/9  => currentIndex = 0
  /// - Đang ở thẻ 5/9  => currentIndex = 4
  /// - Đang ở thẻ 9/9  => currentIndex = 8
  final int currentIndex;

  final Set<String> knownWordIds;
  final Set<String> unknownWordIds;
  final Set<String> favoriteWordIds;

  Map<String, dynamic> toJson() {
    return {
      'currentIndex': currentIndex,
      'knownWordIds': knownWordIds.toList(),
      'unknownWordIds': unknownWordIds.toList(),
    };
  }

  factory FlashcardProgressData.fromJson(Map<String, dynamic> json) {
    return FlashcardProgressData(
      currentIndex: int.tryParse(json['currentIndex']?.toString() ?? '') ?? 0,
      knownWordIds: _readStringSet(json['knownWordIds']),
      unknownWordIds: _readStringSet(json['unknownWordIds']),
      favoriteWordIds: _readStringSet(json['favoriteWordIds']),
    );
  }

  static Set<String> _readStringSet(dynamic value) {
    if (value is! List) return {};
    return value.map((item) => item.toString()).toSet();
  }
}

class FlashcardProgressRepository {
  FlashcardProgressRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  String? get _uid {
    final uid = _firebaseAuth.currentUser?.uid.trim();

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return uid;
  }

  String _key(String topic) {
    final normalizedTopic = _normalizeTopic(topic);
    return UserStorageKeyHelper.key('flashcard_$normalizedTopic');
  }

  String _documentId(String topic) {
    return 'flashcard_${_normalizeTopic(topic)}';
  }

  DocumentReference<Map<String, dynamic>> _progressDoc(
    String uid,
    String topic,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(_documentId(topic));
  }

  String _normalizeTopic(String topic) {
    return topic
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<FlashcardProgressData?> loadProgress(String topic) async {
    final uid = _uid;

    if (uid == null) {
      return _loadLocalProgress(topic);
    }

    try {
      final doc = await _progressDoc(uid, topic).get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null) {
          final progress = FlashcardProgressData.fromJson(data);
          await _saveLocalProgress(topic: topic, data: progress);

          return progress;
        }
      }
    } catch (error) {
      debugPrint('Không thể tải Flashcard progress từ Firestore: $error');
    }

    return _loadLocalProgress(topic);
  }

  Future<FlashcardProgressData?> _loadLocalProgress(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(topic));

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return FlashcardProgressData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress({
    required String topic,
    required FlashcardProgressData data,
  }) async {
    await _saveLocalProgress(topic: topic, data: data);

    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      await _progressDoc(uid, topic).set({
        'topic': topic,
        'currentIndex': data.currentIndex,
        'knownWordIds': data.knownWordIds.toList(),
        'unknownWordIds': data.unknownWordIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Không thể đồng bộ Flashcard progress lên Firestore: $error');
    }
  }

  Future<void> _saveLocalProgress({
    required String topic,
    required FlashcardProgressData data,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key(topic), jsonEncode(data.toJson()));
  }

  Future<void> clearProgress(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(topic));

    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      await _progressDoc(uid, topic).delete();
    } catch (error) {
      debugPrint('Không thể xóa Flashcard progress trên Firestore: $error');
    }
  }

  /// Dùng cho Topic Select.
  ///
  /// Mục tiêu:
  /// - Chưa từng học topic => 0/total
  /// - Đã vào và đang học thẻ 1 => 1/total
  /// - Đang học thẻ 5 => 5/total
  /// - Đang ở thẻ cuối => total/total
  ///
  /// Vì currentIndex bắt đầu từ 0 nên cần +1 khi hiển thị.
  Future<int> getCurrentPositionCount(String topic) async {
    final progress = await loadProgress(topic);

    if (progress == null) {
      return 0;
    }

    return progress.currentIndex + 1;
  }

  /// Dùng nếu sau này anh muốn hiển thị số từ đã kéo sang phải.
  /// Không dùng hàm này cho TopicCard nếu anh muốn hiển thị tiến trình vị trí thẻ.
  Future<int> getKnownCount(String topic) async {
    final progress = await loadProgress(topic);
    return progress?.knownWordIds.length ?? 0;
  }

  /// Dùng nếu muốn hiển thị số từ chưa thuộc.
  Future<int> getUnknownCount(String topic) async {
    final progress = await loadProgress(topic);
    return progress?.unknownWordIds.length ?? 0;
  }
}
