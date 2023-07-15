import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flash_card/flash_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/controller/dictionary_controller.dart';
import '../../../business_logic/models/dictionary_history.dart';

class FlashCardsView extends StatelessWidget {
  final List<DictionaryHistory> cards;
  final DictionaryController dictionaryController;

  FlashCardsView(
      {Key? key, required this.cards, required this.dictionaryController})
      : super(key: key);

  String _highlightOccurrences(String source, String context) {
    if (context.isEmpty || !source.contains(context)) {
      return source;
    }
    return source.replaceAll(context, '<b>$context</b>');
  }

  void _exportToAnki(BuildContext context) async {
    List<List<dynamic>> rows = [];

    // Add flashcards data
    for (var card in cards) {
      String def = await dictionaryController.loadDefinition(card.word);
      rows.add([
        def,
        '<bold>${card.word}</bold><br>\n${_highlightOccurrences(card.context, card.word)}'
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Here you have your csv ready, you can save it to a file or share it
    // Implement saving or sharing of csv string...

    // Pick directory
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      // Create file in the chosen directory
      final file = File(path.join(
//          dir,
          "C:\\Users\\bksub\\OneDrive\\Desktop\\testing",
          "anki_flashcards.csv"));

      // Write CSV to the file
      try {
        await file.writeAsString(csv);
      } catch (e) {
        print('Error writing file: $e');
      }

      // File is saved. You can show a success message if you want.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flashcards exported successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
      ),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return FlashCard(
            backWidget: Container(
              height: 100,
              width: 100,
              child: Column(
                children: [
                  Text(
                    cards[index].word, // Display the word
                    style: TextStyle(fontSize: 30),
                  ),
                  HtmlWidget(
                    _highlightOccurrences(cards[index].context,
                        cards[index].word), // Highlight the word in the context
                  ),
                ],
              ),
            ),
            frontWidget: FutureBuilder<String>(
              future: dictionaryController
                  .loadDefinition(cards[index].word), // your future operation
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // or some kind of loading widget
                } else {
                  if (snapshot.hasError)
                    return const Text('Error: loading definition');
                  else
                    return SingleChildScrollView(
                      child: HtmlWidget(
                        (snapshot.data!).isEmpty
                            ? "<p><h2>No Definition Found</h2></p>"
                            : snapshot.data!,
                      ),
                    );
                }
              },
            ),
            width: 300,
            height: 400,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _exportToAnki(context),
        label: const Text('Export to Anki'),
        icon: const Icon(Icons.download),
      ),
    );
  }
}
