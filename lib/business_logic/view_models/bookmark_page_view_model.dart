import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_sync_repo.dart';

import '../../ui/screens/home/openning_books_provider.dart';
import '../../ui/screens/reader/mobile_reader_container.dart';
import '../../utils/platform_info.dart';
import '../models/book.dart';
import '../models/bookmark.dart';

class BookmarkPageViewModel extends ChangeNotifier {
  BookmarkPageViewModel(this.repository);
  final BookmarkSyncRepo repository;

  List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;

  Future<void> fetchBookmarks() async {
    _bookmarks = await repository.getBookmarks();
    notifyListeners();
  }

  Future<void> delete(Bookmark bookmark) async {
    _bookmarks.remove(bookmark);
    await repository.delete(bookmark);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    _bookmarks.clear();
    await repository.deleteAll();
    notifyListeners();
  }

  void openBook(Bookmark bookmark, BuildContext context) async {
    final book = Book(id: bookmark.bookID, name: bookmark.name);
    final openningBookProvider = context.read<OpenningBooksProvider>();
    openningBookProvider.add(book: book, currentPage: bookmark.pageNumber, textToHighlight: bookmark.name);

    if (Mobile.isPhone(context)) {
      // Navigator.pushNamed(context, readerRoute,
      //     arguments: {'book': bookItem.book});
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MobileReaderContainer()));
    }
    // update bookmarks
    _bookmarks = await repository.getBookmarks();
    notifyListeners();
  }
}
