import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:substring_highlight/substring_highlight.dart';
import 'toc.dart';
import '../../services/provider/script_language_provider.dart';
import '../../utils/pali_script.dart';

abstract class TocListItem {
  late Toc toc;
  int getPageNumber();
  Widget build(BuildContext context, String filterText);
}

class TocHeadingOne implements TocListItem {
  TocHeadingOne(this.toc);

  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final tocName = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: toc.name);

    return Text(tocName, style: Theme.of(context).textTheme.titleLarge);
  }
}

class TocHeadingTwo implements TocListItem {
  TocHeadingTwo(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final tocName = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(color: colorScheme.onSurface),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}

class TocHeadingThree implements TocListItem {
  TocHeadingThree(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final tocName = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(color: colorScheme.onSurface),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}

class TocHeadingFour implements TocListItem {
  TocHeadingFour(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final tocName = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 48.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(color: colorScheme.onSurface),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}

class TocHeadingFive implements TocListItem {
  TocHeadingFive(this.toc);
  @override
  final Toc toc;
  @override
  set toc(Toc toc) => this.toc = toc;

  @override
  int getPageNumber() {
    return toc.pageNumber;
  }

  @override
  Widget build(BuildContext context, String filterText) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final tocName = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: toc.name);
    return Padding(
      padding: const EdgeInsets.only(left: 64.0),
      child: SubstringHighlight(
        text: tocName,
        term: filterText,
        textStyle: TextStyle(color: colorScheme.onSurface),
        textStyleHighlight: TextStyle(color: colorScheme.primary),
      ),
    );
  }
}
