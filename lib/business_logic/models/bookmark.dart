import 'dart:convert';

List<Bookmark> definitionFromJson(String str) =>
    List<Bookmark>.from(json.decode(str).map((x) => Bookmark.fromJson(x)));

String definitionToJson(List<Bookmark> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

enum BookmarkAction {
  insert,
  delete,
  // Add more actions if needed
}

class Bookmark {
  final String id;
  final String bookID;
  final int pageNumber;
  final String note;
  String name;
  String selectedText;

  Bookmark({
    this.id = "n/a",
    this.bookID = "n/a",
    this.pageNumber = 0,
    this.note = "n/a",
    this.name = 'Unknown', // Setting default value for bookName
    this.selectedText = '',
  });

  @override
  String toString() {
    return '''bookID: $bookID
              name: $name
              pageNumber: $pageNumber
              note: $note
              selected_text: $selectedText
    ''';
    //removed bookname for now.
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book_id': bookID,
        'page_number': pageNumber,
        'note': note,
        'name': name,
        'selected_text': selectedText,
      };

  factory Bookmark.fromJson(Map<dynamic, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? 'n/a', // id is the primary key
      bookID: json['book_id'],
      pageNumber: json['page_number'],
      note: json['note'],
      name: json['name'] ?? 'Unknown',
      selectedText: json['selected_text'] ?? '',
    );
  }
}
