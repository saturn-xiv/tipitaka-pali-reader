import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/repositories/bookmark_repo.dart';

import '../../ui/screens/home/openning_books_provider.dart';
import '../../ui/screens/reader/mobile_reader_container.dart';
import '../../utils/platform_info.dart';
import '../models/book.dart';
import '../models/bookmark.dart';

class BookmarkPageViewModel extends ChangeNotifier {
  BookmarkPageViewModel();

  final repository = BookmarkDatabaseRepository(DatabaseHelper());

  List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;

  Future<void> fetchBookmarks() async {
    _bookmarks = await repository.getAllBookmark();
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

    // BUG FIX HACK  issue 217 https://github.com/bksubhuti/tipitaka-pali-reader/issues/217AND
    // highlighting words with numbers and small words interferes withthe
    // html code.  So this is a hack until we can do system based highlights
    String textToHighlight = bookmark.selectedText
        .split(' ') // Split the name into words
        .where((word) =>
            word.length >= 4 &&
            !word.contains(RegExp(
                r'\d'))) // Filter out words with less than 4 characters and words that contain numbers
        .join(' '); // Join the words back into a string

// Now call the function with the filtered text
    openningBookProvider.add(
        book: book,
        currentPage: bookmark.pageNumber,
        textToHighlight: textToHighlight);

    if (Mobile.isPhone(context)) {
      // Navigator.pushNamed(context, readerRoute,
      //     arguments: {'book': bookItem.book});
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MobileReaderContainer()));
    }
    // update bookmarks
    _bookmarks = await repository.getAllBookmark();
    notifyListeners();
  }

  void refreshBookmarks() async{
    await fetchBookmarks();
    notifyListeners();
  }
}
