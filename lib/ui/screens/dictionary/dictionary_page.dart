import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/repositories/dictionary_repo.dart';
import '../../../business_logic/models/dictionary_history.dart';
import '../../widgets/colored_text.dart';
import 'controller/dictionary_controller.dart';
import 'widget/dict_algo_selector.dart';
import 'widget/dict_content_view.dart';
import 'widget/dict_search_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({Key? key}) : super(key: key);

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage>
    with AutomaticKeepAliveClientMixin {
  final List<String> _words = [];
  String _lastWord = "";

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.history,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () async {
              await _showDictionaryHistoryDlg(context);
            },
          ),
        ],
      ),
      body: ChangeNotifierProvider<DictionaryController>(
        create: (context) => DictionaryController(
          context: context,
        )..onLoad(),
        child: Consumer<DictionaryController>(builder: (context, dc, __) {
          if (dc.lookupWord != null) {
            if (dc.lookupWord != _lastWord) {
              _words.add(dc.lookupWord!);
              _lastWord = dc.lookupWord!;
              // debugPrint(" added words:  ${_words.toString()}");
            }
          } // if not null
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Row(
                children: [
                  const Expanded(child: DictionarySearchField()),
                  const SizedBox(width: 8), // padding
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      if (_words.isNotEmpty) {
                        // i think this should be handled by the state, but I'm
                        // sure the notifier is always the same object, so I
                        // handle here in the ui.

                        //the last -1 item is shown.. so need to go -2
                        int index = _words.length - 2;
                        // don't go beyond
                        index = (index < 0) ? 0 : index;
                        // save that word
                        _lastWord = _words[index];
                        _words.removeLast(); // remove from list
                        dc.onWordClicked(_lastWord);
                        //debugPrint("onpressed:  _words:  ${_words.toString()}");
                      }
                    },
                  ),
                  const DictionaryAlgorithmModeView(),
                ],
              ),
              const SizedBox(height: 4), // padding
              const Expanded(child: DictionaryContentView()),
            ]),
          );
        }),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
  Future<void> _showDictionaryHistoryDlg(BuildContext context) async {
    final dbService = DatabaseHelper();
    final dbDHR = DictionaryDatabaseRepository(dbService);

    return showDialog<void>(
      context: context,
      //barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: ColoredText(AppLocalizations.of(context)!.dictionaryHistory),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const ScrollPhysics(),
              child: FutureBuilder<List<DictionaryHistory>>(
                  future: dbDHR.getDictionaryHistory(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final dictHistory = snapshot.data![index];
                          String s = dictHistory.date;
                          String sFormattedDate =
                              "${s.substring(6, 8)}/${s.substring(4, 6)}/${s.substring(0, 4)}";

                          return Card(
                            child: ListTile(
                              leading: ColoredText(
                                  '${index + 1}) ${dictHistory.word}'),
                              //title: ColoredText(" $sFormattedDate"),
                              onTap: () {
                                // cause a lookup
                                globalLookupWord.value =
                                    snapshot.data![index].word;
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        });
                  }),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
