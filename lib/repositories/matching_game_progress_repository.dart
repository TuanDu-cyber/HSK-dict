import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

final matchingGameProgressRepositoryProvider =
    Provider<MatchingGameProgressRepository>((ref) {
      return MatchingGameProgressRepository(
        firebaseAuth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
    });

class MatchingGameStats {
  const MatchingGameStats({
    required this.totalRounds,
    required this.totalWins,
    required this.totalCorrectPairs,
    required this.bestTimeByTopic,
    this.lastTopic,
  });

  final int totalRounds;
  final int totalWins;
  final int totalCorrectPairs;
  final Map<String, int> bestTimeByTopic;
  final String? lastTopic;

  MatchingGameStats copyWith({
    int? totalRounds,
    int? totalWins,
    int? totalCorrectPairs,
    Map<String, int>? bestTimeByTopic,
    String? lastTopic,
  }) {
    return MatchingGameStats(
      totalRounds: totalRounds ?? this.totalRounds,
      totalWins: totalWins ?? this.totalWins,
      totalCorrectPairs: totalCorrectPairs ?? this.totalCorrectPairs,
      bestTimeByTopic: bestTimeByTopic ?? this.bestTimeByTopic,
      lastTopic: lastTopic ?? this.lastTopic,
    );
  }
}

class MatchingGameProgressRepository {
  MatchingGameProgressRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _totalRoundsSuffix = 'matching_total_rounds';
  static const String _totalWinsSuffix = 'matching_total_wins';
  static const String _totalCorrectPairsSuffix = 'matching_total_correct_pairs';
  static const String _lastTopicSuffix = 'matching_last_topic';
  static const String _bestTimeTopicsSuffix = 'matching_best_time_topics';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  String get _totalRoundsKey => UserStorageKeyHelper.key(_totalRoundsSuffix);
  String get _totalWinsKey => UserStorageKeyHelper.key(_totalWinsSuffix);
  String get _totalCorrectPairsKey =>
      UserStorageKeyHelper.key(_totalCorrectPairsSuffix);
  String get _lastTopicKey => UserStorageKeyHelper.key(_lastTopicSuffix);
  String get _bestTimeTopicsKey =>
      UserStorageKeyHelper.key(_bestTimeTopicsSuffix);

  String? get _uid {
    final uid = _firebaseAuth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return null;
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _gameStatsDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('game');
  }

  String _bestTimeKey(String topic) {
    return UserStorageKeyHelper.key(
      'matching_best_time_${_normalizeTopic(topic)}',
    );
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

  Future<void> saveRoundStarted({required String? topic}) async {
    final stats = await _loadSyncedStats();
    final nextStats = stats.copyWith(
      totalRounds: stats.totalRounds + 1,
      lastTopic: _cleanTopic(topic) ?? stats.lastTopic,
    );

    await _saveLocalStats(nextStats);
    await _syncStats(nextStats);
  }

  Future<void> saveRoundWon({
    required String? topic,
    required int elapsedSeconds,
    required int correctPairs,
  }) async {
    final stats = await _loadSyncedStats();
    final bestTimeByTopic = {...stats.bestTimeByTopic};
    final cleanTopic = _cleanTopic(topic);

    if (cleanTopic != null) {
      final oldBest = bestTimeByTopic[cleanTopic];

      if (oldBest == null || elapsedSeconds < oldBest) {
        bestTimeByTopic[cleanTopic] = elapsedSeconds;
      }
    }

    final nextStats = stats.copyWith(
      totalWins: stats.totalWins + 1,
      totalCorrectPairs: stats.totalCorrectPairs + correctPairs,
      bestTimeByTopic: bestTimeByTopic,
      lastTopic: cleanTopic ?? stats.lastTopic,
    );

    await _saveLocalStats(nextStats);
    await _syncStats(nextStats);
  }

  Future<String?> getLastTopic() async {
    final stats = await _loadSyncedStats();
    return stats.lastTopic;
  }

  Future<MatchingGameStats> _loadSyncedStats() async {
    final uid = _uid;

    if (uid == null) {
      return _loadLocalStats();
    }

    try {
      final doc = await _gameStatsDoc(uid).get();
      final data = doc.data();

      if (doc.exists && data != null) {
        final stats = MatchingGameStats(
          totalRounds: _readInt(data['playedCount'] ?? data['totalRounds']),
          totalWins: _readInt(data['completedCount'] ?? data['totalWins']),
          totalCorrectPairs: _readInt(data['totalCorrectPairs']),
          bestTimeByTopic: _readIntMap(data['bestTimeByTopic']),
          lastTopic: data['lastTopic']?.toString(),
        );
        await _saveLocalStats(stats);
        return stats;
      }
    } catch (error) {
      debugPrint('Không thể tải Game stats từ Firestore: $error');
    }

    return _loadLocalStats();
  }

  Future<MatchingGameStats> _loadLocalStats() async {
    final prefs = await SharedPreferences.getInstance();
    final topics = prefs.getStringList(_bestTimeTopicsKey) ?? const [];
    final bestTimeByTopic = <String, int>{};

    for (final topic in topics) {
      final bestTime = prefs.getInt(_bestTimeKey(topic));
      if (bestTime != null) {
        bestTimeByTopic[topic] = bestTime;
      }
    }

    return MatchingGameStats(
      totalRounds: prefs.getInt(_totalRoundsKey) ?? 0,
      totalWins: prefs.getInt(_totalWinsKey) ?? 0,
      totalCorrectPairs: prefs.getInt(_totalCorrectPairsKey) ?? 0,
      bestTimeByTopic: bestTimeByTopic,
      lastTopic: prefs.getString(_lastTopicKey),
    );
  }

  Future<void> _saveLocalStats(MatchingGameStats stats) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_totalRoundsKey, stats.totalRounds);
    await prefs.setInt(_totalWinsKey, stats.totalWins);
    await prefs.setInt(_totalCorrectPairsKey, stats.totalCorrectPairs);
    await prefs.setStringList(
      _bestTimeTopicsKey,
      stats.bestTimeByTopic.keys.toList(),
    );

    if (stats.lastTopic != null && stats.lastTopic!.trim().isNotEmpty) {
      await prefs.setString(_lastTopicKey, stats.lastTopic!);
    }

    for (final entry in stats.bestTimeByTopic.entries) {
      await prefs.setInt(_bestTimeKey(entry.key), entry.value);
    }
  }

  Future<void> _syncStats(MatchingGameStats stats) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      final bestScore = stats.bestTimeByTopic.values.isEmpty
          ? null
          : stats.bestTimeByTopic.values.reduce((a, b) => a < b ? a : b);

      await _gameStatsDoc(uid).set({
        'playedCount': stats.totalRounds,
        'completedCount': stats.totalWins,
        'totalCorrectPairs': stats.totalCorrectPairs,
        'bestScore': bestScore,
        'bestTimeByTopic': stats.bestTimeByTopic,
        'lastTopic': stats.lastTopic,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Không thể đồng bộ Game stats lên Firestore: $error');
    }
  }

  String? _cleanTopic(String? topic) {
    final cleanTopic = topic?.trim();
    if (cleanTopic == null || cleanTopic.isEmpty) return null;
    return cleanTopic;
  }

  int _readInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, int> _readIntMap(dynamic value) {
    if (value is! Map) return {};

    final result = <String, int>{};
    value.forEach((key, mapValue) {
      result[key.toString()] = _readInt(mapValue);
    });
    return result;
  }
}
