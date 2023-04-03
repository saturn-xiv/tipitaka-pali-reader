import 'dart:convert';
class DictionaryHistory {
  final String word;
  final DateTime dateTime;
  DictionaryHistory({
    required this.word,
    required this.dateTime,
  });


  DictionaryHistory copyWith({
    String? word,
    DateTime? dateTime,
  }) {
    return DictionaryHistory(
      word: word ?? this.word,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'date': dateTime.toIso8601String(),
    };
  }

  factory DictionaryHistory.fromMap(Map<String, dynamic> map) {
    return DictionaryHistory(
      word: map['word'] ?? '',
      dateTime: DateTime.parse(map['date'],),
    );
  }

  String toJson() => json.encode(toMap());

  factory DictionaryHistory.fromJson(String source) => DictionaryHistory.fromMap(json.decode(source));

  @override
  String toString() => word;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DictionaryHistory &&
      other.word == word &&
      other.dateTime == dateTime;
  }

  @override
  int get hashCode => word.hashCode ^ dateTime.hashCode;
}
