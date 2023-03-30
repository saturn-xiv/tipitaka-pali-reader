import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tipitaka_pali/data/constants.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

// Open Assets Database
  _initDatabase() async {
    // myLogger.i('initializing Database');
    late String dbPath;

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      dbPath = await getDatabasesPath();
    }
    if (Platform.isLinux || Platform.isWindows) {
      final docDirPath = await getApplicationSupportDirectory();
      dbPath = docDirPath.path;
    }
    var path = join(dbPath, DatabaseInfo.fileName);
    Prefs.databaseDirPath = dbPath;

    // myLogger.i('opening Database ...');
    return await openDatabase(path);
  }

  Future close() async {
    await _database?.close();
    _database = null;
  }

  Future<List<Map<String, Object?>>> backup({required String tableName}) async {
    final dbInstance = await database;
    final maps = await dbInstance.query(tableName);
    // print('maps: ${maps.length}');
    return maps;
  }

  // Future<List<Map<String, Object?>>> backupBookmarks() async {
  //   final dbInstance = await database;
  //   final maps = await dbInstance
  //       .query('bookmark', columns: <String>['book_id', 'page_number']);
  //   return maps;
  // }

  // Future<List<Map<String, Object?>>> backupDictionary() async {
  //   final dbInstance = await database;
  //   final maps = await dbInstance.query('dictionary_books',
  //       columns: <String>['id', 'name', 'user_order', 'user_choice']);
  //   return maps;
  // }

  Future<void> deleteDictionaryData() async {
    final dbInstance = await database;
    await dbInstance.delete('dictionary_books');
  }

  Future<void> restore(
      {required String tableName,
      required List<Map<String, Object?>> values}) async {
    final dbInstance = await database;
    for (final value in values) {
      await dbInstance.insert(tableName, value);
    }
  }

  Future<void> buildWordList(updateMessageCallback) async {
    final frequencyMap = <String, int>{};
    final dbInstance = await database;
    final mapsOfCount =
        await dbInstance.rawQuery('SELECT count(*) cnt FROM pages');
    final int count = mapsOfCount.first['cnt'] as int;
    int start = 1;
    int batchCount = 500; // Updated batch count
    while (start < count) {
      final maps = await dbInstance.rawQuery('''
          SELECT content FROM pages
          WHERE id BETWEEN $start AND ${start + batchCount}
          ''');

      for (var element in maps) {
        var content = element['content'] as String;
        content = _cleanText(content);
        content = content.toLowerCase();
        final words = content.split(' ');
        for (var word in words) {
          word = _cleanWord(word);
          if (word.isNotEmpty) {
            if (frequencyMap.containsKey(word)) {
              frequencyMap[word] = frequencyMap[word]! + 1;
            } else {
              frequencyMap[word] = 1;
            }
          }
        }
      }
      start += batchCount;
      updateMessageCallback(
          'Processing the word list: ${(start / count * 100).round()}%');
    }

    // writing to db
    updateMessageCallback('Writing wordlist to db ...');
    final before = DateTime.now();
    final length = frequencyMap.length;
    debugPrint('wordlist count: $length');
    final wordlist = frequencyMap.entries.toList();
    var chunks = <List<MapEntry<String, int>>>[];
    int chunkSize = 15000;
    for (var i = 0; i < length; i += chunkSize) {
      chunks.add(
          wordlist.sublist(i, i + chunkSize > length ? length : i + chunkSize));
    }
    int chunkIndex = 1;
    final chunkCount = chunks.length;
    for (var chunk in chunks) {
      var buffer = StringBuffer();
      buffer.write('INSERT INTO words (word, plain, frequency) VALUES ');
      for (var entry in chunk) {
        buffer.write(
            '("${entry.key}", "${_toPlain(entry.key)}", ${entry.value}), ');
      }
      await dbInstance
          .rawInsert(buffer.toString().substring(0, buffer.length - 2));
      updateMessageCallback(
          'Writing wordlist to db: ${((100 / chunkCount) * chunkIndex).round()}%');
      chunkIndex++;
    }

    final after = DateTime.now();
    debugPrint('saving wordlist time: ${after.difference(before).inSeconds}');
  }

  Future<bool> buildIndex() async {
    final dbInstance = await database;
    // building Index
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS "dictionary_index" ON "dictionary" ("word");');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS "dictionary_book_id_index" ON "dictionary" ("word"	ASC,"book_id"	ASC);');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS "dpd_headwords_index" ON "dpd_inflections_to_headwords" ("inflection"	ASC);');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS "dpd_index" ON "dpd" ("word","book_id");');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS "dpr_stem_index" ON "dpr_stem" ("word"	ASC);');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS "dpr_breakup_index" ON "dpr_breakup" ("word");');
    await dbInstance
        .execute('CREATE INDEX IF NOT EXISTS page_index ON pages ( bookid );');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS paragraph_index ON paragraphs ( book_id );');
    await dbInstance.execute(
        'CREATE INDEX IF NOT EXISTS paragraph_mapping_index ON paragraph_mapping ( base_page_number);');
    await dbInstance
        .execute('CREATE INDEX IF NOT EXISTS toc_index ON tocs ( book_id );');
    await dbInstance.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS word_index ON words ( "word" collate nocase, "plain" collate nocase);');

    return true;
  }

  Future<bool> buildFts(updateMessageCallback) async {
    final dbInstance = await database;
    await dbInstance
        .execute('''CREATE VIRTUAL TABLE IF NOT EXISTS fts_pages USING FTS4
         (id, bookid, page, content, paranum)''');

    final mapsOfCount =
        await dbInstance.rawQuery('SELECT count(*) cnt FROM pages');
    final int count = mapsOfCount.first['cnt'] as int;
    int start = 1;
    int batchCount = 500;
    while (start < count) {
      final maps = await dbInstance.rawQuery('''
          SELECT id, bookid, page, content, paranum FROM pages
          WHERE id BETWEEN $start AND ${start + batchCount}
          ''');

      Batch batch = dbInstance.batch();
      for (var element in maps) {
        // before populating to fts, need to remove html tag
        final value = <String, Object?>{
          'id': element['id'] as int,
          'bookid': element['bookid'] as String,
          'page': element['page'] as int,
          'content': _cleanText(element['content'] as String),
          'paranum': element['paranum'] as String,
        };
        batch.insert('fts_pages', value);
      }
      await batch.commit(noResult: true);
      start += batchCount;
      debugPrint('finished: $start rows populating');
      int percent = ((start / count) * 100).round();

      updateMessageCallback('Finished populating: $percent% of data');
    }

    return true;
  }

  String _cleanText(String text) {
    final regexHtmlTags = RegExp(r'<[^>]*>');
    text = text.replaceAll(regexHtmlTags, '');

    text = text.replaceAll('"', '');
    text = text.replaceAll("'", '');
    return text;
  }

  String _cleanWord(String word) {
    final reToken = RegExp(r'[^a-zāīūṅñṭḍṇḷṃ]');
    final cleanWord = word.replaceAll(reToken, '');
    return cleanWord;
  }

  final variations = {
    'a': RegExp(r'ā'),
    'u': RegExp(r'ū'),
    't': RegExp(r'ṭ'),
    'n': RegExp(r'[ñṇṅ]'),
    'i': RegExp(r'ī'),
    'd': RegExp(r'ḍ'),
    'l': RegExp(r'ḷ'),
    'm': RegExp(r'[ṁṃ]')
  };
  String _toPlain(String word) {
    var plain = word.toLowerCase().trim();
    variations.forEach((key, value) {
      plain = plain.replaceAll(value, key);
    });
    return plain;
  }
}
