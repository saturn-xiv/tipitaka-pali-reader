import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_fire_repo.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_repo.dart';

class BookmarkCloudTransferDialog extends StatefulWidget {
  @override
  _TransferDialogState createState() => _TransferDialogState();
}

class _TransferDialogState extends State<BookmarkCloudTransferDialog> {
  List<Bookmark> localBookmarks = [];
  List<Bookmark> cloudBookmarks = [];

  @override
  void initState() {
    super.initState();
    fetchBookmarks();
  }

  void fetchBookmarks() async {
    // Fetch local bookmarks
    localBookmarks =
        await BookmarkDatabaseRepository(DatabaseHelper()).getBookmarks();
    // Fetch cloud bookmarks
    cloudBookmarks = await BookmarkFireRepository().getBookmarks();
    setState(() {});
  }

  void downloadBookmark(Bookmark bookmark) async {
    // Add logic to write the bookmark to the local database
    await BookmarkDatabaseRepository(DatabaseHelper()).insert(bookmark);
    fetchBookmarks();
  }

  void deleteFromCloud(Bookmark bookmark) async {
    // Add logic to delete the bookmark from Firestore
    await BookmarkFireRepository().delete(bookmark);
    fetchBookmarks();
  }

  void transferToCloud(Bookmark bookmark) async {
    await BookmarkFireRepository().insert(bookmark);
    // Optionally, remove the bookmark from local after transfer
    // await BookmarkDatabaseRepository(DatabaseHelper()).delete(bookmark);
    fetchBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transfer Bookmarks'),
      content: Container(
        width: double.maxFinite, // Ensures the dialog takes full width
        child: Column(
          children: [
            Icon(Icons.sd_card),
            Flexible(
              child: Card(
                child: SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    //                  physics: NeverScrollableScrollPhysics(),
                    itemCount: localBookmarks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(localBookmarks[index].note),
                        trailing: IconButton(
                          icon: const Icon(Icons.cloud_upload),
                          onPressed: () =>
                              transferToCloud(localBookmarks[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Icon(Icons.cloud),
            Flexible(
              child: Card(
                child: SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    //                  physics: NeverScrollableScrollPhysics(),
                    itemCount: cloudBookmarks.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(cloudBookmarks[index].note),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cloud_download),
                              onPressed: () =>
                                  downloadBookmark(cloudBookmarks[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  deleteFromCloud(cloudBookmarks[index]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
