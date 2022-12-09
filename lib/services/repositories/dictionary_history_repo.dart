import 'package:tipitaka_pali/services/database/database_helper.dart';

import '../../business_logic/models/dictionary_history.dart';

abstract class DictionaryHistoryRepository {
  Future<int> insertOrReplace(DictionaryHistory DictionaryHistory);

  Future<int> delete(DictionaryHistory DictionaryHistory);

  Future<int> deleteAll();

  Future<List<DictionaryHistory>> getDictionaryHistory();
}

class DictionaryHistoryDatabaseRepository
    implements DictionaryHistoryRepository {
  DictionaryHistoryDatabaseRepository({required this.dbh});
  DatabaseHelper dbh;

  @override
  Future<int> insertOrReplace(DictionaryHistory dh) async {
    final db = await dbh.database;
    var result = await db
        .rawDelete("DELETE FROM dictionary_history WHERE word = '${dh.word}';");
    result = await db.rawInsert("INSERT INTO dictionary history (");
    return result;
  }

  @override
  Future<int> delete(DictionaryHistory dh) async {
    final db = await dbh.database;

    return await db
        .rawDelete("DELETE FROM dictionary_history WHERE word = '${dh.word}';");
  }

  @override
  Future<int> deleteAll() async {
    final db = await dbh.database;
    return await db.rawDelete("DELETE FROM dictionary_history';");
  }

  @override
  Future<List<DictionaryHistory>> getDictionaryHistory() async {
    final db = await dbh.database;

    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT word, context, date, book_id, page_number
      FROM dictionary_history
      ''');
    return maps.map((x) => DictionaryHistory.fromJson(x)).toList();
  }
}
