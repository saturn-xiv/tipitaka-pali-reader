import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/database/database_helper.dart';
import '../../services/repositories/dictionary_history_repo.dart';
import '../../services/repositories/dictionary_repo.dart';
import '../screens/dictionary/controller/dictionary_controller.dart';
import '../screens/dictionary/widget/dict_algo_selector.dart';
import '../screens/dictionary/widget/dict_content_view.dart';
import '../screens/dictionary/widget/dict_search_field.dart';

class DictionaryDialog extends StatelessWidget {
  final String? word;

  const DictionaryDialog({Key? key, this.word}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DictionaryController>(
      create: (context) =>
          DictionaryController(context: context,
                    dictionaryRepository: DictionaryDatabaseRepository(DatabaseHelper()),
          dictionaryHistoryRepository: DictionaryHistoryDatabaseRepository(
            dbh: DatabaseHelper(),
          ),
           lookupWord: word)..onLoad(),
      child: Consumer<DictionaryController>(
        builder: (context, dc, __) {
          return Material(
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 56.0),
                  child: DictionaryContentView(),
                ),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(child: DictionarySearchField()),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => dc.onClickedPrevious(),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: DictionaryAlgorithmModeView(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
