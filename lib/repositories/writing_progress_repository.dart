import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

final writingProgressRepositoryProvider = Provider<WritingProgressRepository>((
  ref,
) {
  return WritingProgressRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class WritingProgressData {
  const WritingProgressData({
    required this.currentIndex,
    required this.currentCharIndex,
    required this.sessionSeed,
    required this.wordIds,
    required this.completedCharIds,
    required this.wrongCharIds,
    required this.skippedCharIds,
    required this.attemptCountByCharId,
    required this.isCompleted,
  });

  final int currentIndex;
  final int currentCharIndex;
  final int sessionSeed;
  final List<String> wordIds;
  final Set<String> completedCharIds;
  final Set<String> wrongCharIds;
  final Set<String> skippedCharIds;
  final Map<String, int> attemptCountByCharId;
  final bool isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'currentIndex': currentIndex,
      'currentCharIndex': currentCharIndex,
      'sessionSeed': sessionSeed,
      'wordIds': wordIds,
      'completedCharIds': completedCharIds.toList(),
      'wrongCharIds': wrongCharIds.toList(),
      'skippedCharIds': skippedCharIds.toList(),
      'attemptCountByCharId': attemptCountByCharId,
      'isCompleted': isCompleted,
    };
  }

  factory WritingProgressData.fromJson(Map<String, dynamic> json) {
    return WritingProgressData(
      currentIndex: int.tryParse(json['currentIndex']?.toString() ?? '') ?? 0,
      currentCharIndex:
          int.tryParse(json['currentCharIndex']?.toString() ?? '') ?? 0,
      sessionSeed: int.tryParse(json['sessionSeed']?.toString() ?? '') ?? 0,
      wordIds: _readStringList(json['wordIds']),
      completedCharIds: _readStringSet(
        json['completedCharIds'] ?? json['completedWordIds'],
      ),
      wrongCharIds: _readStringSet(
        json['wrongCharIds'] ?? json['wrongWordIds'],
      ),
      skippedCharIds: _readStringSet(
        json['skippedCharIds'] ?? json['skippedWordIds'],
      ),
      attemptCountByCharId: _readIntMap(
        json['attemptCountByCharId'] ?? json['attemptCountByWordId'],
      ),
      isCompleted: json['isCompleted'] == true,
    );
  }

  static Set<String> _readStringSet(dynamic value) {
    if (value is! List) return {};
    return value.map((item) => item.toString()).toSet();
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  static Map<String, int> _readIntMap(dynamic value) {
    if (value is! Map) return {};

    final result = <String, int>{};

    value.forEach((key, mapValue) {
      result[key.toString()] = int.tryParse(mapValue.toString()) ?? 0;
    });

    return result;
  }
}

class WritingProgressRepository {
  WritingProgressRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  String? get _uid {
    final uid = _firebaseAuth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return null;
    return uid;
  }

  String _key(String topic) {
    return UserStorageKeyHelper.key('writing_${_normalizeTopic(topic)}');
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

  String _documentId(String topic) {
    return 'writing_${_normalizeTopic(topic)}';
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

  Future<WritingProgressData?> loadProgress(String topic) async {
    final uid = _uid;

    if (uid == null) {
      return _loadLocalProgress(topic);
    }

    try {
      final doc = await _progressDoc(uid, topic).get();
      final data = doc.data();

      if (doc.exists && data != null) {
        final progress = WritingProgressData.fromJson(data);
        await _saveLocalProgress(topic: topic, data: progress);
        return progress;
      }
    } catch (error) {
      debugPrint('Không thể tải Writing progress từ Firestore: $error');
    }

    return _loadLocalProgress(topic);
  }

  Future<WritingProgressData?> _loadLocalProgress(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(topic));

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return WritingProgressData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress({
    required String topic,
    required WritingProgressData data,
  }) async {
    await _saveLocalProgress(topic: topic, data: data);

    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      await _progressDoc(uid, topic).set({
        'topic': topic,
        'sessionSeed': data.sessionSeed,
        'wordIds': data.wordIds,
        'currentIndex': data.currentIndex,
        'currentCharIndex': data.currentCharIndex,
        'completedCharIds': data.completedCharIds.toList(),
        'completedWordIds': data.completedCharIds.toList(),
        'wrongCharIds': data.wrongCharIds.toList(),
        'wrongWordIds': data.wrongCharIds.toList(),
        'skippedCharIds': data.skippedCharIds.toList(),
        'skippedWordIds': data.skippedCharIds.toList(),
        'attemptCountByCharId': data.attemptCountByCharId,
        'isCompleted': data.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Không thể đồng bộ Writing progress lên Firestore: $error');
    }
  }

  Future<void> _saveLocalProgress({
    required String topic,
    required WritingProgressData data,
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
      debugPrint('Không thể xóa Writing progress trên Firestore: $error');
    }
  }

  Future<int> getCurrentPositionCount(String topic) async {
    final progress = await loadProgress(topic);

    if (progress == null) {
      return 0;
    }

    final hasStarted =
        progress.completedCharIds.isNotEmpty ||
        progress.wrongCharIds.isNotEmpty ||
        progress.skippedCharIds.isNotEmpty ||
        progress.attemptCountByCharId.isNotEmpty ||
        progress.currentIndex > 0 ||
        progress.currentCharIndex > 0 ||
        progress.isCompleted;

    if (!hasStarted) {
      return 0;
    }

    return progress.currentIndex + 1;
  }
}
