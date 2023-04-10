import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/provider/script_language_provider.dart';
import '../../../../utils/pali_script.dart';

class SuggestionListTile extends StatelessWidget {
  const SuggestionListTile({
    Key? key,
    required this.suggestedWord,
    required this.frequency,
    this.isFirstWord = true,
    this.onClickedSubmitButton,
    this.onClickedSuggestion,
  }) : super(key: key);

  final String suggestedWord;
  final int frequency;
  final bool isFirstWord;
  final VoidCallback? onClickedSubmitButton;
  final VoidCallback? onClickedSuggestion;

  @override
  Widget build(BuildContext context) {
    String scriptWord = PaliScript.getScriptOf(
        script: context.read<ScriptLanguageProvider>().currentScript,
        romanText: suggestedWord);
    if (!isFirstWord) {
      scriptWord = '... $scriptWord';
    }
    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      // suggested word
      title: Text(scriptWord, style: Theme.of(context).textTheme.bodyLarge),
      leading: const Icon(Icons.library_add),
      //subtitle: const Icon(Icons.library_add),
      // word frequency
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              PaliScript.getScriptOf(
                  script: context.read<ScriptLanguageProvider>().currentScript,
                  romanText: (frequency == -1) ? " " : frequency.toString()),
              style: Theme.of(context).textTheme.bodyLarge),
          IconButton(
              onPressed: onClickedSubmitButton, icon: const Icon(Icons.search)),
        ],
      ),
      onTap: onClickedSuggestion,
    );
  }
}
