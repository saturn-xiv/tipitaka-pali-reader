import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:tipitaka_pali/business_logic/models/toc_list_item.dart';
import 'package:tipitaka_pali/business_logic/view_models/toc_view_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TocDialog extends StatefulWidget {
  final String bookID;
  final int? currentPage;

  const TocDialog({
    Key? key,
    required this.bookID,
    this.currentPage,
  }) : super(key: key);

  @override
  State<TocDialog> createState() => _TocDialogState();
}

class _TocDialogState extends State<TocDialog> {
  int currentIndex = 0;
  AutoScrollController autoScrollController = AutoScrollController();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Stack(alignment: Alignment.center, children: [
            Text(
              AppLocalizations.of(context)!.table_of_contents,
              //style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ))
          ]),
          const Divider(color: Colors.grey),
          FutureBuilder<List<TocListItem>>(
              future: TocViewModel(widget.bookID).fetchTocListItems(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final listItems = snapshot.data!;
                  currentIndex = getIndex(widget.currentPage, listItems);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    autoScrollController.scrollToIndex(
                      currentIndex,
                      duration: const Duration(milliseconds: 100),
                      preferPosition: AutoScrollPosition.middle,
                    );
                  });
                  return Expanded(
                    child: ListView.separated(
                      controller: autoScrollController,
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        return AutoScrollTag(
                          key: ValueKey(index),
                          controller: autoScrollController,
                          index: index,
                          child: ListTile(
                            onTap: () =>
                                Navigator.pop(context, listItems[index].toc),
                            title: listItems[index].build(context),
                            selected: currentIndex == index,
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(
                            height: 1, indent: 16.0, endIndent: 16.0);
                      },
                    ),
                  );
                } else {
                  return const SizedBox(
                    child: CircularProgressIndicator(),
                  );
                }
              }),
        ],
      ),
    );
  }

  int getIndex(int? currentPage, List<TocListItem> listItems) {
    if (currentPage == null) return 0;

    // current page contains toc
    for (int i = 0; i < listItems.length; i++) {
      if (listItems[i].toc.pageNumber == currentPage) {
        return i;
      }
    }

    // current page does not contain toc
    for (int i = 0; i < listItems.length; i++) {
      if (listItems[i].toc.pageNumber > currentPage) {
        return i - 1;
      }
    }

    return 0;
  }
}
