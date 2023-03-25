class SearchSuggestion {
  String word;
  int count;
  String? plain;

  SearchSuggestion(this.word, this.count, {this.plain});

  factory SearchSuggestion.fromCached(String word) {
    final split = word.split("|");
    return SearchSuggestion(split[1], int.parse(split[2]), plain: split[0]);
  }
}
