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
  BookmarkAction action;
  String actionDate;
  String syncDate;
  int synced;

  // Constructor with named parameters
  Bookmark({
    this.id = "n/a",
    this.bookID = "n/a",
    this.pageNumber = 0,
    this.note = "n/a",
    this.name = 'Unknown', // Setting default value for bookName
    this.action = BookmarkAction.insert,
    this.actionDate = 'n/a',
    this.syncDate = 'n/a',
    this.synced = 0,
  });

  @override
  String toString() {
    return '''bookID: $bookID
              name: $name
              pageNumber: $pageNumber
              note: $note
    ''';
    //removed bookname for now.
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book_id': bookID,
        'page_number': pageNumber,
        'note': note,
        'name': name,
        'action': action.toString().split('.').last,
        'action_date': actionDate,
        'sync_date': syncDate,
        'synced': synced,
      };

  factory Bookmark.fromJson(Map<dynamic, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? 'n/a', // id is the primary key
      bookID: json['book_id'],
      pageNumber: json['page_number'],
      note: json['note'],
      name: json['name'] ?? 'Unknown',
      action: BookmarkAction.values.firstWhere(
          (e) => e.toString().split('.').last == json['action'],
          orElse: () => BookmarkAction.insert),
      actionDate: json['action_date'] ?? 'Unknown',
      syncDate: json['sync_date'] ?? 'Unknown',
      synced: json['synced'] ?? 1,
    );
  }
}
