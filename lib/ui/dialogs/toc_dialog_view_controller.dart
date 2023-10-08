import 'package:flutter/foundation.dart';
import 'package:tipitaka_pali/business_logic/models/toc.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/repositories/toc_repo.dart';

class TocDialogViewController {
  final String bookID;
  final TocRepository tocRepository;

  TocDialogViewController({required this.bookID, required this.tocRepository});

  late final List<Toc> _allTocs;
  final ValueNotifier<List<Toc>?> _tocs = ValueNotifier(null);
  ValueListenable<List<Toc>?> get tocs => _tocs;

  String _filterText = '';
  String get filterText => _filterText;

  void onLoad() async {
    _allTocs = await tocRepository.getTocs(bookID);
    _tocs.value = _allTocs;
  }

  void onFilterChanged(String filter) async {
    _filterText = filter;

    if (filter.isEmpty) {
      _tocs.value = [..._allTocs];
    } else {
      if (Prefs.isFuzzy) {
        String simpleFilteredWord = filter.replaceAllMapped(
          RegExp('[ṭḍṃāūīḷñṅ]'),
          (match) => {
            'ṭ': 't',
            'ḍ': 'd',
            'ṃ': 'm',
            'ā': 'a',
            'ū': 'u',
            'ī': 'i',
            'ḷ': 'l',
            'ñ': 'n',
            'ṅ': 'n'
          }[match.group(0)]!,
        );

        final filterdToc = _allTocs
            .where((element) => element.name
                .toLowerCase()
                .contains(simpleFilteredWord.toLowerCase()))
            .toList();
        _tocs.value = [...filterdToc];
      } else {
        final filterdToc = _allTocs
            .where((element) =>
                element.name.toLowerCase().contains(filter.toLowerCase()))
            .toList();
        _tocs.value = [...filterdToc];
      }
    }
  }
}
