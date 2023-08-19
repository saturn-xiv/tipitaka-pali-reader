import 'package:intl/intl.dart';
import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/services/dao/bookmark_dao.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';

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
    bm.actionDate = formattedDate;
    bm.action = BookmarkAction.insert;
    bm.synced = 0;

    String sql = '''
        insert into bookmark (book_id, name, page_number, note, action, action_date, synced) 
        values ('${bm.bookID}','${bm.name}', ${bm.pageNumber},'${bm.note}','${bm.action}','${bm.actionDate}',${bm.synced})
        ''';

    final db = await _databaseHelper.database;
    return await db
        .rawInsert(sql); // Use ConflictAlgorithm.replace to handle conflicts
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
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT id, book_id, page_number, name, note, action, action_date, synced, sync_date
      From bookmark
      ''');

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
