import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

final learningActivityRepositoryProvider = Provider<LearningActivityRepository>(
  (ref) {
    return LearningActivityRepository(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
  },
);

class LearningActivityRepository {
  LearningActivityRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _learningDaysKey = 'learning_days';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  String? get _uid {
    final uid = _firebaseAuth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return null;
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _activityDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('learning_activity');
  }

  Future<void> markStudiedToday() async {
    final today = _dateKey(DateTime.now());
    final days = await _loadSyncedLearningDays();
    final updatedDays = {...days, today}.toList()..sort();

    await _saveLocalLearningDays(updatedDays);
    await _syncLearningActivity(updatedDays);
  }

  Future<Set<int>> getWeeklyStudyDays() async {
    final days = (await _loadSyncedLearningDays()).toSet();
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final studiedWeekdays = <int>{};

    for (var offset = 0; offset < 7; offset++) {
      final date = monday.add(Duration(days: offset));
      if (days.contains(_dateKey(date))) {
        studiedWeekdays.add(date.weekday);
      }
    }

    return studiedWeekdays;
  }

  Future<int> getCurrentStreak() async {
    final days = (await _loadSyncedLearningDays()).toSet();
    return _calculateCurrentStreak(days);
  }

  Future<bool> shouldShowReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final days = (await _loadSyncedLearningDays()).toSet();
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayKey = _dateKey(today);

    if (days.contains(todayKey) || days.contains(_dateKey(yesterday))) {
      return false;
    }

    return prefs.getBool(_key('streak_reminder_shown_$todayKey')) != true;
  }

  Future<void> markReminderShown() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    await prefs.setBool(_key('streak_reminder_shown_$todayKey'), true);
  }

  Future<List<String>> _loadSyncedLearningDays() async {
    final uid = _uid;

    if (uid == null) {
      return _loadLocalLearningDays();
    }

    try {
      final doc = await _activityDoc(uid).get();
      final data = doc.data();

      if (doc.exists && data != null) {
        final days = _readStringList(data['learningDays'])..sort();
        await _saveLocalLearningDays(days);
        return days;
      }
    } catch (error) {
      debugPrint('Không thể tải learning activity từ Firestore: $error');
    }

    return _loadLocalLearningDays();
  }

  Future<List<String>> _loadLocalLearningDays() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getStringList(_key(_learningDaysKey)) ?? <String>[];
    return days.toSet().toList()..sort();
  }

  Future<void> _saveLocalLearningDays(List<String> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(_learningDaysKey), days.toSet().toList());
  }

  Future<void> _syncLearningActivity(List<String> days) async {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    try {
      final sortedDays = days.toSet().toList()..sort();
      final currentStreak = _calculateCurrentStreak(sortedDays.toSet());
      final lastStudiedDate = sortedDays.isEmpty ? null : sortedDays.last;

      await _activityDoc(uid).set({
        'learningDays': sortedDays,
        'currentStreak': currentStreak,
        'lastStudiedDate': lastStudiedDate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Không thể đồng bộ learning activity lên Firestore: $error');
    }
  }

  int _calculateCurrentStreak(Set<String> days) {
    final today = DateTime.now();

    DateTime cursor;
    if (days.contains(_dateKey(today))) {
      cursor = today;
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      if (!days.contains(_dateKey(yesterday))) return 0;
      cursor = yesterday;
    }

    var streak = 0;
    while (days.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  String _key(String name) {
    return UserStorageKeyHelper.key(name);
  }

  String _dateKey(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
