import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/provider/bookmark_provider.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_sync_repo.dart';

import '../../../business_logic/models/bookmark.dart';
import '../../../business_logic/view_models/bookmark_page_view_model.dart';
import '../../../services/dao/bookmark_dao.dart';
import '../../../services/database/database_helper.dart';
import '../../dialogs/confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BookmarkPageViewModel>(
          create: (_) => BookmarkPageViewModel(
              BookmarkSyncRepo(DatabaseHelper(), BookmarkDao()))
            ..fetchBookmarks(),
        ),
        ChangeNotifierProvider<BookmarkNotifier>(
          create: (_) => BookmarkNotifier(),
        ),
      ],
      child: Scaffold(
        appBar: const BookmarkAppBar(),
        body: Consumer2<BookmarkPageViewModel, BookmarkNotifier>(
          builder: (context, vm, bn, child) {
            // Assuming BookmarkNotifier has a similar bookmarks list
            final bookmarks =
                vm.bookmarks; // You can also utilize 'bn.bookmarks' if needed
            return bookmarks.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.bookmark))
                : ListView.separated(
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return ListTile(
                        dense: true,
                        title: Text(bookmark.note),
                        subtitle: Text(localScript(context,
                            "${bookmark.name}  --  ${bookmark.pageNumber.toString()}")),
                        onTap: () => vm.openBook(bookmark, context),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip:
                                  AppLocalizations.of(context)!.shareThisNote,
                              onPressed: () {
                                Share.share(bookmark.toString(),
                                    subject: AppLocalizations.of(context)!
                                        .shareTitle);
                              },
                              icon: const Icon(Icons.share),
                            ),
                            IconButton(
                              onPressed: () => vm.delete(bookmark),
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                  );
          },
        ),
        floatingActionButton: Builder(
          builder: (innerContext) => FloatingActionButton(
            onPressed: () {
              //innerContext.read<BookmarkNotifier>().fetchBookmarks();
            },
            child: const Icon(Icons.refresh),
          ),
        ),
      ),
    );
  }

  String localScript(BuildContext context, String s) {
    return PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: s);
  }
}

class BookmarkAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BookmarkAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.bookmark),
      actions: [
        IconButton(
            tooltip: AppLocalizations.of(context)!.shareAllNotes,
            icon: const Icon(Icons.share),
            onPressed: () async {
              String bookMarkText = "";
              final List<Bookmark> bookmarks =
                  context.read<BookmarkPageViewModel>().bookmarks;
              for (var book in bookmarks) {
                bookMarkText += book.toString();
              }
              Share.share(bookMarkText,
                  subject: AppLocalizations.of(context)!.shareAllNotes);
            }),
        IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final result = await _getConfirmataion(context);
              if (result == OkCancelAction.ok) {
                context.read<BookmarkPageViewModel>().deleteAll();
              }
            }),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

  Future<OkCancelAction?> _getConfirmataion(BuildContext context) async {
    return await showDialog<OkCancelAction>(
        context: context,
        builder: (context) {
          return ConfirmDialog(
            title: AppLocalizations.of(context)!.confirmation,
            message: AppLocalizations.of(context)!.areSureDelete,
            okLabel: AppLocalizations.of(context)!.delete,
            cancelLabel: AppLocalizations.of(context)!.cancel,
          );
        });
  }
}
