import 'package:tipitaka_pali/business_logic/models/sutta.dart';

import '../database/database_helper.dart';

abstract class SuttaRepository {
  Future<List<Sutta>> getAll();
}

class SuttaRepositoryDatabase implements SuttaRepository {
  final DatabaseHelper databaseProvider;
  // final String tableSutta = 'sutta';
  // final String tableBook = 'book';
  // final String columnName = 'name';
  // final String columnBookID = 'book_id';
  // final String columnBookName = 'book_name';
  // final String columnPageNumber = 'page_number';

  SuttaRepositoryDatabase(this.databaseProvider);

  @override
  Future<List<Sutta>> getAll() async {
    final db = await databaseProvider.database;
    var results = await db.rawQuery('''
SELECT suttas.name, book_id, books.name as book_name, page_number from suttas
INNER JOIN books on books.id = suttas.book_id
''');
    return results.map((e) => Sutta.fromMap(e)).toList();
  }
}
