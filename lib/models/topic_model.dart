class TopicModel {
  const TopicModel({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.totalCount,
    required this.learnedCount,
  });

  final String key;
  final String title;
  final String subtitle;
  final int totalCount;
  final int learnedCount;

  double get progressValue {
    if (totalCount <= 0) return 0;
    return learnedCount / totalCount;
  }

  String get progressText => '$learnedCount/$totalCount';

  TopicModel copyWith({
    String? key,
    String? title,
    String? subtitle,
    int? totalCount,
    int? learnedCount,
  }) {
    return TopicModel(
      key: key ?? this.key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      totalCount: totalCount ?? this.totalCount,
      learnedCount: learnedCount ?? this.learnedCount,
    );
  }
}
