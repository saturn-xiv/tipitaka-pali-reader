import 'package:firedart/auth/user_gateway.dart';
import 'package:flutter/material.dart';
import 'package:firedart/firedart.dart';
import 'package:tipitaka_pali/business_logic/models/bookmark.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class BookmarkFireRepository {
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
        data['id'] = doc.id; // Adding the document ID to the data map.
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
      var auth = FirebaseAuth.instance;
      User user = await auth.getUser();
      debugPrint('User: $user');
/*
      if (user.emailVerified == false) {
        debugPrint('Email not verified!');
        throw Exception('Email not verified!');
      }
*/
      var userBookmarksCollection = Firestore.instance
          .collection('users')
          .document(Prefs.email)
          .collection('bookmarks');

      await userBookmarksCollection.add({
        'bookID': bookmark.bookID,
        'note': bookmark.note,
        'page': bookmark.pageNumber,
        'action': bookmark.action,
        'actionDate': bookmark.actionDate,
        'syncDate': bookmark.syncDate,
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
          .document(bookmark.id);

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
