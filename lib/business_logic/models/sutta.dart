class Sutta {
  final String name;
  final String bookID;
  final String bookName;
  final int pageNumber;
  Sutta({
    required this.name,
    required this.bookID,
    required this.bookName,
    required this.pageNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bookID': bookID,
      'bookName': bookName,
      'pageNumber': pageNumber,
    };
  }

  factory Sutta.fromMap(Map<String, dynamic> map) {
    return Sutta(
      name: map['name'] ?? '',
      bookID: map['book_id'] ?? '',
      bookName: map['book_name'] ?? '',
      pageNumber: map['page_number']?.toInt() ?? 0,
    );
  }

  @override
  String toString() =>
      'Sutta(name: $name, bookID: $bookID, pageNumber: $pageNumber)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Sutta &&
        other.name == name &&
        other.bookID == bookID &&
        other.bookName == bookName &&
        other.pageNumber == pageNumber;
  }

  @override
  int get hashCode =>
      name.hashCode ^ bookID.hashCode ^ bookName.hashCode ^ pageNumber.hashCode;
}
