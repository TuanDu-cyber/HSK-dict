import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.streak = 0,
    this.onlineMinutesToday = 0,
    this.lastActiveDate,
  });

  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int streak;
  final int onlineMinutesToday;
  final String? lastActiveDate;

  factory AppUserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return AppUserModel(
      uid: data['uid']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Learner',
      email: data['email']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString(),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
      streak: int.tryParse(data['streak']?.toString() ?? '') ?? 0,
      onlineMinutesToday:
          int.tryParse(data['onlineMinutesToday']?.toString() ?? '') ?? 0,
      lastActiveDate: data['lastActiveDate']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
      'streak': streak,
      'onlineMinutesToday': onlineMinutesToday,
      'lastActiveDate': lastActiveDate,
    };
  }

  Map<String, dynamic> toUpdateFirestore() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'streak': streak,
      'onlineMinutesToday': onlineMinutesToday,
      'lastActiveDate': lastActiveDate,
    };
  }

  AppUserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? streak,
    int? onlineMinutesToday,
    String? lastActiveDate,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      streak: streak ?? this.streak,
      onlineMinutesToday: onlineMinutesToday ?? this.onlineMinutesToday,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
