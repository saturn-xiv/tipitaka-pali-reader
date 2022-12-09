import 'dart:convert';

List<DictionaryHistory> dictionaryHistoryFromJson(String str) =>
    List<DictionaryHistory>.from(
        json.decode(str).map((x) => DictionaryHistory.fromJson(x)));

String dictionaryHistoryToJson(List<DictionaryHistory> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DictionaryHistory {
  String word;
  String context;
  String date;
  String bookID;
  int pageNumber;

  DictionaryHistory(
      {this.word = "",
      this.context = "",
      this.date = "",
      this.bookID = "",
      this.pageNumber = 0});

  factory DictionaryHistory.fromJson(Map<dynamic, dynamic> json) {
    return DictionaryHistory(
      word: json["word"] ?? "n/a",
      context: json["context"] ?? "n/a",
      date: json["date"] ?? "n/a",
      bookID: json["book_id"] ?? "n/a",
      pageNumber: json["page_number"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "word": word,
        "context": context,
        "date": date,
        "book_id": bookID,
        "page_number": pageNumber,
      };

  @override
  String toString() {
    return '$word: $date';
  }
}
