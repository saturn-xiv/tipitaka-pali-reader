// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../business_logic/models/definition.dart';
import '../../../../business_logic/models/dictionary_history.dart';
import '../../../../services/database/database_helper.dart';
import '../../../../services/database/dictionary_service.dart';
import '../../../../services/repositories/dictionary_history_repo.dart';
import '../../../../services/repositories/dictionary_repo.dart';
import 'dictionary_state.dart';
import 'package:flutter/services.dart';
import 'package:tipitaka_pali/services/prefs.dart';

// global variable
final ValueNotifier<String?> globalLookupWord = ValueNotifier<String?>(null);

enum DictAlgorithm { Auto, TPR, DPR }

extension ParseToString on DictAlgorithm {
  String toStr() {
    return toString().split('.').last;
  }
}

class DictionaryController with ChangeNotifier {
  final DictionaryHistoryRepository dictionaryHistoryRepository;
  final DictionaryRepository dictionaryRepository;

  String _currentlookupWord = '';
  String get lookupWord => _currentlookupWord;
  BuildContext context;

  DictionaryState _dictionaryState = const DictionaryState.initial();
  DictionaryState get dictionaryState => _dictionaryState;

  DictAlgorithm _currentAlgorithmMode = DictAlgorithm.Auto;
  DictAlgorithm get currentAlgorithmMode => _currentAlgorithmMode;

  // TextEditingController textEditingController = TextEditingController();

  final ValueNotifier<List<DictionaryHistory>> _histories =
      ValueNotifier<List<DictionaryHistory>>([]);
  ValueListenable<List<DictionaryHistory>> get histories => _histories;

  DictionaryController({
    required this.context,
    required this.dictionaryHistoryRepository,
    required this.dictionaryRepository,
    String? lookupWord,
  }) : _currentlookupWord = lookupWord ?? '';

  void onLoad() {
    debugPrint('init dictionary controller');
    globalLookupWord.addListener(_lookupWordListener);

    // load history
    dictionaryHistoryRepository.getAll().then((values) {
      values.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _histories.value = [...values];
    });

    if (_currentlookupWord.isNotEmpty) {
      _lookupDefinition();
    }
  }

  @override
  void dispose() {
    debugPrint('dictionary Controller is disposed');
    globalLookupWord.removeListener(_lookupWordListener);
    super.dispose();
  }

  void _lookupWordListener() {
    if (globalLookupWord.value != null) {
      _currentlookupWord = globalLookupWord.value ?? '';
      debugPrint('lookup word: $_currentlookupWord');
      _lookupDefinition();
    }
  }

  Future<void> _lookupDefinition() async {
    _dictionaryState = const DictionaryState.loading();
    notifyListeners();
    if (_currentlookupWord.isEmpty) {
      return;
    }
    // loading definitions
    final definition = await loadDefinition(_currentlookupWord!);
    debugPrint(
        '==================> $_currentlookupWord, is empty: ${definition.isEmpty}');
    if (definition.isEmpty) {
      _dictionaryState = const DictionaryState.noData();
      notifyListeners();
    } else {
      _dictionaryState = DictionaryState.data(definition);
      notifyListeners();
      // save to history
      if (!isContainInHistories(_histories.value, _currentlookupWord)) {
        await dictionaryHistoryRepository.insert(_currentlookupWord);
        // refresh histories
        final histories = await dictionaryHistoryRepository.getAll();
        histories.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _histories.value = [...histories];
      }
    }
  }

  Future<String> loadDefinition(String word) async {
    // use only if setting is good in prefs
    if (Prefs.saveClickToClipboard == true) {
      // await Clipboard.setData(ClipboardData(text: word));
    }
    debugPrint('_currentAlgorithmMode: ${_currentAlgorithmMode}');

    switch (_currentAlgorithmMode) {
      case DictAlgorithm.Auto:
        return await searchAuto(word);
      case DictAlgorithm.TPR:
        return searchWithTPR(word);
      case DictAlgorithm.DPR:
        return searchWithDPR(word);
    }
  }

  Future<String> searchAuto(String word) async {
    //
    // Audo mode will use TPR algorithm first
    // if defintion was found, will be display this definition
    // Otherwise will be display result of DPR a

    final before = DateTime.now();

    String definition = await searchWithTPR(word);
    debugPrint(
        'TPR definition "$definition", definition.isEmpty: ${definition.isEmpty}');
    if (definition.isEmpty) definition = await searchWithDPR(word);
    debugPrint('DPR def: $definition');
    final after = DateTime.now();
    final differnt = after.difference(before);
    debugPrint('compute time: $differnt');

    final dp = DictionaryDatabaseRepository(DatabaseHelper());
    // final dh = DictionaryHistory(word: word);
    //await dp.insertOrReplace(dh);
    // Todo removed for release.  fix later.

    return definition;
  }

  Future<String> searchWithTPR(String word) async {
    final originalWord = word;
    // looking up using estimated stem word
    final dictionaryProvider =
        DictionarySerice(DictionaryDatabaseRepository(DatabaseHelper()));
    // now get the headword all times.
    final String dpdHeadWords = await dictionaryProvider.getDpdHeadwords(word);
    // if we find the word.. then we isAlreadyStem = true;
    // make the lookup word that new dpdHeadWord.

    bool isAlreadyStem = false;
    if (dpdHeadWords.isNotEmpty) {
      // TODO get list from ven Bodhirasa for exceptions Bhagavaa and bhikkhave etc.

      List<String> dpdList = dpdHeadWords.split(RegExp(r"[, ]"));
      // remove the left bracket and single quotes
      String dpdword = dpdList[0].replaceAll(RegExp(r"[\'\[\]]"), "");

//small case switch.. little hack.
      switch (dpdword) {
        case "āyasmant":
          word = "āyasmantu";
          break;
        case "bhikkhave":
          word = "bhikkhu";
          break;
        case "ambho":
          isAlreadyStem = true;
          break;
        default:
          if (word.contains("āyasm")) {
            dpdword = "āyasmantu";
          }

          // total hack for ending in vant change to vantu
          // works in most cases.
          if (dpdword.length > 4) {
            if (dpdword.substring(dpdword.length - 4, dpdword.length) ==
                "vant") {
              dpdword = "${dpdword.substring(0, dpdword.length - 4)}vantu";
            }
          }

          word = dpdword;
          break;
      }
    }

    final definitions = await dictionaryProvider.getDefinition(word,
        isAlreadyStem: isAlreadyStem);

    // check to see if dpd is used.
    // separate table and process for dpd
    if (Prefs.isDpdOn) {
      if (dpdHeadWords.isNotEmpty) {
        Definition dpdDefinition =
            await dictionaryProvider.getDpdDefinition(dpdHeadWords);
        if (Prefs.isDpdGrammarOn) {
          Definition grammarDef =
              await dictionaryProvider.getDpdGrammarDefinition(originalWord);
          if (grammarDef.word.isNotEmpty) {
            dpdDefinition.definition += grammarDef.definition;
          }
        }
        definitions.insert(0, dpdDefinition);
        definitions.sort((a, b) => a.userOrder.compareTo(b.userOrder));
      }
      // alternative way.
/*      Definition grammarDef =
          await dictionaryProvider.getDpdGrammarDefinition(word);
      if (!grammarDef.word.isEmpty) {
        definitions.add(grammarDef);
      }
      */
    }
    if (definitions.isEmpty) return '';

    return _formatDefinitions(definitions);
  }

  Future<String> searchWithDPR(String word) async {
    // looking up using dpr breakup words
    List<Definition> definitions = [];
    final dictionaryProvider =
        DictionarySerice(DictionaryDatabaseRepository(DatabaseHelper()));
    // frist dpr_stem will be used for stem
    // stem is single word mostly
    final String dprStem = await dictionaryProvider.getDprStem(word);
    if (dprStem.isNotEmpty) {
      definitions =
          await dictionaryProvider.getDefinition(dprStem, isAlreadyStem: true);
    }

    debugPrint('dprStem: $dprStem');
    debugPrint('Prefs.isDpdOn: ${Prefs.isDpdOn}');
    debugPrint('definitions: $definitions');

    if (Prefs.isDpdOn) {
      final String dpdHeadWord = await dictionaryProvider.getDpdHeadwords(word);
      debugPrint('dpdHeadWord: $dpdHeadWord for "$word"');
      if (dpdHeadWord.isNotEmpty) {
        Definition dpdDefinition =
            await dictionaryProvider.getDpdDefinition(dpdHeadWord);
        definitions.insert(0, dpdDefinition);
      }

      if (definitions.isNotEmpty) {
        definitions.sort((a, b) => a.userOrder.compareTo(b.userOrder));
        return _formatDefinitions(definitions);
      }
    }

    // not found in dpr_stem
    // will be lookup in dpr_breakup
    // breakup is multi-words
    final String breakupText = await dictionaryProvider.getDprBreakup(word);

    if (breakupText.isEmpty) return '';

    final List<String> words = getWordsFrom(breakup: breakupText);
    // formating header
    String formatedDefintion = '<b>$word</b> - ';
    String firstPartOfBreakupText =
        breakupText.substring(0, breakupText.indexOf(' '));
    firstPartOfBreakupText = firstPartOfBreakupText.replaceAll("-", " · ");
    // final cssColor = Theme.of(context).primaryColor.toCssString();
    String cssColor =
        "#${Theme.of(context).primaryColor.value.toRadixString(16).substring(2)}";
    String csspreFormat =
        '<p style="color:$cssColor; font-size:90%; font-weight=bold">';
    String lastPartOfBreakupText = words.map((word) => word).join(' + ');
    formatedDefintion +=
        '$csspreFormat $firstPartOfBreakupText [ $lastPartOfBreakupText ] </p>';
    // getting definition per word
    for (var word in words) {
      final definitions =
          await dictionaryProvider.getDefinition(word, isAlreadyStem: true);
      // print(definitions);
      if (definitions.isNotEmpty) {
        formatedDefintion += _formatDefinitions(definitions);
      }
    }
    debugPrint(formatedDefintion);
    return formatedDefintion;
  }

  Future<void> onLookup(String word) async {
    _currentlookupWord = word;
    _lookupDefinition();
  }

  void onInputIsEmpty() {
    _currentlookupWord = '';
    _dictionaryState = const DictionaryState.initial();
    notifyListeners();
  }

  Future<List<String>> getSuggestions(String word) async {
    return DictionarySerice(DictionaryDatabaseRepository(DatabaseHelper()))
        .getSuggestions(word);
  }

  String _formatDefinitions(List<Definition> definitions) {
    String formattedDefinition = '';
    for (Definition definition in definitions) {
      formattedDefinition += _addStyleToBook(definition.bookName);
      formattedDefinition += definition.definition;
    }
    return formattedDefinition;
  }

  String _addStyleToBook(String book) {
    // made variables for easy reading.. otherwise long
    String bkColor =
        Theme.of(context).primaryColor.value.toRadixString(16).substring(2);
    String foreColor =
        Theme.of(context).canvasColor.value.toRadixString(16).substring(2);

    return '<h3 style="background-color: #$bkColor; color: #$foreColor; text-align:center;  padding-bottom:5px; padding-top: 5px;">$book</h3>\n<br>\n';
  }

  List<String> getWordsFrom({required String breakup}) {
    // the dprBreakup data look like this:
    // 'bhikkhu':'bhikkhu (bhikkhu)',
    //
    // or this:
    // 'āyasmā':'āyasmā (āya, āyasmant, āyasmanta)',
    //
    // or this:
    // 'asaṃkiliṭṭhaasaṃkilesiko':'asaṃ-kiliṭṭhā-saṃkilesiko (asa, asā, kiliṭṭha, saṃkilesiko)',
    //
    // - The key of the dprBreakup object is the word being look up here (the "key" parameter of this function)
    // - The format of the break up is as follows:
    //   - the original word broken up with dashes (-) and the components of the breakup as dictionary entries in ()
    //
    final indexOfLeftBracket = breakup.indexOf(' (');
    final indexOfRightBracket = breakup.indexOf(')');
    var breakupWords = breakup
        .substring(indexOfLeftBracket + 2, indexOfRightBracket)
        .split(', ');
    // cleans up DPR-specific stuff
    breakupWords =
        breakupWords.map((word) => word.replaceAll('`', '')).toList();
    return breakupWords;
  }

  void onModeChanged(DictAlgorithm? value) {
    if (value != null) {
      _currentAlgorithmMode = value;
      _lookupDefinition();
    }
  }

  void onWordClicked(String word) async {
    word = _romoveNonCharacter(word);

    word = word.toLowerCase();
    _currentlookupWord = word;

    _lookupDefinition();
  }

  void onClickedNext() {
    if (_histories.value.isEmpty) {
      return;
    }
    final index = _getIndex(_histories.value, _currentlookupWord);
    if (index == -1) {
      return;
    }

    if (index + 1 < _histories.value.length) {
      _currentlookupWord = _histories.value[index + 1].word;
      _lookupDefinition();
    }
  }

  void onClickedPrevious() {
    if (_histories.value.isEmpty) {
      return;
    }
    final index = _getIndex(_histories.value, _currentlookupWord);
    if (index == _histories.value.length) {
      return;
    }

    if (index - 1 >= 0) {
      _currentlookupWord = _histories.value[index - 1].word;
      _lookupDefinition();
    }
  }

  Future<void> onDelete(String word) async {
    await dictionaryHistoryRepository.delete(word);
    final histories = await dictionaryHistoryRepository.getAll();
    histories.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    _histories.value = [...histories];
    _dictionaryState = const DictionaryState.initial();
  }

  String _romoveNonCharacter(String word) {
    word = word.replaceAllMapped(
        RegExp(r'[\[\]\+/\.\)\(\-,:;")\\]'), (match) => ' ');
    List<String> ls = word.split(' ');
    // fix for first character being a non-word-char in above list
    // if so, first split will be empty.
    // if length is >1
    if (ls.length > 1 && ls[0].isEmpty) {
      word = ls[1];
    } else {
      word = ls[0];
    }
    word.trim();
    return word;
  }

  int _getIndex(List<DictionaryHistory> histories, String word) {
    if (histories.isEmpty) return -1;
    // histories.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    for (int i = 0; i < histories.length; i++) {
      if (histories[i].word == word) {
        return i;
      }
    }
    // not found
    return -1;
  }

  bool isContainInHistories(List<DictionaryHistory> histories, String word) {
    if (histories.isEmpty) return false;
    // histories.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    for (int i = 0; i < histories.length; i++) {
      if (histories[i].word == word) {
        return true;
      }
    }
    // not found
    return false;
  }

  void onClickedHistoryButton() {
    _currentlookupWord = '';
    _dictionaryState = const DictionaryState.initial();
    notifyListeners();
  }
}
