import '../../business_logic/models/definition.dart';
import '../../utils/pali_stemmer.dart';
import '../repositories/dictionary_repo.dart';

const kdartTheme = 'default_dark_theme';
const kblackTheme = 'black';

class DictionarySerice {
  DictionarySerice(this.dictionaryRepository);
  final DictionaryRepository dictionaryRepository;

  Future<Definition> getDpdDefinition(String headword) async {
    final definitions = await dictionaryRepository.getDpdDefinition(headword);
    return definitions;
  }

  Future<Definition> getDpdGrammarDefinition(String word) async {
    final definition = await dictionaryRepository.getDpdGrammarDefinition(word);
    return definition;
  }

  Future<List<Definition>> getDefinition(String word,
      {bool isAlreadyStem = false}) async {
    if (!isAlreadyStem) {
      word = PaliStemmer.getStem(word);
    }

    // final DatabaseHelper databaseHelper = DatabaseHelper();
    // final DictionaryRepository dictRepository =
    //     DictionaryDatabaseRepository(databaseHelper);

    // lookup using estimated stem word
    // print('dict word: $stemWord');
    final definitions = await dictionaryRepository.getDefinition(word);
    return definitions;

    // return _formatDefinitions(definitions);
  }

  Future<List<String>> getSuggestions(String word) async {
    return dictionaryRepository.getSuggestions(word);
  }

  Future<String> getDpdWordSplit(String word) async {
    return dictionaryRepository.getDpdWordSplit(word);
  }

  Future<String> getDprStem(String word) async {
    return dictionaryRepository.getDprStem(word);
  }

  Future<String> getDpdHeadwords(String word) async {
    return dictionaryRepository.getDpdHeadwords(word);
  }

  Future<String> getDpdLikeHeadwords(String word) async {
    return dictionaryRepository.getDpdLikeHeadwords(word);
  }
}
