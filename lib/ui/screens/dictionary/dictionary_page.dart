import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/repositories/dictionary_repo.dart';
import '../../../business_logic/models/dictionary_history.dart';
import '../../../services/repositories/dictionary_history_repo.dart';
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
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ChangeNotifierProvider<DictionaryController>(
      create: (context) => DictionaryController(
        context: context,
        dictionaryRepository: DictionaryDatabaseRepository(DatabaseHelper()),
        dictionaryHistoryRepository: DictionaryHistoryDatabaseRepository(
          dbh: DatabaseHelper(),
        ),
      )..onLoad(),
      child: Consumer<DictionaryController>(builder: (context, dc, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dictionary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => dc.onClickedPrevious(),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => dc.onClickedForward(),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: dc.onClickedHistoryButton,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Row(
                children: const [
                  Expanded(child: DictionarySearchField()),
                  SizedBox(width: 8), // padding
                  DictionaryAlgorithmModeView(),
                ],
              ),
              const SizedBox(height: 4), // padding
              const Expanded(child: DictionaryContentView()),
            ]),
          ),
        );
      }),
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
          content: SizedBox(
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
                          // String s = dictHistory.date;
                          // String sFormattedDate =
                          //     "${s.substring(6, 8)}/${s.substring(4, 6)}/${s.substring(0, 4)}";

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
