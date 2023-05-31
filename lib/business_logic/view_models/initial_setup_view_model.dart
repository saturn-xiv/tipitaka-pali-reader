import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tipitaka_pali/data/constants.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class InitialSetupViewModel extends ChangeNotifier {
  final BuildContext _context;
  String _status = '';
  void updateMessageCallback(String msg) {
    _status = msg;
    notifyListeners();
  }

  InitialSetupViewModel(this._context);
  String get status => _status;

  Future<void> setUp(bool isUpdateMode) async {
    debugPrint('isUpdateMode : $isUpdateMode');

    late String databasesDirPath;

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      databasesDirPath = await getDatabasesPath();
    }
    if (Platform.isLinux || Platform.isWindows) {
      final docDirPath = await getApplicationSupportDirectory();
      databasesDirPath = docDirPath.path;
    }
    // final databasesDirPath = await getApplicationDocumentsDirectory();
    final dbFilePath = join(databasesDirPath, DatabaseInfo.fileName);

    final recents = <Map<String, Object?>>[];
    final bookmarks = <Map<String, Object?>>[];
    final dictionaryHistories = <Map<String, Object?>>[];
    final searchHistories = <Map<String, Object?>>[];
    final dictionaries = <Map<String, Object?>>[];

    // because a new db is copied.. the extension dpdgrammar is lost
    setDpdGrammarFlag(true);

    if (isUpdateMode) {
      // backuping user data to memory
      final DatabaseHelper databaseHelper = DatabaseHelper();
      recents.addAll(await databaseHelper.backup(tableName: 'recent'));
      bookmarks.addAll(await databaseHelper.backup(tableName: 'bookmark'));
      // backup history to memory
      try {
        dictionaryHistories.addAll(
            await databaseHelper.backup(tableName: 'dictionary_history'));
        searchHistories
            .addAll(await databaseHelper.backup(tableName: 'search_history'));
      } on DatabaseException catch (e) {
        // Todo: Handle the exception
        debugPrint('SQLite exception: $e');
      } catch (e) {
        debugPrint('Exception: $e');
      }

      //dictionaries
      //  .addAll(await databaseHelper.backup(tableName: 'dictionary_books'));

      //debugPrint('dictionary books: ${dictionaries.length}');
      await databaseHelper.close();
      // deleting old database file
    }

    await deleteDatabase(dbFilePath);

    // make sure the folder exists
    if (!await Directory(databasesDirPath).exists()) {
      debugPrint('creating db folder path: $databasesDirPath');
      try {
        await Directory(databasesDirPath).create(recursive: true);
      } catch (e) {
        debugPrint('$e');
      }
    }

    // copying new database from assets
    await _copyFromAssets(dbFilePath);

    final DatabaseHelper databaseHelper = DatabaseHelper();
    // restoring user data
    if (recents.isNotEmpty) {
      await databaseHelper.restore(tableName: 'recent', values: recents);
    }

    if (bookmarks.isNotEmpty) {
      await databaseHelper.restore(tableName: 'bookmark', values: bookmarks);
    }

// restore history from memory
    try {
      await databaseHelper.restore(
          tableName: 'dictionary_history', values: dictionaryHistories);
      await databaseHelper.restore(
          tableName: 'search_history', values: searchHistories);
    } on DatabaseException catch (e) {
      // Todo: Handle the exception
      debugPrint('SQLite exception: $e');
    } catch (e) {
      debugPrint('Exception: $e');
    }
    // dictionary_books table is semi-user data
    // need to delete before restoring
    if (dictionaries.isNotEmpty) {
      await databaseHelper.deleteDictionaryData();
      debugPrint('dictionary books: ${dictionaries.length}');
      await databaseHelper.restore(
          tableName: 'dictionary_books', values: dictionaries);
    }

    // save record to shared Preference
    Prefs.isDatabaseSaved = true;
    Prefs.databaseVersion = DatabaseInfo.version;

    _openHomePage();
  }

  Future<void> _copyFromAssets(String dbFilePath) async {
    final dbFile = File(dbFilePath);
    final timeBeforeCopy = DateTime.now();
    final int count = AssetsFile.partsOfDatabase.length;
    int partNo = 0;
    _status =
        "About to copy database to your \nlocal Application folder\n Approximate Size: ${count * 50} MB";
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 3000));
    for (String part in AssetsFile.partsOfDatabase) {
      // reading from assets
      // using join method on assets path does not work for windows
      final bytes = await rootBundle.load(
          '${AssetsFile.baseAssetsFolderPath}/${AssetsFile.databaseFolderPath}/$part');
      // appending to output dbfile
      await dbFile.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          mode: FileMode.append);
      int percent = ((++partNo / count) * 100).round();
      _status = "Finished copying $percent% of ~${count * 50} MB.";
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final timeAfterCopied = DateTime.now();
    debugPrint(
        'database copying time: ${timeAfterCopied.difference(timeBeforeCopy)}');

    // final isDbExist = await databaseExists(dbFilePath);
    // debugPrint('is db exist: $isDbExist');

    final timeBeforeIndexing = DateTime.now();

    // creating index tables
    _status = "building word list";
    notifyListeners();
    final DatabaseHelper databaseHelper = DatabaseHelper();

    await databaseHelper.buildWordList(updateMessageCallback);
    _status = "finished building word list";
    notifyListeners();

    _status = "building indexes";
    notifyListeners();
    final indexResult = await databaseHelper.buildIndex();
    if (indexResult == false) {
      // handle error
    }
    _status = "finidshed building indexes";
    notifyListeners();
    // creating fts table
    final ftsResult = await DatabaseHelper().buildFts(updateMessageCallback);
    if (ftsResult == false) {
      // handle error
    }

    final timeAfterIndexing = DateTime.now();
    //_indexStatus =help
    notifyListeners();

    debugPrint(
        'indexing time: ${timeAfterIndexing.difference(timeBeforeIndexing)}');
  }

  void _openHomePage() {
    Navigator.of(_context).popAndPushNamed('/home');
  }

  setDpdGrammarFlag(bool isOn) async {
    // if this function is called in setup.. that means the db does not have the
    // table.  It is unsure if this type of (commented out) query is supported in linux sqlflite
    // however, it is sure to not be included on this setup routine and it is sure to be turned
    // on during the install of extension.
    Prefs.isDpdGrammarOn = isOn;
/*  final dictionaryProvider =
      DictionarySerice(DictionaryDatabaseRepository(DatabaseHelper()));
  Prefs.isDpdGrammarOn = await dictionaryProvider.isDpdGrammarExist();
  */
  }
}
