import 'package:collection/collection.dart';
import 'package:flutter/rendering.dart';
import 'package:html/dom.dart' as dom;

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tipitaka_pali/providers/font_provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/script_language_provider.dart';
import 'package:tipitaka_pali/utils/font_utils.dart';
import 'package:tipitaka_pali/utils/platform_info.dart';

import '../../../../data/constants.dart';
import '../../../../services/provider/theme_change_notifier.dart';
import '../../../../utils/pali_script.dart';
import '../../../../utils/pali_script_converter.dart';
import '../../../widgets/custom_text_selection_control.dart';
import '../controller/reader_view_controller.dart';

class PaliPageWidget extends StatefulWidget {
  final int pageNumber;
  final String htmlContent;
  final Script script;
  final String? highlightedWord;
  final String? searchText;
  final int? pageToHighlight;
  final Function(String clickedWord)? onClick;
  final Function(String clickedWord)? onSearch;
  const PaliPageWidget({
    Key? key,
    required this.pageNumber,
    required this.htmlContent,
    required this.script,
    this.highlightedWord,
    this.onClick,
    this.onSearch,
    this.searchText,
    this.pageToHighlight,
  }) : super(key: key);

  @override
  State<PaliPageWidget> createState() => _PaliPageWidgetState();
}

final nonPali = RegExp(r'[^a-zāīūṅñṭḍṇḷṃ]+', caseSensitive: false);

class PaliWidgetFactory extends WidgetFactory {}

class _PaliPageWidgetState extends State<PaliPageWidget> {
  final _myFactory = PaliWidgetFactory();
  String? highlightedWord;
  int? highlightedWordIndex;

  final GlobalKey _textKey = GlobalKey();
  int? _pageToHighlight;

  @override
  void initState() {
    super.initState();
    highlightedWord = widget.highlightedWord;
    _pageToHighlight = widget.pageToHighlight;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myFactory.onTapUrl('#goto');
    });
  }

  int findOccurrencesBefore(String word, RenderParagraph target) {
    List<Element> richTexts = [];
    void pickRichTexts(Element element) {
      if (element.widget is RichText) {
        richTexts.add(element);
      }
      element.visitChildren(pickRichTexts);
    }
    _textKey.currentContext?.visitChildElements((element) {
      pickRichTexts(element);
    });

    int occurrencesBefore = 0;
    for (final rte in richTexts) {
      if (rte.renderObject == target) {
        break;
      }
      final paragraphText = (rte.widget as RichText).text.toPlainText();
      final matchesInParagraph = word.allMatches(paragraphText).length;
      occurrencesBefore += matchesInParagraph;
    }
    return occurrencesBefore;
  }

  @override
  Widget build(BuildContext context) {
    int fontSize = context.watch<ReaderFontProvider>().fontSize;
    String html = _formatContent(widget.htmlContent, widget.script, context);
    final fontName = FontUtils.getfontName(
        script: context.read<ScriptLanguageProvider>().currentScript);

    final child = Container(
      color: Colors.transparent,
      child: GestureDetector(
        onTapUp: (details) {
          final box = _textKey.currentContext?.findRenderObject()! as RenderBox;

          final result = BoxHitTestResult();
          final offset = box.globalToLocal(details.globalPosition);
          if (!box.hitTest(result, position: offset)) {
            return;
          }

          for (final entry in result.path) {
            final target = entry.target;
            if (entry is! BoxHitTestEntry || target is! RenderParagraph) {
              continue;
            }

            final p = target.getPositionForOffset(entry.localPosition);
            final text = target.text.toPlainText();

            debugPrint('${_textKey.currentContext?.widget}');
            if (text.isNotEmpty && p.offset < text.length) {
              final int offset = p.offset;
              final charUnderTap = text[offset];
              final leftChars = getLeftCharacters(text, offset);
              final rightChars = getRightCharacters(text, offset);
              final word = leftChars + charUnderTap + rightChars;

              final textBefore = text.substring(0, p.offset - leftChars.length);
              final occurrencesInTextBefore = word.allMatches(textBefore).length;
              final wordIndex = findOccurrencesBefore(word, target) + occurrencesInTextBefore;

              if (word == highlightedWord && highlightedWordIndex == wordIndex) {
                setState(() {
                  highlightedWord = null;
                  highlightedWordIndex = null;
                  _pageToHighlight = null;
                });
              } else {
                setState(() {
                  widget.onClick?.call(word);
                  highlightedWord = word;
                  highlightedWordIndex = wordIndex;

                  _pageToHighlight = widget.pageNumber;
                });
              }
            }
          }
        },
        child: HtmlWidget(
          key: _textKey,
          html,
          factoryBuilder: () => _myFactory,
          textStyle: TextStyle(
              fontSize: fontSize.toDouble(),
              inherit: true,
              fontFamily: fontName),
          customStylesBuilder: (element) {
            // if (element.className == 'title' ||
            //     element.className == 'book' ||
            //     element.className == 'chapter' ||
            //     element.className == 'subhead' ||
            //     element.className == 'nikaya') {
            //   return {
            //     'text-align': 'center',
            //     // 'text-decoration': 'none',
            //   };
            // }
            if (element.localName == 'a') {
              // print('found a tag: ${element.outerHtml}');
              final isHighlight =
                  element.parent!.className.contains('search-highlight') ==
                      true;
              if (isHighlight) {
                return {'color': '#000', 'text-decoration': 'none'};
              }

              if (context.read<ThemeChangeNotifier>().isDarkMode) {
                return {
                  'color': 'white',
                  'text-decoration': 'none',
                };
              } else {
                return {
                  'color': 'black',
                  'text-decoration': 'none',
                };
              }
            }

            if (element.className == 'highlighted') {
              String styleColor = (Prefs.darkThemeOn) ? "white" : "black";
              Color c = Theme.of(context).primaryColorLight;
              return {
                'background': 'rgb(${c.red},${c.green},${c.blue})',
                'color': styleColor,
              };
            }
            // no style
            return {'text-decoration': 'none'};
          },
          onTapUrl: (word) {
            if (widget.onClick != null) {
              // #goto is used for scrolling to selected text
              if (word != '#goto') {
                setState(() {
                  highlightedWord = word;
                  widget.onClick!(word);
                });
              }
            }
            return false;
          },
        ),
      ),
    );

    if (!Mobile.isPhone(context)) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectionArea(
        focusNode: FocusNode(
          canRequestFocus: true,
        ),
        selectionControls: FlutterSelectionControls(
          toolBarItems: [
            ToolBarItem(
              item: const Text('Copy'),
              itemControl: ToolBarItemControl.copy,
            ),
            ToolBarItem(
              item: const Text('Select All'),
              itemControl: ToolBarItemControl.selectAll,
            ),
            ToolBarItem(
              item: const Text('Search'),
              onItemPressed: (selectedText) {
                widget.onSearch?.call(selectedText);
              },
            ),
            ToolBarItem(
              item: const Text('Share'),
              onItemPressed: (selectedText) {
                // do sharing
                Share.share(selectedText, subject: 'Pāḷi text from TPR');
              },
            ),
          ],
        ),
        // clicking on blank area in html widget lose focus, and it is normal.
        // Container Widget with color can be used to acquire foucs
        // The color value is required for this container in order to acquire focus.
        child: child,
      ),
    );
  }

  String _formatContent(String content, Script script, BuildContext context) {
    content = _removeHiddenTags(content);

    if (highlightedWord != null &&
        _pageToHighlight != null &&
        _pageToHighlight == widget.pageNumber) {
      content = _addHighlight(content, highlightedWord!);
    }

    if (!Prefs.isShowAlternatePali) {
      content = _removeAlternatePali(content);
    }

    if (widget.searchText?.isNotEmpty == true) {
      content = _addHighlight2(content, '${widget.searchText}', context);
    }
    // content = _makeClickable(content, script);
    content = _changeToInlineStyle(content);
    content = _formatWithUserSetting(content);
    return content;
  }

  String _removeHiddenTags(String content) {
    return content.replaceAll(RegExp(r'<a name="para[^"]*">'), '');
  }

  String _removeAlternatePali(String content) {
    // format of alternate pali
    // <span class="note">[bhagavāti (syā.), dī. ni. 1.157, abbhuggatākārena pana sameti]</span>
    return content.replaceAll(RegExp(r'<span class="note">\[.+?\]</span>'), '');
  }

  String _addHighlight2(
      String content, String textToHighlight, BuildContext context) {
    final rvc = Provider.of<ReaderViewController>(context, listen: false);
    final soup = BeautifulSoup(content);
    final isDark = context.read<ThemeChangeNotifier>().isDarkMode;
    final textColor = isDark ? '#000' : '#000';
    final borderColor = isDark ? '#6bb8ff' : '#000';
    final bgColor = isDark ? '#2994ff' : '#a6d2ff';

    List<ReplaceResult> toReplace = [];
    for (final node in (soup.body?.nodes ?? [])) {
      _highlightNode(node, textToHighlight, toReplace, textColor);
    }

    final highlightAll = rvc.highlightEveryMatch.value;
    var highlightIndex = 0;
    toReplace.forEachIndexed((index, result) {
      for (final newNode in result.newNodes) {
        if (widget.pageNumber == rvc.currentPage.value &&
            newNode.data.contains('data-is-highlighted')) {
          final si = rvc.searchIndexes[rvc.currentSearchResult.value - 1];
          if (highlightIndex == si.index) {
            newNode.attributes['style'] =
                'background: $bgColor; color: $textColor; border: 1px solid $borderColor;';
          } else if (!highlightAll) {
            newNode.attributes['style'] = 'border: 1px solid transparent;';
          }
          highlightIndex++;
        }

        result.node.parent?.insertBefore(newNode, result.node);
      }

      result.node.remove();
    });

    return soup.toString();
  }

  _highlightNode(dom.Node node, String textToHighlight,
      List<ReplaceResult> toReplace, String textColor) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      if (node.text == null ||
          node.text?.isEmpty == true ||
          node.text?.contains(textToHighlight) == false) {
        return;
      }

      final replace =
          '<span style="background-color: #FFE959 !important; color: $textColor; border: 1px solid #FFE959;" class="search-highlight" data-is-highlighted="true">$textToHighlight</span>';
      final replaced = (node.text ?? '').replaceAll(textToHighlight, replace);
      final highlighted = BeautifulSoup(replaced);

      List<dom.Node> newNodes =
          (highlighted.body?.nodes ?? []).toList(growable: false).cast();
      toReplace.add(ReplaceResult(node, newNodes));
    } else {
      for (final nodeChild in node.nodes) {
        _highlightNode(nodeChild, textToHighlight, toReplace, textColor);
      }
    }
  }

  String _makeClickable(String content, Script script) {
    // pali word not inside html tag
    // final regexPaliWord = RegExp(r'[a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]+(?![^<>]*>)');
    final regexPaliWord = _getPaliWordRegexp(script);
    return content.replaceAllMapped(regexPaliWord,
        (match) => '<a href="${match.group(0)}">${match.group(0)}</a>');
    /*
    final regexHtmlTag = RegExp(r'<[^>]+>');
    final regexPaliWord = RegExp(r'([a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]+)');
    final matches = regexHtmlTag.allMatches(content);

    var formattedContent = '';
    for (var i = 0, length = matches.length; i < length - 1; i++) {
      final curretTag = matches.elementAt(i);
      final nextTag = matches.elementAt(i + 1);
      // add current tag to formatted content
      formattedContent += content.substring(curretTag.start, curretTag.end);
      if (curretTag.end == nextTag.start) continue; // no text data
      // extract text data
      var text = content.substring(curretTag.end, nextTag.start);
      // add a tag to every word to make clickable
      text = text.replaceAllMapped(regexPaliWord, (match) {
        String word = match.group(0)!;
        return '<a href="$word">$word</a>';
      });
      // add text to formatted context
      formattedContent += text;
    }
    // add last tag to formatted content
    formattedContent += content.substring(matches.last.start);

    return formattedContent;
    */
  }

  String _changeToInlineStyle(String content) {
    String styleColor = (Prefs.darkThemeOn) ? "white" : "black";
    final styleMaps = <String, String>{
      r'class="bld"': 'style="font-weight:bold; color: $styleColor;"',
      r'class="t5"': 'style="font-weight:bold; color: $styleColor;"',
      r'class="t1"': 'style=" color: $styleColor;"',
      r'class="t3"':
          'style="font-size: 1.7em;font-weight:bold; color: $styleColor;"',
      r'class="t2"':
          'style="font-size: 1.7em;font-weight:bold; color: $styleColor;"',
      r'class="th31"':
          'style="font-size: 1.7em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="centered"': 'style="text-align:center;color: $styleColor;"',
      r'class="paranum"': 'style="font-weight: bold; color: $styleColor;"',
      r'class="indent"':
          'style="text-indent:1.3em;margin-left:2em; color: $styleColor;"',
      r'class="bodytext"': 'style="text-indent:1.3em;color: $styleColor;"',
      r'class="unindented"': 'style="color: $styleColor;"',
      r'class="noindentbodytext"': 'style="color: $styleColor;"',
      r'class="book"':
          'style="font-size: 1.9em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="chapter"':
          'style="font-size: 1.7em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="nikaya"':
          'style="font-size: 1.6em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="title"':
          'style="font-size: 1.3em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="subhead"':
          'style="font-size: 1.6em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="subsubhead"':
          'style="font-size: 1.6em; text-align:center; font-weight: bold; color: $styleColor;"',
      r'class="gatha1"': r'style="margin-bottom: 0em; margin-left: 5em;"',
      r'class="gatha2"': r'style="margin-bottom: 0em; margin-left: 5em;"',
      r'class="gatha3"': r'style="margin-bottom: 0em; margin-left: 5em;"',
      r'class="gathalast"': r'style="margin-bottom: 1.3em; margin-left: 5em;"',
      r'class="pageheader"': r'style="font-size: 0.9em; color: deeppink;"',
      r'class="note"': r'style="font-size: 0.8em; color: gray;"',
      r'class = "highlightedSearch"':
          r'style="background: #FFE959; color: #000;"',
      // r'class="highlighted"':
      //     r'style="background: rgb(255, 114, 20); color: white;"',
    };

    styleMaps.forEach((key, value) {
      content = content.replaceAll(key, value);
    });
    //debugPrint(content);
    return content;
  }

  RegExp _getPaliWordRegexp(Script script) {
    // only alphabets used for pali
    // no digit , no puntutation
    switch (script) {
      case Script.myanmar:
        return RegExp('[\u1000-\u103F]+(?![^<>]*>)');
      case Script.roman:
        return RegExp(r'[a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]+(?![^<>]*>)');
      case Script.sinhala:
        return RegExp('[\u0D80-\u0DDF\u0DF2\u0DF3]+(?![^<>]*>)');
      case Script.devanagari:
        return RegExp('[\u0900-\u097F]+(?![^<>]*>)');
      case Script.thai:
        return RegExp('[\u0E00-\u0E7F\uF700-\uF70F]+(?![^<>]*>)');
      case Script.laos:
        return RegExp('[\u0E80-\u0EFF]+(?![^<>]*>)');
      case Script.khmer:
        return RegExp('[\u1780-\u17FF]+(?![^<>]*>)');
      case Script.bengali:
        return RegExp('[\u0980-\u09FF]+(?![^<>]*>)');
      case Script.gurmukhi:
        return RegExp('[\u0A00-\u0A7F]+(?![^<>]*>)');
      case Script.taitham:
        return RegExp('[\u1A20-\u1AAF]+(?![^<>]*>)');
      case Script.gujarati:
        return RegExp('[\u0A80-\u0AFF]+(?![^<>]*>)');
      case Script.telugu:
        return RegExp('[\u0C00-\u0C7F]+(?![^<>]*>)');
      case Script.kannada:
        return RegExp('[\u0C80-\u0CFF]+(?![^<>]*>)');
      case Script.malayalam:
        return RegExp('[\u0D00-\u0D7F]+(?![^<>]*>)');
// actual code block [0x11000, 0x1107F]
// need check
      case Script.brahmi:
        return RegExp('[\uD804\uDC00-\uDC7F]+(?![^<>]*>)');
      case Script.tibetan:
        return RegExp('[\u0F00-\u0FFF]+(?![^<>]*>)');
// actual code block [0x11000, 0x1107F]
//need check
      case Script.cyrillic:
        return RegExp('[\u0400-\u04FF\u0300-\u036F]+(?![^<>]*>)');

      default:
        return RegExp(r'[a-zA-ZāīūṅñṭḍṇḷṃĀĪŪṄÑṬḌHṆḶṂ]+(?![^<>]*>)');
    }
  }

  String _formatWithUserSetting(String pageContent) {
    // return pages[index].content;

    // if (tocHeader != null) {
    //   pageContent = addIDforScroll(pageContent, tocHeader!);
    // }

    // showing page number based on user settings
    var publicationKeys = <String>['P', 'T', 'V'];
    if (!Prefs.isShowPtsNumber) publicationKeys.remove('P');
    if (!Prefs.isShowThaiNumber) publicationKeys.remove('T');
    if (!Prefs.isShowVriNumber) publicationKeys.remove('V');

    if (publicationKeys.isNotEmpty) {
      for (var publicationKey in publicationKeys) {
        final publicationFormat =
            RegExp('(<a name="$publicationKey(\\d+)\\.(\\d+)">)');
        pageContent = pageContent.replaceAllMapped(publicationFormat, (match) {
          final volume = match.group(2)!;
          // remove leading zero from page number
          final pageNumber = int.parse(match.group(3)!).toString();
          return '${match.group(1)}[$publicationKey $volume.$pageNumber]';
        });
      }
    }

    return '''
            <p style="color:brown;text-align:right;">${_getScriptPageNumber(widget.pageNumber)}</p>
            <div id="page_content">
              $pageContent
            </div>
    ''';
  }

  String _getScriptPageNumber(int pageNumber) {
    return PaliScript.getScriptOf(
      script: context.watch<ScriptLanguageProvider>().currentScript,
      romanText: (pageNumber.toString()),
    );
  }

  String _addHighlight(String content, String textToHighlight,
      {highlightClass = "highlighted", addId = true}) {

    final singleHighlight = true;

    if (singleHighlight) {
      final highlighted = '<span class = "$highlightClass">$textToHighlight</span>';
      Match match = textToHighlight.allMatches(content).elementAt(highlightedWordIndex ?? 0);
      return content.replaceRange(match.start, match.end, highlighted);
    }

    // TODO - optimize highlight for some query text

    textToHighlight = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: textToHighlight);

    if (!textToHighlight.contains(' ')) {
      final pattern = RegExp('(?<=[\\s", ])$textToHighlight(?=[\\s", ])');
      if (content.contains(pattern)) {
        final replace =
            '<span class = "$highlightClass">$textToHighlight</span>';
        content = content.replaceAll(pattern, replace);

        // adding id to scroll
        // content = content.replaceFirst('<span class = "highlighted">',
        //     '<span id="$kGotoID" class="highlighted">');
        return content;
      }
    }

    final words = textToHighlight.trim().split(' ');
    for (final word in words) {
      if (content.contains(word)) {
        final String replace = '<span class = "$highlightClass">$word</span>';
        content = content.replaceAll(word, replace);
      } else {
        // bolded word case
        // Log.d("if not found highlight", "yes");
        // removing ti (တိ) at end
        String trimmedWord = word.replaceAll(RegExp(r'(nti|ti)$'), '');
        // print('trimmedWord: $trimmedWord');
        final replace = '<span class = "$highlightClass">$trimmedWord</span>';

        content = content.replaceAll(trimmedWord, replace);
      }
      //
    }

    if (addId) {
      // adding id to scroll
      content = content.replaceFirst('<span class = "$highlightClass">',
          '<span id="$kGotoID" class="$highlightClass">');
    }

    return content;
  }

  String addIDforScroll(String content, String tocHeader) {
    String tocHeaderWithID = '<span id="$kGotoID">$tocHeader</span>';
    content = content.replaceAll(tocHeader, tocHeaderWithID);

    return content;
  }

  String getLeftCharacters(String text, int offset) {
    StringBuffer chars = StringBuffer();
    for (int i = offset - 1; i >= 0; i--) {
      if (nonPali.hasMatch(text[i])) break;
      chars.write(text[i]);
    }
    return chars.toString().split('').reversed.join();
  }

  String getRightCharacters(String text, int offset) {
    StringBuffer chars = StringBuffer();

    for (int i = offset + 1; i < text.length; i++) {
      if (nonPali.hasMatch(text[i])) break;
      chars.write(text[i]);
    }
    return chars.toString();
  }
}

class _MyFactory extends WidgetFactory {
  /// Controls whether text is rendered with [SelectableText] or [RichText].
  ///
  /// Default: `true`.
  bool get selectableText => false;

  /// The callback when user changes the selection of text.
  ///
  /// See [SelectableText.onSelectionChanged].
  SelectionChangedCallback? get selectableTextOnChanged => null;

  @override
  Widget? buildText(BuildMetadata meta, TextStyleHtml tsh, InlineSpan text) {
    if (meta.overflow == TextOverflow.clip && text is TextSpan) {
      return Text.rich(
        text,
        style: tsh.style,
        maxLines: meta.maxLines > 0 ? meta.maxLines : null,
        textAlign: tsh.textAlign ?? TextAlign.start,
        textDirection: tsh.textDirection,
      );
    }
    return super.buildText(meta, tsh, text);
  }
}

class ReplaceResult {
  dom.Node node;
  List<dom.Node> newNodes;
  ReplaceResult(this.node, this.newNodes);
}
