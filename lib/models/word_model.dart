// Model chuẩn cho một từ vựng HSK đọc từ JSON và dùng xuyên suốt app.
class WordModel {
  const WordModel({
    required this.id,
    required this.level,
    required this.hanzi,
    required this.pinyin,
    required this.meaningVi,
    required this.exampleZh,
    required this.examplePinyin,
    required this.exampleVi,
    required this.category,
    required this.topic,
  });

  final String id;
  final int level;
  final String hanzi;
  final String pinyin;
  final String meaningVi;
  final String exampleZh;
  final String examplePinyin;
  final String exampleVi;
  final String category;
  final String topic;

  factory WordModel.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final value = json[key];
      if (value == null) return fallback;
      return value.toString();
    }

    return WordModel(
      id: readString('id'),
      level: int.tryParse(readString('level', fallback: '1')) ?? 1,
      hanzi: readString('hanzi'),
      pinyin: readString('pinyin'),
      meaningVi: readString('meaning_vi', fallback: 'Chưa có nghĩa'),
      exampleZh: readString('example_zh', fallback: 'Chưa có ví dụ'),
      examplePinyin: readString('example_pinyin', fallback: 'Chưa có pinyin'),
      exampleVi: readString('example_vi', fallback: 'Chưa có bản dịch'),
      category: readString('category', fallback: 'Từ vựng'),
      topic: readString('topic', fallback: 'Khác'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'hanzi': hanzi,
      'pinyin': pinyin,
      'meaning_vi': meaningVi,
      'example_zh': exampleZh,
      'example_pinyin': examplePinyin,
      'example_vi': exampleVi,
      'category': category,
      'topic': topic,
    };
  }
}
