import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../services/database/database_helper.dart';
import '../../../../services/prefs.dart';
import '../../../../services/repositories/search_history_repo.dart';
import 'search_history_view.dart';
import 'search_suggestion_view.dart';

import '../../../../business_logic/view_models/search_page_view_model.dart';
import '../../../../inner_routes.dart';
import '../../../../utils/pali_script.dart';
import '../../../../utils/pali_script_converter.dart';
import '../../../../utils/script_detector.dart';
import '../widgets/search_bar.dart';
import 'search_mode_view.dart';

enum QueryMode { exact, prefix, distance, anywhere }

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController controller;
  late bool isShowingSearchModeView;

  @override
  void initState() {
    controller = TextEditingController();
    isShowingSearchModeView = false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchPageViewModel>(
        create: (_) => SearchPageViewModel(
              searchHistoryRepository:
                  SearchHistoryDatabaseRepository(dbh: DatabaseHelper()),
            )..init(),
        child: Builder(builder: (context) {
          final vm = context.read<SearchPageViewModel>();
          return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(AppLocalizations.of(context)!.search),
                centerTitle: true,
                actions: [
                  FilterChip(
                      label: Text(
                        'Fuzzy',
                        style: TextStyle(fontSize: 12),
                      ),
                      selected: Prefs.isFuzzy,
                      onSelected: (value) {
                        setState(() {
                          Prefs.isFuzzy = !Prefs.isFuzzy;
                          vm.isFuzzy = Prefs.isFuzzy;
                          vm.onTextChanged(controller.text);
                        });
                      }),
                  const SizedBox(
                    width: 8,
                  )
                ],
              ),
              body: Column(
                children: [
                  // search bar
                  Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          hint: getHint(vm.queryMode),
                          controller: controller,
                          onSubmitted: (value) {
                            _onSubmitted(value, vm);
                          },
                          onTextChanged: vm.onTextChanged,
                        ),
                      ),
                      // IconButton(
                      //   padding: EdgeInsets.zero,
                      //   constraints: BoxConstraints(),
                      //   icon: Prefs.isFuzzy
                      //       ? Icon(Icons.lens_blur)
                      //       : Icon(Icons.lens_outlined),
                      //   onPressed: () {
                      //     setState(() {
                      //       Prefs.isFuzzy = !Prefs.isFuzzy;
                      //       vm.isFuzzy = Prefs.isFuzzy;
                      //       vm.onTextChanged(controller.text);
                      //     });
                      //   },
                      //   tooltip: "Fuzzy Search",
                      // ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.filter_list),
                        tooltip: AppLocalizations.of(context)!.filter,
                        onPressed: () {
                          setState(() {
                            isShowingSearchModeView = !isShowingSearchModeView;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  // search mode chooser view
                  AnimatedSize(
                    duration:
                        Duration(milliseconds: Prefs.animationSpeed.round()),
                    child: isShowingSearchModeView
                        ? SearchModeView(
                            mode: vm.queryMode,
                            wordDistance: vm.wordDistance,
                            onModeChanged: (value) {
                              vm.onQueryModeChanged(value);
                            },
                            onDistanceChanged: (value) {
                              vm.onWordDistanceChanged(value);
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  // suggestion view

                  Expanded(
                    child: ValueListenableBuilder(
                        valueListenable: vm.isSearching,
                        builder: (context, isSearching, child) {
                          if (isSearching) {
                            return ValueListenableBuilder(
                                valueListenable: vm.suggestions,
                                builder: (_, suggestions, __) {
                                  return SearchSuggestionView(
                                    suggestions: suggestions,
                                    onClickedSubmitButton: (suggestion) {
                                      _updateInput(suggestion.word);
                                      _onSubmitted(controller.text, vm);
                                    },
                                    onClickedSuggestion: (suggestion) {
                                      _updateInput(suggestion.word);
                                    },
                                  );
                                });
                          }
                          return ValueListenableBuilder(
                              valueListenable: vm.histories,
                              builder: (_, histories, __) {
                                return SearchHistoryView(
                                    histories: histories,
                                    onClick: (value) {
                                      _onSubmitted(value, vm);
                                    },
                                    onDelete: vm.onDeleteButtonClicked);
                              });
                        }),
                  ),
                ],
              ));
        }));
  }

  void _updateInput(String suggestion) {
    String inputText = controller.text;
    final inputScript = ScriptDetector.getLanguage(inputText);
    final words = inputText.split(' ');
    if (inputScript == Script.roman) {
      words.last = suggestion;
    } else {
      words.last =
          PaliScript.getScriptOf(script: inputScript, romanText: suggestion);
    }
    inputText = words.join(' ');
    controller.text = inputText;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
  }

  Widget _buildEmptyView(BuildContext context) {
    return GestureDetector(
      child: Container(color: Colors.transparent),
      // in android, keyboard can be hide by pressing back button
      // ios doesn't have back button
      // so to hide keyboard, provide this
      onTap: () => FocusScope.of(context).unfocus(),
    );
  }

  String getHint(QueryMode queryMode) {
    return queryMode.toString();
  }

  // _showSearchTypeSelectDialog(QueryMode queryMode) {
  //   return showBottomSheet<void>(
  //       context: context,
  //       builder: (BuildContext bc) {
  //         return SearchModeView(mode: queryMode);
  //       });
  // }

  void _onSubmitted(String searchWord, SearchPageViewModel vm) {
    final inputScriptLanguage = ScriptDetector.getLanguage(searchWord);
    if (inputScriptLanguage != Script.roman) {
      searchWord = PaliScript.getRomanScriptFrom(
          script: inputScriptLanguage, text: searchWord);
    }
    vm.onSubmmited(searchWord);
    // open search results
    Navigator.pushNamed(context, searchResultRoute, arguments: {
      'searchWord': searchWord,
      'queryMode': vm.queryMode,
      'wordDistance': vm.wordDistance,
    });
  }
}
