import 'package:flutter/material.dart';
import 'package:ms_material_color/ms_material_color.dart';
import 'package:provider/provider.dart';
import 'package:tabbed_view/tabbed_view.dart';

import '../../../business_logic/models/book.dart';
import '../../../services/provider/script_language_provider.dart';
import '../../../services/provider/theme_change_notifier.dart';
import '../../../utils/pali_script.dart';
import '../../../utils/platform_info.dart';
import '../home/openning_books_provider.dart';
import 'reader.dart';

class ReaderContainer extends StatefulWidget {
  const ReaderContainer({Key? key}) : super(key: key);

  @override
  State<ReaderContainer> createState() => _ReaderContainerState();
}

class _ReaderContainerState extends State<ReaderContainer> {
  var tabsVisibility = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget readerAt(int i, List<Map<String, dynamic>> books) {
    final current = books[i];
    final book = current['book'] as Book;
    final currentPage = current['current_page'] as int?;
    final textToHighlight = current['text_to_highlight'] as String?;
    var reader = Reader(
      book: book,
      initialPage: currentPage,
      textToHighlight: textToHighlight,
    );
    return reader;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: There are two states, empty state and data state
    // only rebuild when states are not equal.
    // when previous and new state is same,
    // add new books to tabbed view by TabbedViewController
    final openedBookProvider = context.watch<OpenningBooksProvider>();
    final books = openedBookProvider.books;

    final tabs = books.asMap().entries.map((entry) {
      final book = entry.value['book'] as Book;
      final index = entry.key;
      final uuid = entry.value['uuid'];
      // Newly opened tab always becomes visible and hides the last visible book
      if (index == 0 && !tabsVisibility.containsKey(uuid)) {
        tabsVisibility[uuid] = true;

        if (books.length > 3) {
          for (var i = books.length - 1; i > 1; i--) {
            final revUuid = books[i]['uuid'];
            if (tabsVisibility.containsKey(revUuid) &&
                tabsVisibility[revUuid] == true) {
              tabsVisibility[revUuid] = false;
              break;
            }
          }
        }
      }
      final isVisible = (tabsVisibility[uuid] ?? false) == true;
      return TabData(
          text: PaliScript.getScriptOf(
              script: context.watch<ScriptLanguageProvider>().currentScript,
              romanText: book.name),
          buttons: [
            TabButton(
                icon: IconProvider.data(
                    isVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => {
                      setState(() {
                        tabsVisibility[uuid] = !isVisible;
                      })
                    }),
          ],
          keepAlive: false);
    }).toList();

    if (books.isEmpty) {
      return Container(
        color: const Color(0xfffbf0da),
        child: Center(
          child: Text(
            PaliScript.getScriptOf(
              script: context.watch<ScriptLanguageProvider>().currentScript,
              romanText: ('''
Sabbapāpassa akaraṇaṃ
Kusalassa upasampadā
Sacittapa⁠riyodāpanaṃ
Etaṃ buddhānasāsanaṃ
'''),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.brown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surfaceTint;
    final materialColor = MsMaterialColor(primaryColor.value);
    final TabbedViewThemeData themeData =
        TabbedViewThemeData.minimalist(colorSet: materialColor);
    Radius radius = const Radius.circular(8.0);
    BorderRadiusGeometry? borderRadius =
        BorderRadius.only(topLeft: radius, topRight: radius);
    themeData.tabsArea
      ..border = const Border(bottom: BorderSide(color: Colors.grey))
      ..middleGap = .0;

    themeData.tab
      ..margin = const EdgeInsets.only(top: 2)
      ..textStyle = TextStyle(color: Theme.of(context).colorScheme.onBackground)
      ..padding = const EdgeInsets.all(4)
      ..buttonsOffset = 18
      ..decoration = BoxDecoration(
          shape: BoxShape.rectangle,
          color: Theme.of(context).colorScheme.background,
          border: Border.all(color: Colors.grey),
          borderRadius: borderRadius)
      ..selectedStatus.decoration = BoxDecoration(
          color: primaryColor.withOpacity(0.6), borderRadius: borderRadius)
      ..highlightedStatus.decoration = BoxDecoration(
          color: surface.withOpacity(0.5), borderRadius: borderRadius);

    // cannot watch two notifiers simultaneity in a single widget
    // so warp in consumer for watching theme change
    return Stack(
      children: [
        Consumer<ThemeChangeNotifier>(
          builder: ((context, themeChangeNotifier, child) {
            // tabbed view uses custom theme and provide TabbedViewTheme.
            // need to watch theme change and rebuild TabbedViewTheme with new one

            return TabbedViewTheme(
              data: themeData,
              child: TabbedView(
                  controller: TabbedViewController(tabs),
                  contentBuilder: (_, index) {
                    if (Mobile.isPhone(context)) {
                      return readerAt(index, books);
                    } else {
                      return Container();
                    }
                  },
                  onTabClose: (index, tabData) {
                    tabsVisibility.remove(books[index]['book'].id);
                    context.read<OpenningBooksProvider>().remove(index: index);
                  },
                  onTabSelection: (selectedIndex) {
                    if (selectedIndex != null) {
                      context
                          .read<OpenningBooksProvider>()
                          .updateSelectedBookIndex(selectedIndex);
                    }
                  },
                  draggableTabBuilder:
                      (int tabIndex, TabData tab, Widget tabWidget) {
                    // tabWidget actually is a MouseRegion in the tabbed_view
                    // library. The following code is only used to make tabs
                    // selectable on "tap down" instead of "on tap" (which is
                    // "on tap down" + "on tap up").
                    //
                    final mr = tabWidget as MouseRegion;
                    final gd = mr.child as GestureDetector;

                    GestureDetector gestureDetector = GestureDetector(
                        onTapDown: (_) {
                          gd.onTap?.call();
                        },
                        child: gd.child);

                    MouseRegion mouseRegion = MouseRegion(
                        cursor: mr.cursor,
                        onHover: mr.onHover,
                        onExit: mr.onExit,
                        child: gestureDetector);

                    return Draggable<int>(
                        feedback: Material(
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(border: Border.all()),
                                child: Text(tab.text))),
                        data: tabIndex,
                        dragAnchorStrategy: (Draggable<Object> draggable,
                            BuildContext context, Offset position) {
                          return Offset.zero;
                        },
                        child: DragTarget(
                          builder: (
                            BuildContext context,
                            List<dynamic> accepted,
                            List<dynamic> rejected,
                          ) {
                            return mouseRegion;
                          },
                          onAccept: (int index) {
                            debugPrint('Will move $tabIndex to $index');
                            context
                                .read<OpenningBooksProvider>()
                                .swap(tabIndex, index);
                          },
                        ));
                  }),
            );
          }),
        ),
        if (!Mobile.isPhone(context)) getColumns(books)
      ],
    );
  }

  Widget getColumns(List<Map<String, dynamic>> books) {
    return Container(
      padding: const EdgeInsets.fromLTRB(1, 30, 1, 1),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: Iterable.generate(books.length)
              .map((i) {
                final isVisible = tabsVisibility[books[i]['uuid']] ?? false;
                if (isVisible) {
                  return Expanded(child: readerAt(i, books));
                } else {
                  return null;
                }
              })
              .where((element) => element != null)
              .cast<Widget>()
              .toList()),
    );
  }
}
