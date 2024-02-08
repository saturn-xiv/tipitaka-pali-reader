import 'package:firedart/auth/user_gateway.dart';
import 'package:flutter/material.dart';
import 'package:firedart/firedart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/utils/simple_encryptor.dart';

class BookmarkFireRepository {
  // Assuming AES-256, key should be 32 characters long
  final SimpleEncryptor cryptoHelper = SimpleEncryptor(Prefs.password);

  BookmarkFireRepository();

  // Ensure user is signed in before any operation
  Future<void> ensureSignedIn() async {
    if (FirebaseAuth.instance.isSignedIn) return;
    await signIn(Prefs.email, Prefs.password);
  }

  Future<List<Bookmark>> getBookmarks() async {
    List<Bookmark> bookmarks = [];
    try {
      await ensureSignedIn();

      var bookmarksCollection = Firestore.instance
          .collection('users')
          .document(Prefs.email)
          .collection('bookmarks');
      var documents = await bookmarksCollection.get();
      debugPrint("ok got records ${documents.length}");

      for (var doc in documents) {
        Map<String, dynamic> data = doc.map;
        data['id'] = doc.id;
        data['book_id'] = cryptoHelper.decryptText(data['book_id']);
        data['name'] = cryptoHelper.decryptText(data['name']);
        data['page_number'] =
            int.parse(cryptoHelper.decryptText(data['page_number']));
        data['note'] = cryptoHelper.decryptText(data['note']);
        data['selected_text'] = cryptoHelper.decryptText(data['selected_text']);
        bookmarks.add(Bookmark.fromJson(data));
      }
      return bookmarks;
      //    notifier.bookmarks = bookmarks;
    } catch (e) {
      debugPrint('Error fetching bookmarks: $e');
      // Optionally, you could provide a way to communicate this error to the user
      // For instance, using a state for `errorMessage` or similar.
      return bookmarks;
    }
  }

  Future<List<Bookmark>> getBookmarksAfter(String lastSyncDate) async {
    final query = Firestore.instance
        .collection('bookmarks')
        .where('syncDate', isGreaterThan: lastSyncDate);

    var documents = await query.get();
    final List<Bookmark> bookmarks = [];

    for (var doc in documents) {
      Map<String, dynamic> data = doc.map;
      data['id'] = doc.id; // Adding the document ID to the data map.
      bookmarks.add(Bookmark.fromJson(data));
    }
    return bookmarks;
  }

  Future<void> signIn(String email, String password) async {
    try {
      const projectId = "tipitaka-pali-reader-firestore";
      await dotenv.load();
      final apiKey = dotenv.env['FIREBASE_API_KEY'];

      if (!FirebaseAuth.initialized) {
        // ensure the app is initialized.
        FirebaseAuth.initialize(apiKey!, VolatileStore());
        Firestore.initialize(projectId);
      }
      var auth = FirebaseAuth.instance;
      await auth.signIn(email, password);
      debugPrint('Successfully signed in!');
      Prefs.isSignedIn = true;
      Prefs.email = email;
      Prefs.password = password;
    } catch (e) {
      debugPrint('Error during sign-in: $e');
      rethrow; // Optionally rethrow to handle the error on the UI side.
    }
  }

  Future<int> insert(Bookmark bookmark) async {
    try {
      ensureSignedIn();
      var auth = FirebaseAuth.instance;
      User user = await auth.getUser();
      debugPrint('User: $user');

      var userBookmarksCollection = Firestore.instance
          .collection('users')
          .document(Prefs.email)
          .collection('bookmarks');

      await userBookmarksCollection.add({
        'book_id': cryptoHelper.encryptText(bookmark.bookID),
        'note': cryptoHelper.encryptText(bookmark.note),
        'page_number': cryptoHelper.encryptText(bookmark.pageNumber.toString()),
        'selected_text': cryptoHelper.encryptText(bookmark.selectedText),
        'name': cryptoHelper.encryptText(bookmark.name),
      });
      return 1;
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
      rethrow; // Optionally rethrow to handle the error on the UI side.
    }
  }

  Future<int> delete(Bookmark bookmark) async {
    try {
      await ensureSignedIn();

      // Get reference to the specific bookmark
      var bookmarkRef = Firestore.instance
          .collection('users')
          .document(Prefs.email)
          .collection('bookmarks')
          .document(bookmark.id.toString());

      // Delete the bookmark
      await bookmarkRef.delete();
      debugPrint('Bookmark deleted!');
      return 1;
    } catch (e) {
      debugPrint('Error during deletion: $e');
      rethrow; // Optionally rethrow to handle the error on the UI side.
    }
  }

  Future<int> deleteAll() async {
    try {
      await ensureSignedIn();

      // Get reference to all bookmarks
      var bookmarksCollection = Firestore.instance
          .collection('users')
          .document(Prefs.email)
          .collection('bookmarks');

      var documents = await bookmarksCollection.get();

      for (var doc in documents) {
        await doc.reference.delete();
      }

      debugPrint('All bookmarks deleted!');
      return 1;
      // Clear the local list
//      _bookmarks.clear();
//      notifyListeners();
    } catch (e) {
      debugPrint('Error during batch deletion: $e');
      rethrow; // Optionally rethrow to handle the error on the UI side.
    }
  }
}
