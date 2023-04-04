import 'package:flutter/material.dart';
import '../../../../business_logic/models/search_suggestion.dart';
import 'suggestion_list_tile.dart';

class SearchSuggestionView extends StatelessWidget {
  const SearchSuggestionView({
    super.key,
    required this.suggestions,
    this.onClicked,
    this.isFistWord = true,
  });

  final List<SearchSuggestion> suggestions;
  final ValueChanged<SearchSuggestion>? onClicked;
  final bool isFistWord;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => SuggestionListTile(
        suggestedWord: suggestions[index].word,
        frequency: suggestions[index].count,
        isFirstWord: isFistWord,
        onTap: () => onClicked?.call(suggestions[index]),
      ),
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }
}
