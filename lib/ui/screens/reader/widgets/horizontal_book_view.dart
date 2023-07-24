import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../../business_logic/models/page_content.dart';
import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';
import '../controller/reader_view_controller.dart';
import 'pali_page_widget.dart';

class HorizontalBookView extends StatefulWidget {
  const HorizontalBookView({
    Key? key,
    this.onSearchedSelectedText,
    this.onSharedSelectedText,
    this.onClickedWord,
  }) : super(key: key);
  final ValueChanged<String>? onSearchedSelectedText;
  final ValueChanged<String>? onSharedSelectedText;
  final ValueChanged<String>? onClickedWord;

  @override
  State<HorizontalBookView> createState() => _HorizontalBookViewState();
}

class _HorizontalBookViewState extends State<HorizontalBookView> {
  late final ReaderViewController readerViewController;
  late final PageController pageController;

  SelectedContent? _selectedContent;

  @override
  void initState() {
    super.initState();
    readerViewController =
        Provider.of<ReaderViewController>(context, listen: false);
    pageController = PageController(
        initialPage: readerViewController.currentPage.value -
            readerViewController.book.firstPage);

    readerViewController.currentPage.addListener(_listenPageChange);
  }

  @override
  void dispose() {
    readerViewController.currentPage.removeListener(_listenPageChange);
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readerViewController =
        Provider.of<ReaderViewController>(context, listen: false);

    return PageView.builder(
      controller: pageController,
      pageSnapping: true,
      itemCount: readerViewController.pages.length,
      itemBuilder: (context, index) {
        final PageContent pageContent = readerViewController.pages[index];
        final script = context.read<ScriptLanguageProvider>().currentScript;
        // transciption
        String htmlContent = PaliScript.getScriptOf(
          script: script,
          romanText: pageContent.content,
          isHtmlText: true,
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                bottom: 100.0), // estimated toolbar height
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
                          // onSearch(_selectedContent!.plainText);
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
              child: PaliPageWidget(
                  pageNumber: pageContent.pageNumber!,
                  htmlContent: htmlContent,
                  script: script,
                  highlightedWord: readerViewController.textToHighlight,
                  pageToHighlight: readerViewController.pageToHighlight,
                  onClick: widget.onClickedWord,
                  book: readerViewController.book),
            ),
          ),
        );
      },
      onPageChanged: (value) {
        int pageNumber = value + readerViewController.book.firstPage;
        readerViewController.onGoto(pageNumber: pageNumber);
      },
    );
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

  void _listenPageChange() {
    int pageIndex = readerViewController.currentPage.value -
        readerViewController.book.firstPage;
    pageController.jumpToPage(pageIndex);
  }

}
