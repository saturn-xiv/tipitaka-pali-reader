import 'package:intl/intl.dart';
import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class BookmarkRepository {
  Future<int> insert(Bookmark bookmark);

  Future<int> delete(Bookmark bookmark);

  Future<int> deleteAll();

  Future<List<Bookmark>> getBookmarks();
  Future<List<Bookmark>> getBookmarksAfter(String lastSyncDate);
}

class BookmarkDatabaseRepository extends BookmarkRepository {
  BookmarkDatabaseRepository(this._databaseHelper); //, this.dao);
  final DatabaseHelper _databaseHelper;
  //final BookmarkDao dao;

  @override
  Future<int> insert(Bookmark bm) async {
    String formattedDate = DateFormat('yyyyMMddHHmmss').format(DateTime.now());

    final db = await _databaseHelper.database;

    return await db.insert(
        'bookmark',
        {
          'book_id': bm.bookID,
          'name': bm.name,
          'page_number': bm.pageNumber,
          'note': bm.note,
          'selected_text': bm.selectedText,
        },
        conflictAlgorithm: ConflictAlgorithm
            .replace); // Use ConflictAlgorithm.replace to handle conflicts
  }

  @override
  Future<int> delete(Bookmark bookmark) async {
    final db = await _databaseHelper.database;
    String sql = '''
         Delete from bookmark 
         Where book_id = '${bookmark.bookID}' and page_number = ${bookmark.pageNumber} and note = '${bookmark.note}' and name = '${bookmark.name}'
         ''';
    return await db.rawDelete(sql);
  }

  @override
  Future<int> deleteAll() async {
    final db = await _databaseHelper.database;
    String sql = '''
         Delete from bookmark 
         ''';
    return await db.rawDelete(sql);
  }

  @override
  Future<List<Bookmark>> getBookmarks() async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps =
        await db.query('bookmark'); // Using the query helper method

    List<Bookmark> bookmarks = maps.map((x) => Bookmark.fromJson(x)).toList();
    return bookmarks;
  }

  @override
  Future<List<Bookmark>> getBookmarksAfter(String lastSyncDate) async {
    final db = await _databaseHelper.database;
    String sql = '''
      SELECT * 
      FROM bookmark
      WHERE sync_date < "$lastSyncDate" 
      ''';
    List<Map<String, dynamic>> maps = await db.rawQuery(sql);
    List<Bookmark> defs = maps.map((x) => Bookmark.fromJson(x)).toList();
    return maps.map((entry) => Bookmark.fromJson(entry)).toList();
  }
}
