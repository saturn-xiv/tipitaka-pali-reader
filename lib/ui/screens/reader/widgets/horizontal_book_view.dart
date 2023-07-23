import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wtf_sliding_sheet/wtf_sliding_sheet.dart';

import '../../../../business_logic/models/page_content.dart';
import '../../../../business_logic/view_models/search_page_view_model.dart';
import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';
import '../../../../utils/platform_info.dart';
import '../../../dialogs/dictionary_dialog.dart';
import '../../home/search_page/search_page.dart';
import '../controller/reader_view_controller.dart';
import 'pali_page_widget.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class HorizontalBookView extends StatefulWidget {
  const HorizontalBookView({Key? key}) : super(key: key);

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
              child: PaliPageWidget(
                  pageNumber: pageContent.pageNumber!,
                  htmlContent: htmlContent,
                  script: script,
                  highlightedWord: readerViewController.textToHighlight,
                  pageToHighlight: readerViewController.pageToHighlight,
                  onClick: onClickedWord,
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

  Future<void> onClickedWord(String word) async {
    // removing puntuations etc.
    // convert to roman if display script is not roman
    word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: word);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    await showSlidingBottomSheet(
      context,
      builder: (context) {
        //Widget for SlidingSheetDialog's builder method
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final screenHeight = MediaQuery.of(context).size.height;
        const marginTop = 24.0;
        final slidingSheetDialogContent = SizedBox(
          height: screenHeight - (statusBarHeight + marginTop),
          child: DictionaryDialog(word: word),
        );

        return SlidingSheetDialog(
          elevation: 8,
          cornerRadius: 16,
          duration: Duration(
            milliseconds: Prefs.animationSpeed.round(),
          ),
          // minHeight: 200,
          snapSpec: const SnapSpec(
            snap: true,
            snappings: [0.4, 0.6, 0.8, 1.0],
            positioning: SnapPositioning.relativeToSheetHeight,
          ),
          headerBuilder: (context, _) {
            // building drag handle view
            return Center(
                heightFactor: 1,
                child: Container(
                  width: 56,
                  height: 10,
                  // color: Colors.black45,
                  decoration: BoxDecoration(
                    // border: Border.all(color: Colors.red),
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ));
          },
          // this builder is called when state change
          // normaly three states occurs
          // first state - isLaidOut = false
          // second state - islaidOut = true , isShown = false
          // thirs state - islaidOut = true , isShown = ture
          // to avoid there times rebuilding, return  prebuild content
          builder: (context, state) => slidingSheetDialogContent,
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

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );

    // delay a little miliseconds to wait for SearchPage Initialization

    Future.delayed(
      const Duration(milliseconds: 50),
      () => globalSearchWord.value = word,
    );
  }
}
