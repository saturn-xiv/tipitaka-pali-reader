import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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

  String _highlightMDOccurrences(String source, String word) {
    if (word.isEmpty || !source.contains(word)) {
      return source;
    }
    return source.replaceAll(word, '**$word**');
  }

  final ValueNotifier<bool> isExporting = ValueNotifier<bool>(false);
  void _exportToAnki(BuildContext context) async {
    isExporting.value = true;
    List<List<dynamic>> rows = [];

    // Add flashcards data
    for (var card in cards) {
      String def = await dictionaryController.loadDefinition(card.word);
      rows.add([
        '<p><h3>${card.word}</h3>\n${_highlightOccurrences(card.context, card.word)}</p>',
        def
      ]);
    }

    String csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      textEndDelimiter: '"',
    ).convert(rows);

    // Pick directory
    String? dir = await FilePicker.platform.getDirectoryPath();
    if (dir != null) {
      // Create file in the chosen directory
      final file = File(path.join(dir, "anki_flashcards.csv"));

      // Write CSV to the file
      try {
        await file.writeAsString(csv);
      } catch (e) {
        debugPrint('Error writing file: $e');
      }

      isExporting.value = false;
      // File is saved. You can show a success message if you want.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Flashcards exported successfully!'),
        ),
      );
    }
  }

  _exportToRemNote(BuildContext context) async {
    isExporting.value = true;
    StringBuffer sb = StringBuffer();

    // Add flashcards data
    for (var card in cards) {
      String def = await dictionaryController.loadDefinition(card.word);
      BeautifulSoup bs = BeautifulSoup(def);
      // Find all 'details' elements.
      String defCard = "\n";
      List<Bs4Element> bs4s = bs.findAll("details");
      for (Bs4Element bs4 in bs4s) {
        if (bs4.find('summary') != null) {
          defCard += "\t\t- ";
          defCard += bs4.find('summary')!.getText();
          defCard += "\n";
        }
      }

      String front =
          "**${card.word}** \n\t-${_highlightMDOccurrences(card.context, card.word)}";
      sb.write(front);
      sb.write(defCard);
    }
    await Clipboard.setData(ClipboardData(text: sb.toString()));

    isExporting.value = false;

    // File is saved. You can show a success message if you want.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Text('Your Remnotes are ready to paste now!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Flashcards'),
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
                      style: const TextStyle(fontSize: 30),
                    ),
                    HtmlWidget(
                      _highlightOccurrences(
                          cards[index].context,
                          cards[index]
                              .word), // Highlight the word in the context
                    ),
                  ],
                ),
              ),
              frontWidget: FutureBuilder<String>(
                future: dictionaryController
                    .loadDefinition(cards[index].word), // your future operation
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // or some kind of loading widget
                  } else {
                    if (snapshot.hasError) {
                      return const Text('Error: loading definition');
                    } else {
                      return SingleChildScrollView(
                        child: HtmlWidget(
                          (snapshot.data!).isEmpty
                              ? "<p><h2>No Definition Found</h2></p>"
                              : snapshot.data!,
                        ),
                      );
                    }
                  }
                },
              ),
              width: 300,
              height: 400,
            );
          },
        ),
        floatingActionButton: buildSpeedDial(context));
  }

  SpeedDial buildSpeedDial(BuildContext context) {
    return SpeedDial(
      icon: Icons.download,
      label: const Text("Export"),
      activeIcon: Icons.close,
      //buttonSize: 56.0,
      visible: true,
      closeManually: false,
      renderOverlay: false,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      tooltip: 'Export',
      heroTag: 'speed-dial-hero-tag',
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        SpeedDialChild(
          child: Image.asset(
            'assets/images/anki.png',
            width: 34.0,
            height: 34.0,
            fit: BoxFit.cover,
          ),
          backgroundColor: Colors.white,
          label: 'Anki',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () => _exportToAnki(context),
        ),
        SpeedDialChild(
          child: Image.asset(
            'assets/images/remnote.jpg',
            width: 34.0,
            height: 34.0,
            fit: BoxFit.cover,
          ),
          backgroundColor: Colors.white,
          label: 'Remnote',
          labelStyle: const TextStyle(fontSize: 18.0),
          onTap: () => _exportToRemNote(context),
        ),
      ],
    );
  }
}
