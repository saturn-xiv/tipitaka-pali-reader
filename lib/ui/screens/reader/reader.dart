import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:slidable_bar/slidable_bar.dart';
import 'package:tipitaka_pali/data/constants.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';
import 'package:tipitaka_pali/ui/screens/reader/widgets/search_widget.dart';

import '../../../app.dart';
import '../../../business_logic/models/book.dart';
import '../../../services/database/database_helper.dart';
import '../../../services/repositories/book_repo.dart';
import '../../../services/repositories/page_content_repo.dart';
import '../../../utils/platform_info.dart';
import '../home/openning_books_provider.dart';
import 'controller/reader_view_controller.dart';
import 'widgets/desktop_book_view.dart';
import 'widgets/mobile_book_view.dart';
import 'widgets/reader_tool_bar.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class Reader extends StatelessWidget {
  final Book book;
  final int? initialPage;
  final String? textToHighlight;

  const Reader({
    Key? key,
    required this.book,
    this.initialPage,
    this.textToHighlight,
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
          textToHighlight: textToHighlight)
        ..loadDocument(),
      child: ReaderView(),
    );
  }
}

class ReaderView extends StatelessWidget implements Searchable {
  ReaderView({Key? key}) : super(key: key);
  final _sc = SlidableBarController(initialStatus: Prefs.controlBarShow);

  @override
  void onSearchRequested(BuildContext context) {
    debugPrint('on search requested');
    Provider.of<ReaderViewController>(context, listen: false).showSearchWidget(true);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
          const SearchIntent(),
        },
        child: Actions(
            actions: <Type, Action<Intent>>{
              SearchIntent: SearchAction(this, context),
            },
            child: _getReader(context)));
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
            color: getChosenColor(),
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
              child: Stack(children: [
                if (showSearch)
                  const SearchWidget(),
                Padding(padding: EdgeInsets.only(top: showSearch ? 42 : 0), child: PlatformInfo.isDesktop || Mobile.isTablet(context)
                // don't const these two guys, otherwise theme changes
                // won't be reflected, alternatively: get notified about
                // changes in the views themselves
                    ? const DesktopBookView()
                    : const MobileBookView()),

              ])
            ),
          ))),
      // bottomNavigationBar: SafeArea(child: ControlBar()),
    );
  }

  Color getChosenColor() {
    switch (Prefs.selectedPageColor) {
      case 0:
        return (Color(Colors.white.value));
      case 1:
        return (const Color(seypia));
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
  void invoke(covariant SearchIntent intent) => searchable.onSearchRequested(context);
}

class SlidableClicker extends StatefulWidget {
  const SlidableClicker({ super.key, required this.controller });

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