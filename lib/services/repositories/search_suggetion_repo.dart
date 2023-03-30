import 'package:tipitaka_pali/business_logic/models/search_suggestion.dart';
//import 'package:tipitaka_pali/services/dao/search_suggestion_dao.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';

abstract class SearchSuggestionRepository {
  Future<List<SearchSuggestion>> getSuggestions(
      String filterWord, bool isFuzzy);
}

const maxResults = 100;

// not used but keep around
final variations = {
  'a': RegExp(r'ā'),
  'u': RegExp(r'ū'),
  't': RegExp(r'ṭ'),
  'n': RegExp(r'[ñṇṅ]'),
  'i': RegExp(r'ī'),
  'd': RegExp(r'ḍ'),
  'l': RegExp(r'ḷ'),
  'm': RegExp(r'[ṁṃ]')
};

class SearchSuggestionDatabaseRepository implements SearchSuggestionRepository {
  static List<String> _words = [];
  static Future<void>? _wordsFuture;

  //final dao = SearchSuggestionDao();
  final DatabaseHelper databaseProvider;

  SearchSuggestionDatabaseRepository(this.databaseProvider);

  Future<List<SearchSuggestion>> _getSuggestionsFromDB(
      String filterWord, isFuzzy) async {
    final db = await databaseProvider.database;
    String searchField = (isFuzzy) ? "plain" : "word";
    String sql =
        "SELECT word, plain, frequency FROM words WHERE $searchField LIKE '$filterWord%' ORDER BY LENGTH(word), word ASC LIMIT 100;";

    List<Map<String, dynamic>> maps = await db.rawQuery(sql);
    List<SearchSuggestion> words =
        maps.map((x) => SearchSuggestion.fromJson(x)).toList();

    // fine tune the sort
    words.sort((a, b) {
      if (a.word == filterWord) {
        return -1;
      }
      if (b.word == filterWord) {
        return 1;
      }
      if (a.word.length == b.word.length) {
        return a.word.compareTo(b.word);
      }
      return a.word.length - b.word.length;
    });

    return words;
  }

  @override
  Future<List<SearchSuggestion>> getSuggestions(
      String filterWord, bool isFuzzy) async {
    return _getSuggestionsFromDB(filterWord, isFuzzy);
  }

// function not used but we will keep around
  String _toPlain(String word) {
    var plain = word.toLowerCase().trim();
    variations.forEach((key, value) {
      plain = plain.replaceAll(value, key);
    });
    return plain;
  }
}
