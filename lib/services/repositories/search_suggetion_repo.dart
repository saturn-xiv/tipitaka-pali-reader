import 'package:tipitaka_pali/business_logic/models/search_suggestion.dart';
import 'package:tipitaka_pali/services/dao/search_suggestion_dao.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';

abstract class SearchSuggestionRepository {
  Future<List<SearchSuggestion>> getSuggestions(String filterWord);
}

const maxResults = 100;

final variations = {
  'a': RegExp(r'ā'),
  'u': RegExp(r'ū'),
  't': RegExp(r'ṭ'),
  'n': RegExp(r'[ñṇṅ]'),
  'i': RegExp(r'ī'),
  'd': RegExp(r'ḍ'),
  'l': RegExp(r'ḷ'),
  'm': RegExp(r'ṁṃ')
};

class SearchSuggestionDatabaseRepository implements SearchSuggestionRepository {
  static List<String> _words = [];
  static Future<void>? _wordsFuture;

  final dao = SearchSuggestionDao();
  final DatabaseHelper databaseProvider;

  SearchSuggestionDatabaseRepository(this.databaseProvider);

  Future<List<SearchSuggestion>> _getSuggestionsFromDB(String filterWord) async {
    final db = await databaseProvider.database;
    List<Map<String, dynamic>> maps = await db.query(dao.tableWords,
        columns: [dao.columnWord, dao.columnFrequecny],
        where: "${dao.columnWord} LIKE '$filterWord%'");
    return dao.fromList(maps);
  }

  Future<List<SearchSuggestion>> _getSuggestionsFromMemory(String filterWord) async {
    final words = await _getAllWords();
    final searchWord = filterWord.toLowerCase().trim();
    final other = _toPlain(searchWord);

    final List<SearchSuggestion> results = [];
    for (final word in words) {
      if (word.startsWith(other)) {
        results.add(SearchSuggestion.fromCached(word));
      }
      if (results.length >= maxResults) {
        break;
      }
    }

    results.sort((a, b) {
      if (a.word == searchWord) {
        return -1;
      }
      if (b.word == searchWord) {
        return 1;
      }
      if (a.word.length == b.word.length) {
        return a.word.compareTo(b.word);
      }
      return a.word.length - b.word.length;
    });

    return results;
  }

  @override
  Future<List<SearchSuggestion>> getSuggestions(String filterWord) async {
    return _getSuggestionsFromMemory(filterWord);
  }

  String _toPlain(String word) {
    var plain = word.toLowerCase().trim();
    variations.forEach((key, value) {
      plain = plain.replaceAll(value, key);
    });
    return plain;
  }

  Future<void> _getAllWordsFuture() async {
    final db = await databaseProvider.database;
    final List<Map<String, dynamic>> maps = await db
        .query(dao.tableWords, columns: [dao.columnWord, dao.columnFrequecny]);
    _words = maps
        .map((e) => "${_toPlain(e['word'])}|${e['word']}|${e['frequency']}")
        .toList()
      ..sort((a, b) => a.length - b.length);
  }

  Future<List<String>> _getAllWords() async {
    _wordsFuture ??= _getAllWordsFuture();
    await _wordsFuture;
    return _words;
  }
}
