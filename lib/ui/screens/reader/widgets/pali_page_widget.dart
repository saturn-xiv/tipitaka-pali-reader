import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_selectable_text/fwfh_selectable_text.dart';

import '../../../../utils/pali_script_converter.dart';

class PaliPageWidget extends StatelessWidget {
  final String htmlContent;
  final Script script;
  final double fontSize;
  final Function(String clickedWord)? onClick;
  const PaliPageWidget({
    Key? key,
    required this.htmlContent,
    required this.script,
    required this.fontSize,
    this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: HtmlWidget(
          _formatContent(htmlContent, script),
          factoryBuilder: () => _MyFactory(),
          textStyle: TextStyle(fontSize: fontSize),
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
              return {
                'color': 'black',
                'text-decoration': 'none',
              };
            }
            // no style
            return {'text-decoration': 'none'};
          },
          onTapUrl: (word) {
            if (onClick != null) {
              onClick!(word);
            }
            return true;
          },
        ),
      ),
    );
  }

  String _formatContent(String content, Script script) {
    content = _makeClickable(content, script);
    content = _changeToInlineStyle(content);
    return content;
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
    final styleMaps = <String, String>{
      r'class="bld"': r'style="font-weight:bold;"',
      r'class="centered"': r'style="text-align:center;"',
      r'class="paranum"': r'style="font-weight: bold;"',
      r'class="indent"': r'style="text-indent:1.3em;margin-left:2em;"',
      r'class="bodytext"': r'style="text-indent:1.3em;"',
      r'class="unindented"': r'style=""',
      r'class="noindentbodytext"': r'style=""',
      r'class="book"':
          r'style="font-size: 1.9em; text-align:center; font-weight: bold;"',
      r'class="chapter"':
          r'style="font-size: 1.7em; text-align:center; font-weight: bold;"',
      r'class="nikaya"':
          r'style="font-size: 1.6em; text-align:center; font-weight: bold;"',
      r'class="title"':
          r'style="font-size: 1.3em; text-align:center; font-weight: bold;"',
      r'class="subhead"':
          r'style="font-size: 1.6em; text-align:center; font-weight: bold;"',
      r'class="subsubhead"':
          r'style="font-size: 1.6em; text-align:center; font-weight: bold;"',
      r'class="gatha1"': r'style="margin-bottom: 0em; margin-left: 5em;"',
      r'class="gatha2"': r'style="margin-bottom: 0em; margin-left: 5em;"',
      r'class="gatha3"': r'style="margin-bottom: 0em; margin-left: 5em;"',
      r'class="gathalast"': r'style="margin-bottom: 1.3em; margin-left: 5em;"',
      r'class="pageheader"': r'style="font-size: 0.9em; color: deeppink;"',
      r'class="highlighted"':
          r'style="background: rgb(255, 114, 20); color: white;"',
    };

    styleMaps.forEach((key, value) {
      content = content.replaceAll(key, value);
    });

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
        return RegExp('\u1780-\u17FF]+(?![^<>]*>)');
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
}

class _MyFactory extends WidgetFactory {
  /// Controls whether text is rendered with [SelectableText] or [RichText].
  ///
  /// Default: `true`.
  bool get selectableText => true;

  /// The callback when user changes the selection of text.
  ///
  /// See [SelectableText.onSelectionChanged].
  SelectionChangedCallback? get selectableTextOnChanged => null;

  @override
  Widget? buildText(BuildMetadata meta, TextStyleHtml tsh, InlineSpan text) {
    if (selectableText &&
        meta.overflow == TextOverflow.clip &&
        text is TextSpan) {
      return SelectableText.rich(
        text,
        maxLines: meta.maxLines > 0 ? meta.maxLines : null,
        textAlign: tsh.textAlign ?? TextAlign.start,
        textDirection: tsh.textDirection,
        onSelectionChanged: (selection, cause) {
          final int start = selection.baseOffset;
          final int end = selection.extentOffset;
          print('baseOffset: $start');
          print('extendedOffset: $end');
        },
      );
    }

    return super.buildText(meta, tsh, text);
  }
}
