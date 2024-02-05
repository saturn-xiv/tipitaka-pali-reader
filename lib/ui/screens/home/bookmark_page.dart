import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/bookmark_provider.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_repo.dart';
import 'package:tipitaka_pali/ui/dialogs/bookmark_cloud_transfer_dialog.dart';
import 'package:tipitaka_pali/ui/widgets/colored_text.dart';
import 'package:path/path.dart' as path;
import 'package:tipitaka_pali/ui/widgets/pali_text_view.dart';

import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';
import '../../../business_logic/models/bookmark.dart';
import '../../../business_logic/view_models/bookmark_page_view_model.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import '../../dialogs/confirm_dialog.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage>
    with WidgetsBindingObserver {
  bool _isCurrentlyMounted = true; // New variable to track mounted state

  @override
  void initState() {
    super.initState();
    Provider.of<BookmarkPageViewModel>(context, listen: false).fetchBookmarks();
    WidgetsBinding.instance.addObserver(this);
    _checkInternetConnectivity();
    _isCurrentlyMounted = true;
  }

  @override
  void dispose() {
    _isCurrentlyMounted = false; // Update mounted state
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleDialogClose() {
    if (mounted) {
      // Check if BookmarkPage is still mounted
      context.read<BookmarkPageViewModel>().refreshBookmarks();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInternetConnectivity();
    }
  }

  void _checkInternetConnectivity() async {
    bool hasInternet = await InternetConnection().hasInternetAccess;
    if (!hasInternet) {
      setState(() {
        Prefs.isSignedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // duplicate: already provided at app.dart
        // ChangeNotifierProvider<BookmarkPageViewModel>(
        //   create: (_) => BookmarkPageViewModel()..fetchBookmarks(),
        // ),
        ChangeNotifierProvider<BookmarkNotifier>(
          create: (_) => BookmarkNotifier(),
        ),
      ],
      child: Scaffold(
        appBar: BookmarkAppBar(onDialogClose: _handleDialogClose),
        // Rydmike proposal: Consider converting the Drawer on Home screen
        //    to a Widget and add it also to other top level screens.
        // drawer: Mobile.isPhone(context) ? AppDrawer(context) : null,
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
                        subtitle: PaliTextView(
                            "${bookmark.name}  --  ${bookmark.pageNumber.toString()}"),
                        onTap: () => vm.openBook(bookmark, context),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip:
                                  AppLocalizations.of(context)!.shareThisNote,
                              onPressed: () async {
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
      ),
    );
  }

  String localScript(BuildContext context, String s) {
    return PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: s);
  }

  Future<void> shareBookmarksAsFile(List<Bookmark> bookmarks) async {
    final String bookmarkJson = definitionToJson(bookmarks);
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/bookmarks.tprbmk');

    await file.writeAsString(bookmarkJson);
    Share.shareFiles([file.path], text: 'Here are my bookmarks!');
  }
}

class BookmarkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onDialogClose;

  const BookmarkAppBar({super.key, required this.onDialogClose});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Rydmike: Consider not having implicit back, as it will give idea that
      //  user can go back, but back leads out of app in this case.
      automaticallyImplyLeading: false,
      title: Text(AppLocalizations.of(context)!.bookmark),
      actions: [
        buildDropdownButton(context),
        getCloudButton(context),
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

  Widget buildDropdownButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'import') {
          doImport(context);
        } else if (value == 'export') {
          doExport(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(
                Icons.upload,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8.0),
              ColoredText(AppLocalizations.of(context)!.importBookmarks),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(
                Icons.download,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8.0),
              ColoredText(AppLocalizations.of(context)!.exportBookmarks),
            ],
          ),
        ),
      ],
      icon:
          const Icon(Icons.sd_storage_outlined), // Change to your desired icon
    );
  }

  doImport(BuildContext context) async {
    FilePickerResult? filename = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      lockParentWindow: true,
    );

    if (filename != null) {
      final DatabaseHelper databaseHelper = DatabaseHelper();
      final db = BookmarkDatabaseRepository(databaseHelper);

      File file = File(filename.files.single.path.toString());
      String content = await file.readAsString();
      List<Bookmark> importedBookmarks = definitionFromJson(content);
      for (Bookmark bm in importedBookmarks) {
        db.insert(bm);
      }
      // Refresh the bookmarks
      context.read<BookmarkPageViewModel>().refreshBookmarks();
    } else {
      // User canceled the picker
    }
  }

  doExport(BuildContext context) async {
    final List<Bookmark> bookmarks =
        context.read<BookmarkPageViewModel>().bookmarks;
    String bookmarksJson = definitionToJson(bookmarks);
    String? directory = await FilePicker.platform.getDirectoryPath(
      lockParentWindow: true,
    );
    if (directory != null) {
      final file = File(path.join(directory, "bookmarks_export.json"));

      // Write CSV to the file
      try {
        await file.writeAsString(bookmarksJson);
      } catch (e) {
        debugPrint('Error writing file: $e');
      }
    }
  }

  Widget getCloudButton(BuildContext context) {
    InternetConnection().hasInternetAccess.then((bInternet) {
      if (!bInternet) {
        Prefs.isSignedIn = false;
        // You can also add more code here to handle the scenario when there is no internet.
      } else {
        // Handle the scenario when there is internet.
      }
    });

    return (Prefs.isSignedIn)
        ? IconButton(
            icon: const Icon(Icons.cloud),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return BookmarkCloudTransferDialog();
                },
              ).then((_) => onDialogClose()); // Use the callback here
            })
        : const SizedBox.shrink();
  }
}
