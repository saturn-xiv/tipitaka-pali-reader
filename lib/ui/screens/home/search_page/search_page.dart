import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/ui/widgets/get_velthuis_help_widget.dart';
import 'package:tipitaka_pali/ui/widgets/value_listenser.dart';
import 'package:tipitaka_pali/utils/platform_info.dart';
import '../../../../services/database/database_helper.dart';
import '../../../../services/prefs.dart';
import '../../../../services/repositories/search_history_repo.dart';
import '../../../widgets/search_type_segmented_widget.dart';
import 'search_history_view.dart';
import 'search_suggestion_view.dart';

import '../../../../business_logic/view_models/search_page_view_model.dart';
import '../../../../inner_routes.dart';
import '../../../../utils/pali_script.dart';
import '../../../../utils/pali_script_converter.dart';
import '../../../../utils/script_detector.dart';
import '../widgets/search_bar.dart';

enum QueryMode { exact, prefix, distance, anywhere }

extension ParseToString on QueryMode {
  String toShortString() {
    print(toString());
    return toString().split('.').last;
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController controller;
  late bool isShowingSearchModeView;

  @override
  void initState() {
    controller = TextEditingController();
    isShowingSearchModeView = false;
    super.initState();
    // globalSearchWord.addListener(() {
    //   setState(() {});
    // });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChangeNotifierProvider<SearchPageViewModel>(
        create: (_) => SearchPageViewModel(
              searchHistoryRepository:
                  SearchHistoryDatabaseRepository(dbh: DatabaseHelper()),
            )..init(),
        child: Builder(builder: (context) {
          final vm = context.read<SearchPageViewModel>();
          return Scaffold(
              appBar: AppBar(
                // disable because of conflit with mobile search
                // leading: getVelthuisHelp(context),
                automaticallyImplyLeading: Mobile.isPhone(context),
                title: Text(AppLocalizations.of(context)!.search),
                centerTitle: true,
                actions: [
                  FilterChip(
                      label: Text(
                        AppLocalizations.of(context)!.fuzzy,
                        style: const TextStyle(fontSize: 12),
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
              body: ValueListenableListener(
                onValueChanged: (searchWord) {
                  if (searchWord != null) {
                    _onSubmitted(searchWord, vm);
                  }
                },
                valueListenable: globalSearchWord,
                child: Column(
                  children: [
                    SearchTypeSegmentedControl(
                      mode: vm.queryMode,
                      wordDistance: vm.wordDistance,
                      onModeChanged: (value) {
                        setState(() {
                          vm.onQueryModeChanged(value);
                        });
                      },
                      onDistanceChanged: (value) {
                        vm.onWordDistanceChanged(value);
                      },
                    ),
                    // search bar
                    Row(
                      children: [
                        Expanded(
                          child: TprSearchBar(
                            hint: _getHint(vm.queryMode),
                            controller: controller,
                            onSubmitted: (value) {
                              _onSubmitted(value, vm);
                            },
                            onTextChanged: vm.onTextChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    //const Text("message window"),
                    // search mode chooser view
                    AnimatedSize(
                      duration:
                          Duration(milliseconds: Prefs.animationSpeed.round()),
                      child: /* isShowingSearchModeView
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
                          : */
                          const SizedBox.shrink(),
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
                                      onClickedAddButton: (suggestion) {
                                        _updateInput(suggestion.word);
                                      },
                                      onClickedSuggestion: (suggestion) {
                                        _updateInput(suggestion.word);
                                        _onSubmitted(controller.text, vm);
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
                ),
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
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));
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

  String _getHint(QueryMode queryMode) {
    if (queryMode == QueryMode.exact) {
      return AppLocalizations.of(context)!.exact;
    } else if (queryMode == QueryMode.distance) {
      return AppLocalizations.of(context)!.distance;
    } else if (queryMode == QueryMode.prefix) {
      return AppLocalizations.of(context)!.prefix;
    } else {
      return AppLocalizations.of(context)!.anywhere;
    }
  }

  // _showSearchTypeSelectDialog(QueryMode queryMode) {
  //   return showBottomSheet<void>(
  //       context: context,
  //       builder: (BuildContext bc) {
  //         return SearchModeView(mode: queryMode);
  //       });
  // }

  void _onSubmitted(String searchWord, SearchPageViewModel vm) {
    searchWord = searchWord.trimRight();
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

  @override
  bool get wantKeepAlive => true;
}
