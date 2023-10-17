import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/data/constants.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';
import 'package:tipitaka_pali/services/rx_prefs.dart';
import 'package:tipitaka_pali/ui/screens/reader/mobile_reader_container.dart';
import 'package:tipitaka_pali/ui/screens/reader/widgets/search_widget.dart';
import 'package:wtf_sliding_sheet/wtf_sliding_sheet.dart';

import '../../../app.dart';
import '../../../business_logic/models/book.dart';
import '../../../business_logic/view_models/search_page_view_model.dart';
import '../../../providers/navigation_provider.dart';
import '../../../services/database/database_helper.dart';
import '../../../services/provider/script_language_provider.dart';
import '../../../services/repositories/book_repo.dart';
import '../../../services/repositories/page_content_repo.dart';
import '../../../utils/pali_script.dart';
import '../../../utils/platform_info.dart';
import '../../dialogs/dictionary_dialog.dart';
import '../dictionary/controller/dictionary_controller.dart';
import '../home/openning_books_provider.dart';
import '../home/search_page/search_page.dart';
import 'controller/reader_view_controller.dart';
import 'widgets/horizontal_book_view.dart';
import 'widgets/reader_tool_bar.dart';
import 'widgets/vertical_book_view.dart';

class Reader extends StatelessWidget {
  final Book book;
  final int? initialPage;
  final String? textToHighlight;
  final BookViewMode bookViewMode;
  final String bookUuid;

  const Reader({
    Key? key,
    required this.book,
    this.initialPage,
    this.textToHighlight,
    required this.bookViewMode,
    required this.bookUuid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    myLogger.i('calling Reader build method');
    // logger.i('pass parameter: book: ${book.id} --- ${book.name}');
    // logger.i('current Page in Reader Screen: $currentPage');
    // logger.i('textToHighlight in Reader Screen: $textToHighlight');
    final openedBookProvider = context.read<OpenningBooksProvider>();
    final combo = openedBookProvider.books.map((e) => e['book'].id).join('-');
    return ChangeNotifierProvider<ReaderViewController>(
      // this key prevents a refresh and the refresh is needed for this
      // no highlight bug to not show up.
      // open 2 book in two tabs, close one tab.. the remaining tab will
      // not allow highlighting if key(book.id) code is there.
      // it is good in many cases, but a bug somewhere causes
      // the highlight to fail
      // TODO try to fix this bug later
      //////////////////////////////////
      key: Key('${book.id}@$combo'),
      ////////////////////////
      create: (context) => ReaderViewController(
          context: context,
          bookRepository: BookDatabaseRepository(DatabaseHelper()),
          pageContentRepository:
              PageContentDatabaseRepository(DatabaseHelper()),
          book: book,
          initialPage: initialPage,
          textToHighlight: textToHighlight,
          bookUuid: bookUuid)
        ..loadDocument(),
      child: ReaderView(
        bookViewMode: bookViewMode,
      ),
    );
  }
}

class ReaderView extends StatelessWidget implements Searchable {
  final BookViewMode bookViewMode;
  ReaderView({Key? key, required this.bookViewMode}) : super(key: key);
  final _sc = SlidableBarController(initialStatus: Prefs.controlBarShow);

  @override
  void onSearchRequested(BuildContext context) {
    debugPrint('on search requested');
    Provider.of<ReaderViewController>(context, listen: false)
        .showSearchWidget(true);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(
              Platform.isMacOS
                  ? LogicalKeyboardKey.meta
                  : LogicalKeyboardKey.control,
              LogicalKeyboardKey.keyF): const SearchIntent(),
        },
        child: Actions(actions: <Type, Action<Intent>>{
          SearchIntent: SearchAction(this, context),
        }, child: _getReader(context)));
  }

  Widget _getReader(BuildContext context) {
    final showSearch = context.select<ReaderViewController, bool>(
        (controller) => controller.showSearch);

    final isLoaded = context.select<ReaderViewController, bool>(
        (controller) => controller.isloadingFinished);

    if (!isLoaded) {
      // display fade loading
      // circular progessing is somehow annoying
      return const Material(
        child: Center(
          child: Text('. . .'),
        ),
      );
    }

    return Scaffold(
      // appBar: PlatformInfo.isDesktop || Mobile.isTablet(context)
      //     ? null
      //     : const ReaderAppBar(),
      body: Consumer<ThemeChangeNotifier>(
          builder: ((context, themeChangeNotifier, child) => Container(
                color: getChosenColor(context),
                child: SlidableBar(
                    slidableController: _sc,
                    side: Side.bottom,
                    barContent: const ReaderToolbar(),
                    size: 100,
                    clicker: SlidableClicker(controller: _sc),
                    frontColor: Colors.white,
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    clickerSize: 32,
                    clickerPosition: 0.98,
                    child: Column(children: [
                      if (showSearch)
                        SearchWidget(
                          word: context
                              .read<ReaderViewController>()
                              .searchText
                              .value,
                        ),
                      Expanded(
                          // padding: EdgeInsets.only(top: showSearch ? 42 : 0),
                          child: bookViewMode == BookViewMode.horizontal
                              // don't const these two guys, otherwise theme changes
                              // won't be reflected, alternatively: get notified about
                              // changes in the views themselves
                              ? VerticalBookView(
                                  onSearchedSelectedText: (text) =>
                                      _onSearchSelectedText(text, context),
                                  onSharedSelectedText: _onShareSelectedText,
                                  onClickedWord: (word) =>
                                      _onClickedWord(word, context),
                                  onSearchedInCurrentBook: (text) =>
                                      _onClickedSearchInCurrent(context, text),
                                  onSelectionChanged: (text) {
                                    Provider.of<ReaderViewController>(context,
                                            listen: false)
                                        .selection = text;
                                  },
                                )
                              : HorizontalBookView(
                                  onSearchedSelectedText: (text) =>
                                      _onSearchSelectedText(text, context),
                                  onSharedSelectedText: _onShareSelectedText,
                                  onClickedWord: (word) =>
                                      _onClickedWord(word, context),
                                  onSearchedInCurrentBook: (text) =>
                                      _onClickedSearchInCurrent(context, text),
                                  onSelectionChanged: (text) {
                                    Provider.of<ReaderViewController>(context,
                                            listen: false)
                                        .selection = text;
                                  },
                                )),
                    ])),
              ))),
      // bottomNavigationBar: SafeArea(child: ControlBar()),
    );
  }

  void _onSearchSelectedText(String text, BuildContext context) {
    // removing punctuations etc.
    // convert to roman if display script is not roman
    var word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: text);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    if (PlatformInfo.isDesktop || Mobile.isTablet(context)) {
      // displaying dictionary in the side navigation view
      if (!context.read<NavigationProvider>().isNavigationPaneOpened) {
        context.read<NavigationProvider>().toggleNavigationPane();
      }
      context.read<NavigationProvider>().moveToSearchPage();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchPage()),
      );
    }
    // delay a little milliseconds to wait for SearchPage Initialization

    Future.delayed(
      const Duration(milliseconds: 50),
      () => globalSearchWord.value = word,
    );
  }

  void _onShareSelectedText(String text) {
    Share.share(text, subject: 'Pāḷi text from TPR');
  }

  Future<void> _onClickedWord(String word, BuildContext context) async {
    // removing punctuations etc.
    // convert to roman if display script is not roman
    word = PaliScript.getRomanScriptFrom(
        script: context.read<ScriptLanguageProvider>().currentScript,
        text: word);
    word = word.replaceAll(RegExp(r'[^a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]'), '');
    // convert ot lower case
    word = word.toLowerCase();

    // displaying dictionary in the side navigation view
    if ((PlatformInfo.isDesktop || Mobile.isTablet(context))) {
      if (context.read<NavigationProvider>().isNavigationPaneOpened) {
        context.read<NavigationProvider>().moveToDictionaryPage();
        // delay a little milliseconds to wait for DictionaryPage initialization
        await Future.delayed(const Duration(milliseconds: 50),
            () => globalLookupWord.value = word);
        return;
      }

      // displaying dictionary in side sheet dialog
      final sideSheetWidth = context
          .read<StreamingSharedPreferences>()
          .getDouble(panelSizeKey, defaultValue: defaultPanelSize)
          .getValue();

      showGeneralDialog(
        context: context,
        barrierLabel: 'TOC',
        barrierDismissible: true,
        transitionDuration:
            Duration(milliseconds: Prefs.animationSpeed.round()),
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
    } else {
      // displaying dictionary using bottom sheet dialog
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
  }

  void _onClickedSearchInCurrent(BuildContext context, String text) {
    context.read<ReaderViewController>().showSearchWidget(
          true,
          searchText: text,
        );
  }

  Color getChosenColor(BuildContext context) {
    switch (Prefs.selectedPageColor) {
      case 0:
        return (Color(Colors.white.value));
      case 1:
        return Theme.of(context)
            .colorScheme
            .surfaceVariant; // ?? (const Color(seypia));
      case 2:
        return (Color(Colors.black.value));
      default:
        return Color(Colors.white.value);
    }
  }
}

abstract class Searchable {
  void onSearchRequested(BuildContext context);
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class SearchAction extends Action<SearchIntent> {
  SearchAction(this.searchable, this.context);

  final Searchable searchable;
  final BuildContext context;

  @override
  void invoke(covariant SearchIntent intent) =>
      searchable.onSearchRequested(context);
}

class SlidableClicker extends StatefulWidget {
  const SlidableClicker({super.key, required this.controller});

  final SlidableBarController controller;

  @override
  State<SlidableClicker> createState() => _SlidableClickerState();
}

class _SlidableClickerState extends State<SlidableClicker> {
  toggle() {
    setState(() {
      Prefs.controlBarShow = !Prefs.controlBarShow;
      (Prefs.controlBarShow)
          ? widget.controller.show()
          : widget.controller.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Material(
            child: InkWell(
          onTap: toggle,
          child: Ink(
            width: 42,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Icon(
              Prefs.controlBarShow
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: Colors.white,
            ),
          ),
        )));
  }
}
