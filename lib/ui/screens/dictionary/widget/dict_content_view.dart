import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/business_logic/models/dpd_inflection.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';
import 'package:tipitaka_pali/services/repositories/dictionary_history_repo.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/widget/dictionary_history_view.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';
import 'package:tipitaka_pali/utils/pali_script.dart';
import 'package:tipitaka_pali/utils/pali_script_converter.dart';
import 'package:tipitaka_pali/utils/script_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../services/prefs.dart';
import '../controller/dictionary_controller.dart';
import '../controller/dictionary_state.dart';

class DictionaryContentView extends StatelessWidget {
  final ScrollController? scrollController;
  const DictionaryContentView({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final state = context.select<DictionaryController, DictionaryState>(
        (controller) => controller.dictionaryState);
    GlobalKey textKey = GlobalKey();

    return state.when(
        initial: () => ValueListenableBuilder(
            valueListenable: context.read<DictionaryController>().histories,
            builder: (_, histories, __) {
              return DictionaryHistoryView(
                histories: histories,
                onClick: (word) =>
                    context.read<DictionaryController>().onWordClicked(word),
                onDelete: (word) =>
                    context.read<DictionaryController>().onDelete(word),
                scrollController: scrollController,
              );
            }),
        loading: () => const SizedBox(
            height: 100, child: Center(child: CircularProgressIndicator())),
        data: (content) => SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(8.0),
              child: SelectionArea(
                child: GestureDetector(
                  onTapUp: (details) {
                    final box = textKey.currentContext?.findRenderObject()!
                        as RenderBox;
                    final result = BoxHitTestResult();
                    final offset = box.globalToLocal(details.globalPosition);
                    if (!box.hitTest(result, position: offset)) {
                      return;
                    }

                    for (final entry in result.path) {
                      final target = entry.target;
                      if (entry is! BoxHitTestEntry ||
                          target is! RenderParagraph) {
                        continue;
                      }

                      final p =
                          target.getPositionForOffset(entry.localPosition);
                      final text = target.text.toPlainText();
                      if (text.isNotEmpty && p.offset < text.length) {
                        final int offset = p.offset;
                        // print('pargraph: $text');
                        final charUnderTap = text[offset];
                        final leftChars = getLeftCharacters(text, offset);
                        final rightChars = getRightCharacters(text, offset);
                        final word = leftChars + charUnderTap + rightChars;
                        debugPrint(word);
                        writeHistory(
                            word,
                            AppLocalizations.of(context)!.dictionary,
                            1,
                            "dictionary");

                        // loading definitions
                        String romanWord = word;
                        Script inputScript = ScriptDetector.getLanguage(word);
                        if (inputScript != Script.roman) {
                          romanWord = PaliScript.getRomanScriptFrom(
                              script: inputScript, text: romanWord);
                        }

                        context
                            .read<DictionaryController>()
                            .onWordClicked(romanWord);
                      }
                    }
                  },
                  child: HtmlWidget(
                    key: textKey,
                    content,
                    customStylesBuilder: (element) {
                      if (element.classes.contains('dpdheader')) {
                        return {'font-weight:': 'bold'};
                      }
                      return null;
                    },
                    customWidgetBuilder: (element) {
                      final href = element.attributes['href'];
                      if (href != null) {
                        // Determine the link text
                        String linkText = href.contains("inflect")
                            ? "Inflect"
                            : href.contains("wikipedia")
                                ? "Wikipedia"
                                : "Submit a correction";

                        if (href.startsWith("inflect://")) {
                          // Return a small button for "inflect" links
                          int id =
                              int.parse(href.substring("inflect://".length));
                          return SizedBox(
                            height:
                                24, // Adjust height to make the button smaller
                            child: ElevatedButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                minimumSize: const Size(0,
                                    0), // Removes default minimum size constraints
                                tapTargetSize: MaterialTapTargetSize
                                    .shrinkWrap, // Reduces button padding
                              ),
                              onPressed: () {
                                debugPrint('Will inflect: $id');
                                showDeclension(context, id);
                              },
                              child: Text(
                                linkText,
                                style: const TextStyle(
                                    fontSize: 10), // Set font size to 10pt
                              ),
                            ),
                          );
                        } else {
                          // Use InkWell with 10pt font for other links
                          return InkWell(
                            onTap: () {
                              launchUrl(Uri.parse(href),
                                  mode: LaunchMode.externalApplication);
                              debugPrint('Will launch $href. --> $textKey');
                            },
                            child: Text(
                              linkText,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue,
                                fontSize: 10, // Set font size to 10pt
                              ),
                            ),
                          );
                        }
                      }
                      return null;
                    },
                    textStyle: TextStyle(
                        fontSize: Prefs.dictionaryFontSize.toDouble(),
                        color: context.watch<ThemeChangeNotifier>().isDarkMode
                            ? Colors.white
                            : Colors.black,
                        inherit: true),
                  ),
                ),
              ),
            ),
        noData: () => const SizedBox(
              height: 100,
              child: Center(child: Text('Not found')),
            ));
  }

  String superscripterUni(String text) {
    // Superscript using unicode characters.
    text = text.replaceAllMapped(
      RegExp(r'( )(\d)'),
      (Match match) => '\u200A${match.group(2)}',
    );
    text = text.replaceAll('0', '⁰');
    text = text.replaceAll('1', '¹');
    text = text.replaceAll('2', '²');
    text = text.replaceAll('3', '³');
    text = text.replaceAll('4', '⁴');
    text = text.replaceAll('5', '⁵');
    text = text.replaceAll('6', '⁶');
    text = text.replaceAll('7', '⁷');
    text = text.replaceAll('8', '⁸');
    text = text.replaceAll('9', '⁹');
    text = text.replaceAll('.', '·');
    return text;
  }

  showDeclension(BuildContext context, int wordId) async {
    var dictionaryController = context.read<DictionaryController>();
    DpdInflection? inflection =
        await dictionaryController.getDpdInflection(wordId);

    // prevent using context across asynch gaps
    if (!context.mounted) return;

    // not found, give user some feedback.
    if (inflection == null) {
      // Await the user's response from the dialog
      bool? shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.inflectionNoDataTitle),
          content: Text(AppLocalizations.of(context)!.inflectionNoDataMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true); // Return true to indicate navigation
              },
              child: const Text("Go to Extensions"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        ),
      );

      // Check the result and navigate if needed
      if (shouldNavigate == true) {
        if (!context.mounted) return;

        // Navigate to the desired page (e.g., DownloadView)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DownloadView(),
          ),
        );
      }

      // Return since there's no inflection data
      return;
    }
    debugPrint('Inflection: $inflection');

    String data = await DefaultAssetBundle.of(context)
        .loadString("assets/inflectionTemplates.json");
    List inflectionTemplates = jsonDecode(data);
    final template = inflectionTemplates
        .firstWhereOrNull((map) => map['pattern'] == inflection.pattern);
    if (template == null) {
      debugPrint('Could not find template...');
      return;
    }
    debugPrint('Template: $template');

    String html = "<table border='1' width='100%'>";
    var stem = inflection.stem.replaceAll(RegExp(r'[!*]'), '');
    debugPrint('STEM: "${inflection.stem}", "$stem"');

    template['data'].asMap().forEach((index, value) {
      int rowNumber = index;
      List<List<String>> rowData = (value as List)
          .map((e) => (e as List).map((item) => item as String).toList())
          .toList();
      html += "<tr>";

      for (var column in rowData.asMap().entries) {
        int columnNumber = column.key;
        List<String> cellData = column.value;

        if (rowNumber == 0) {
          if (columnNumber == 0) {
            html += "<th></th>";
          } else if (columnNumber % 2 == 1) {
            html += "<th>${cellData[0]}</th>";
          }
        } else if (rowNumber > 0) {
          if (columnNumber == 0) {
            html += "<th>${cellData[0]}</th>";
          } else if (columnNumber % 2 == 1 && columnNumber > 0) {
            String title = rowData[columnNumber + 1][0];

            for (var inflection in cellData) {
              if (inflection.isEmpty) {
                html += "<td title='$title'></td>";
              } else {
                //String wordClean = "$stem$inflection";
                String word;

                // if (allTipitakaWords.contains(wordClean)) {
                //   word = "$stem<b>$inflection</b>";
                // } else {
                //   word = "<span class='gray'>$stem<b>$inflection</b></span>";
                // }
                word = "$stem<b>$inflection</b>";

                if (cellData.length == 1) {
                  html += "<td title='$title'>$word</td>";
                } else {
                  if (inflection == cellData[0]) {
                    html += "<td title='$title'>$word<br>";
                  } else if (inflection != cellData.last) {
                    html += "$word<br>";
                  } else {
                    html += "$word</td>";
                  }
                }

                // if (!inflectionsList.contains(wordClean)) {
                //   inflectionsList.add(wordClean);
                // }
              }
            }
          }
        }
      }

      html += "</tr>";
    });

    html += "</table>";
    debugPrint(html);

    // =========================================================================
    // Change to use the HTML table
    // =========================================================================
    var useHtml = false;

    List<TableRow> rows =
        template['data'].asMap().entries.map<TableRow>((rowEntry) {
      int rowIndex = rowEntry.key;
      List<List<String>> row = (rowEntry.value as List)
          .map((e) => (e as List).map((item) => item as String).toList())
          .toList();

      return TableRow(
        children: row
            .asMap()
            .entries
            .map<Padding?>((entry) {
              int colIndex = entry.key;
              List<String> cell = entry.value;
              if (colIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(cell[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.orange)),
                );
              }
              if (colIndex % 2 != 1) {
                return null;
              }
              List<InlineSpan> spans = [];

              cell.asMap().forEach((index, value) {
                if (index > 0) {
                  spans.add(const TextSpan(text: '\n'));
                }
                if (rowIndex == 0) {
                  spans.add(TextSpan(
                      text: value,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange)));
                } else if (value.isNotEmpty) {
                  spans.add(TextSpan(text: stem));
                  spans.add(TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.bold)));
                }
              });

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text.rich(TextSpan(children: spans)),
              );
            })
            .where((cell) => cell != null)
            .cast<Padding>()
            .toList(),
      );
    }).toList();
    if (!context.mounted) return;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(superscripterUni(inflection.word)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: useHtml
                      ? HtmlWidget(
                          html,
                        )
                      : Table(
                          border: TableBorder.all(),
                          children: rows,
                        ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok))
              ],
            ));
  }

  String getLeftCharacters(String text, int offset) {
    RegExp wordBoundary = RegExp(r'[\s\.\-",\+]');
    StringBuffer chars = StringBuffer();
    for (int i = offset - 1; i >= 0; i--) {
      if (wordBoundary.hasMatch(text[i])) break;
      chars.write(text[i]);
    }
    return chars.toString().split('').reversed.join();
  }

  String getRightCharacters(String text, int offset) {
    RegExp wordBoundary = RegExp(r'[\s\.\-",\+]');
    StringBuffer chars = StringBuffer();
    for (int i = offset + 1; i < text.length; i++) {
      if (wordBoundary.hasMatch(text[i])) break;
      chars.write(text[i]);
    }
    return chars.toString();
  }
}

typedef WordChanged = void Function(String word);

// put in a common place?  also used in paliPageWidget
writeHistory(String word, String context, int page, String bookId) async {
  final DictionaryHistoryDatabaseRepository dictionaryHistoryRepository =
      DictionaryHistoryDatabaseRepository(dbh: DatabaseHelper());

  await dictionaryHistoryRepository.insert(word, context, page, bookId);
}

/*
class ClickableFactory extends WidgetFactory {
  final WordChanged? onClicked;
  ClickableFactory({this.onClicked});

  @override
  Widget? buildText(BuildMetadata meta, TextStyleHtml tsh, InlineSpan text) {
    if (meta.overflow == TextOverflow.clip && text is TextSpan) {
      if (text.text?.isNotEmpty == true) {
        String inlineText = text.text!;
        // inlineText = inlineText.replaceAll('+', ' + '); // add space between +
        // add space before + if not exist
        inlineText =
            inlineText.replaceAllMapped(RegExp(r'(?<!\s)\+'), (match) => ' +');
        // add space after + if not exist
        inlineText =
            inlineText.replaceAllMapped(RegExp(r'\+(?!\s)'), (match) => '+ ');
        // add space after . if not exist
        inlineText =
            inlineText.replaceAllMapped(RegExp(r'\.(?!\s)'), (match) => '. ');

        return CliakableWordTextView(
          text: inlineText,
          style: tsh.style,
          maxLines: meta.maxLines > 0 ? meta.maxLines : null,
          textAlign: tsh.textAlign ?? TextAlign.start,
          textDirection: tsh.textDirection,
          onWordTapped: (word, index) {
            onClicked?.call(word);
          },
        );
      }
    }

    return super.buildText(meta, tsh, text);
  }
}

class CliakableWordTextView extends StatefulWidget {
  final String text;
  final Function(String word, int? index)? onWordTapped;
  final bool highlight;
  final Color? highlightColor;
  final String alphabets;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign textAlign;
  final TextDirection textDirection;
  const CliakableWordTextView(
      {Key? key,
      required this.text,
      this.onWordTapped,
      this.highlight = true,
      this.highlightColor,
      this.alphabets = '[a-zA-Z]',
      this.style,
      this.maxLines,
      this.textAlign = TextAlign.start,
      this.textDirection = TextDirection.ltr})
      : super(key: key);

  @override
  State<CliakableWordTextView> createState() => _CliakableWordTextViewState();
}

class _CliakableWordTextViewState extends State<CliakableWordTextView> {
  int? selectedWordIndex;
  Color? highlightColor;

  @override
  void initState() {
    selectedWordIndex = -1;
    if (widget.highlightColor == null) {
      highlightColor = Colors.pink.withOpacity(0.3);
    } else {
      highlightColor = widget.highlightColor;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String> wordList = widget.text
        .replaceAll(RegExp(r'(\n)+'), "#")
        .trim()
        .split(RegExp(r'\s|(?<=#)'));

    return Text.rich(
      TextSpan(
        children: [
          for (int i = 0; i < wordList.length; i++)
            TextSpan(
              children: [
                TextSpan(
                    text: wordList[i].replaceAll("#", ""),
                    style: TextStyle(
                        backgroundColor:
                            selectedWordIndex == i && widget.highlight
                                ? highlightColor
                                : Colors.transparent),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        setState(() {
                          selectedWordIndex = i;
                        });
                        if (widget.onWordTapped != null) {
                          widget.onWordTapped!(
                              wordList[i]
                                  .trim()
                                  .replaceAll(
                                      RegExp(r'${widget.alphabets}'), "")
                                  .trim(),
                              selectedWordIndex);
                        }
                      }),
                wordList[i].contains("#")
                    ? const TextSpan(text: "\n\n")
                    : const TextSpan(text: " "),
              ],
            )
          // generateSpans()
        ],
      ),
      style: widget.style,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
    );
  }
}
*/