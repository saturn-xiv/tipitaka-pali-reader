import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../app.dart';
import '../../../../business_logic/models/page_content.dart';
import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';
import '../controller/reader_view_controller.dart';
import 'pali_page_widget.dart';
import 'vertical_book_slider.dart';

class VerticalBookView extends StatefulWidget {
  const VerticalBookView({
    Key? key,
    this.onSearchedSelectedText,
    this.onSharedSelectedText,
    this.onClickedWord,
  }) : super(key: key);
  final ValueChanged<String>? onSearchedSelectedText;
  final ValueChanged<String>? onSharedSelectedText;
  final ValueChanged<String>? onClickedWord;

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
                          widget.onSearchedSelectedText
                              ?.call(_selectedContent!.plainText);
                        },
                        label: 'Search'),
                    ContextMenuButtonItem(
                        onPressed: () {
                          ContextMenuController.removeAny();
                          widget.onSharedSelectedText
                              ?.call(_selectedContent!.plainText);
                          // Share.share(_selectedContent!.plainText,
                          //     subject: 'Pāḷi text from TPR');
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
                          onClick: widget.onClickedWord,
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

}
