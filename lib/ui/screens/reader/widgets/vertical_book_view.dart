import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/app.dart';
import 'package:tipitaka_pali/business_logic/view_models/search_page_view_model.dart';
import 'package:tipitaka_pali/services/rx_prefs.dart';
import 'package:tipitaka_pali/ui/screens/reader/widgets/vertical_book_slider.dart';
import 'package:tipitaka_pali/services/prefs.dart';

import '../../../../business_logic/models/page_content.dart';
import '../../../../providers/navigation_provider.dart';
import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';
import '../../../dialogs/dictionary_dialog.dart';
import '../../../widgets/custom_text_selection_control.dart';
import '../../dictionary/controller/dictionary_controller.dart';
import '../controller/reader_view_controller.dart';
import 'pali_page_widget.dart';

class VerticalBookView extends StatefulWidget {
  const VerticalBookView({Key? key}) : super(key: key);

  @override
  State<VerticalBookView> createState() => _VerticalBookViewState();
}

class _VerticalBookViewState extends State<VerticalBookView> {
  late final ReaderViewController readerViewController;
  late final ItemPositionsListener itemPositionsListener;
  late final ItemScrollController itemScrollController;

  String searchText = '';

  SelectedContent? _selectedContent;

  @override
  void initState() {
    super.initState();
    readerViewController =
        Provider.of<ReaderViewController>(context, listen: false);
    itemPositionsListener = ItemPositionsListener.create();
    itemScrollController = ItemScrollController();
    itemPositionsListener.itemPositions.addListener(_listenItemPosition);
    readerViewController.currentPage.addListener(_listenPageChange);
    readerViewController.searchText.addListener(_onSearchTextChanged);
    readerViewController.currentSearchResult.addListener(() {
      setState(() {});
    });
    readerViewController.highlightEveryMatch.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_listenItemPosition);
    readerViewController.currentPage.removeListener(_listenPageChange);
    readerViewController.searchText.removeListener(_onSearchTextChanged);
    readerViewController.currentSearchResult
        .removeListener(_onSearchTextChanged);
    readerViewController.highlightEveryMatch
        .removeListener(_onSearchTextChanged);
    super.dispose();
  }

  static final Map<String, Widget> cachedPages = {};

  @override
  Widget build(BuildContext context) {
    int pageIndex = readerViewController.currentPage.value -
        readerViewController.book.firstPage;

    debugPrint('page index: $pageIndex');
    debugPrint('searchText-searchText: $searchText');

    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        children: [
          Expanded(
            child: SelectionArea(
              focusNode: FocusNode(
                canRequestFocus: true,
              ),
              contextMenuBuilder: (context, selectableRegionState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: [
                    ...selectableRegionState.contextMenuButtonItems,
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          onSearch(_selectedContent!.plainText);
                        },
                        label: 'Search'),
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          Share.share(_selectedContent!.plainText,
                              subject: 'Pāḷi text from TPR');
                        },
                        label: 'Share'),
                  ],
                );
              },
              onSelectionChanged: (value) => _selectedContent = value,
              child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ScrollablePositionedList.builder(
                    initialScrollIndex: pageIndex,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    itemCount: readerViewController.pages.length,
                    itemBuilder: (_, index) {
                      final PageContent pageContent =
                          readerViewController.pages[index];
                      final script =
                          context.read<ScriptLanguageProvider>().currentScript;
                      // transciption

                      final id =
                          '${readerViewController.book.name}-${readerViewController.book.id}-$index';

                      final stopwatch = Stopwatch()..start();
                      String htmlContent = PaliScript.getCachedScriptOf(
                        script: script,
                        romanText: pageContent.content,
                        cacheId: id,
                        isHtmlText: true,
                      );
                      print(
                          'doSomething() executed in ${stopwatch.elapsedMilliseconds} ms');

                      return PaliPageWidget(
                          pageNumber: pageContent.pageNumber!,
                          htmlContent: htmlContent,
                          script: script,
                          highlightedWord: readerViewController.textToHighlight,
                          searchText: searchText,
                          pageToHighlight: readerViewController.pageToHighlight,
                          onClick: onClickedWord,
                          onSearch: onSearch,
                          book: readerViewController.book);
                    },
                  )),
            ),
          ),
          SizedBox(
              width: 32,
              height: constraints.maxHeight,
              child: const VerticalBookSlider()),
        ],
      );
    });
  }

  // String? _needToHighlight(int index) {
  //   if (readerViewController.textToHighlight == null) return null;
  //   if (readerViewController.initialPage == null) return null;

  //   if (index ==
  //       readerViewController.initialPage! -
  //           readerViewController.book.firstPage) {
  //     return readerViewController.textToHighlight;
  //   }
  //   return null;
  // }

  void _listenItemPosition() {
    // if only one page exist in view, there in no need to update current page
    if (itemPositionsListener.itemPositions.value.length == 1) return;

    // Normally, maximum pages will not exceed two because of page height
    // Three pages is rare case.

    final firstPageOfBook = readerViewController.book.firstPage;
    final currentPage = readerViewController.currentPage.value;
    final upperPageInView = itemPositionsListener.itemPositions.value.first;
    final pageNumberOfUpperPage = upperPageInView.index + firstPageOfBook;
    final lowerPageInView = itemPositionsListener.itemPositions.value.last;
    final pageNumberOfLowerPage = lowerPageInView.index + firstPageOfBook;

    // scrolling down ( natural scrolling )
    //update lower page as current page
    if (lowerPageInView.itemLeadingEdge < 0.4 &&
        pageNumberOfLowerPage != currentPage) {
      myLogger.i('recorded current page: $currentPage');
      myLogger.i('lower page-height is over half');
      myLogger.i('page number of it: $pageNumberOfLowerPage');
      readerViewController.onGoto(pageNumber: pageNumberOfLowerPage);
      return;
    }

    // scrolling up ( natural scrolling )
    if (upperPageInView.itemTrailingEdge > 0.6 &&
        pageNumberOfUpperPage != currentPage) {
      myLogger.i('recorded current page: $currentPage');
      myLogger.i('upper page-height is over half');
      myLogger.i('page number of it: $pageNumberOfUpperPage');
      readerViewController.onGoto(pageNumber: pageNumberOfUpperPage);
      return;
    }
  }

  void _onSearchTextChanged() {
    setState(() {
      searchText = readerViewController.searchText.value;
    });
  }

  void _listenPageChange() {
    // page change are comming from others ( goto, tocs and slider )
    final firstPage = readerViewController.book.firstPage;
    final currenPage = readerViewController.currentPage.value;
    final pageIndex = currenPage - firstPage;

    final pagesInView = itemPositionsListener.itemPositions.value
        .map((itemPosition) => itemPosition.index)
        .toList();

    if (!pagesInView.contains(pageIndex)) {
      itemScrollController.jumpTo(index: pageIndex);
    }
  }

  Future<void> onClickedWord(String word) async {
    // removing puntuations etc.
    // convert to roman if display script is not roman
    word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: word);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    // displaying dictionary in the side navigation view
    if (context.read<NavigationProvider>().isNavigationPaneOpened) {
      context.read<NavigationProvider>().moveToDictionaryPage();
      // delay a little miliseconds to wait for DictionaryPage Initialation
      await Future.delayed(const Duration(milliseconds: 50),
          () => globalLookupWord.value = word);
      return;
    }

    // displaying dictionary in dialog
    final sideSheetWidth = context
        .read<StreamingSharedPreferences>()
        .getDouble(panelSizeKey, defaultValue: defaultPanelSize)
        .getValue();

    showGeneralDialog(
      context: context,
      barrierLabel: 'TOC',
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: Prefs.animationSpeed.round()),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(-1, 0), end: const Offset(0, 0))
              .animate(
            CurvedAnimation(parent: animation, curve: Curves.linear),
          ),
          child: child,
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              width: sideSheetWidth,
              height: MediaQuery.of(context).size.height - 80,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  )),
              child: DictionaryDialog(word: word),
            ),
          ),
        );
      },
    );
  }

  Future<void> onSearch(String word) async {
    // removing puntuations etc.
    // convert to roman if display script is not roman
    word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: word);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    // displaying dictionary in the side navigation view
    if (!context.read<NavigationProvider>().isNavigationPaneOpened) {
      context.read<NavigationProvider>().toggleNavigationPane();
    }
    context.read<NavigationProvider>().moveToSearchPage();
    // delay a little miliseconds to wait for SearchPage Initialization

    Future.delayed(const Duration(milliseconds: 50), () {
      globalSearchWord.value = word;
    });
  }
}
