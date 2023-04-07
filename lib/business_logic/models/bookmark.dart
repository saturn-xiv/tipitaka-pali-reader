class Bookmark {
  final String bookID;
  final int pageNumber;
  final String note;
  final String bookName;

  Bookmark(this.bookID, this.pageNumber, this.note, [String? bookName])
      : bookName = bookName ?? 'Unknown';

  @override
  String toString() {
    return '''bookID: $bookID
              bookName: $bookName
              pageNumber: $pageNumber
              note: $note
    ''';
  }
}
