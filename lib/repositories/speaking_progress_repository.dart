import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

final speakingProgressRepositoryProvider = Provider<SpeakingProgressRepository>(
  (ref) {
    return SpeakingProgressRepository(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
  },
);

class SpeakingProgressData {
  const SpeakingProgressData({
    required this.currentIndex,
    required this.sessionSeed,
    required this.wordIds,
    required this.scoreByWordId,
    required this.initialScoreByWordId,
    required this.finalScoreByWordId,
    required this.toneScoreByWordId,
    required this.feedbackByWordId,
    required this.recognizedTextByWordId,
    required this.completedWordIds,
    required this.lowScoreWordIds,
    required this.skippedWordIds,
    required this.isCompleted,
  });

  final int currentIndex;
  final int sessionSeed;
  final List<String> wordIds;

  final Map<String, int> scoreByWordId;
  final Map<String, int> initialScoreByWordId;
  final Map<String, int> finalScoreByWordId;
  final Map<String, int> toneScoreByWordId;
  final Map<String, String> feedbackByWordId;
  final Map<String, String> recognizedTextByWordId;

  final Set<String> completedWordIds;
  final Set<String> lowScoreWordIds;
  final Set<String> skippedWordIds;

  final bool isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'currentIndex': currentIndex,
      'sessionSeed': sessionSeed,
      'wordIds': wordIds,
      'scoreByWordId': scoreByWordId,
      'initialScoreByWordId': initialScoreByWordId,
      'finalScoreByWordId': finalScoreByWordId,
      'toneScoreByWordId': toneScoreByWordId,
      'feedbackByWordId': feedbackByWordId,
      'recognizedTextByWordId': recognizedTextByWordId,
      'completedWordIds': completedWordIds.toList(),
      'lowScoreWordIds': lowScoreWordIds.toList(),
      'skippedWordIds': skippedWordIds.toList(),
      'isCompleted': isCompleted,
    };
  }

  factory SpeakingProgressData.fromJson(Map<String, dynamic> json) {
    return SpeakingProgressData(
      currentIndex: int.tryParse(json['currentIndex']?.toString() ?? '') ?? 0,
      sessionSeed: int.tryParse(json['sessionSeed']?.toString() ?? '') ?? 0,
      wordIds: _readStringList(json['wordIds']),
      scoreByWordId: _readIntMap(json['scoreByWordId']),
      initialScoreByWordId: _readIntMap(json['initialScoreByWordId']),
      finalScoreByWordId: _readIntMap(json['finalScoreByWordId']),
      toneScoreByWordId: _readIntMap(json['toneScoreByWordId']),
      feedbackByWordId: _readStringMap(json['feedbackByWordId']),
      recognizedTextByWordId: _readStringMap(json['recognizedTextByWordId']),
      completedWordIds: _readStringSet(json['completedWordIds']),
      lowScoreWordIds: _readStringSet(json['lowScoreWordIds']),
      skippedWordIds: _readStringSet(json['skippedWordIds']),
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

  static Map<String, String> _readStringMap(dynamic value) {
    if (value is! Map) return {};

    final result = <String, String>{};

    value.forEach((key, mapValue) {
      if (mapValue != null) {
        result[key.toString()] = mapValue.toString();
      }
    });

    return result;
  }
}

class SpeakingProgressRepository {
  SpeakingProgressRepository({
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
    return UserStorageKeyHelper.key('speaking_${_normalizeTopic(topic)}');
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
    return 'speaking_${_normalizeTopic(topic)}';
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

  Future<SpeakingProgressData?> loadProgress(String topic) async {
    final uid = _uid;

    if (uid == null) {
      return _loadLocalProgress(topic);
    }

    try {
      final doc = await _progressDoc(uid, topic).get();
      final data = doc.data();

      if (doc.exists && data != null) {
        final progress = SpeakingProgressData.fromJson(data);
        await _saveLocalProgress(topic: topic, data: progress);
        return progress;
      }
    } catch (error) {
      debugPrint('Không thể tải Speaking progress từ Firestore: $error');
    }

    return _loadLocalProgress(topic);
  }

  Future<SpeakingProgressData?> _loadLocalProgress(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(topic));

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return SpeakingProgressData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress({
    required String topic,
    required SpeakingProgressData data,
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
        'scoreByWordId': data.scoreByWordId,
        'initialScoreByWordId': data.initialScoreByWordId,
        'finalScoreByWordId': data.finalScoreByWordId,
        'toneScoreByWordId': data.toneScoreByWordId,
        'feedbackByWordId': data.feedbackByWordId,
        'recognizedTextByWordId': data.recognizedTextByWordId,
        'completedWordIds': data.completedWordIds.toList(),
        'lowScoreWordIds': data.lowScoreWordIds.toList(),
        'skippedWordIds': data.skippedWordIds.toList(),
        'isCompleted': data.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Không thể đồng bộ Speaking progress lên Firestore: $error');
    }
  }

  Future<void> _saveLocalProgress({
    required String topic,
    required SpeakingProgressData data,
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
      debugPrint('Không thể xóa Speaking progress trên Firestore: $error');
    }
  }

  Future<int> getCurrentPositionCount(String topic) async {
    final progress = await loadProgress(topic);

    if (progress == null) {
      return 0;
    }

    final hasStarted =
        progress.completedWordIds.isNotEmpty ||
        progress.lowScoreWordIds.isNotEmpty ||
        progress.skippedWordIds.isNotEmpty ||
        progress.scoreByWordId.isNotEmpty ||
        progress.currentIndex > 0 ||
        progress.isCompleted;

    if (!hasStarted) {
      return 0;
    }

    return progress.currentIndex + 1;
  }
}
