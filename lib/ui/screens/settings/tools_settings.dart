import 'package:flutter/material.dart';
import 'package:tipitaka_pali/ui/screens/dictionary/flashcard_setup_view.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tipitaka_pali/ui/widgets/colored_text.dart';

class ToolsSettingsView extends StatefulWidget {
  const ToolsSettingsView({Key? key}) : super(key: key);

  @override
  State<ToolsSettingsView> createState() => _ToolsSettingsViewState();
}

class _ToolsSettingsViewState extends State<ToolsSettingsView> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: ExpansionTile(
        leading: const Icon(Icons.build),
        title: Text(AppLocalizations.of(context)!.tools,
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          const SizedBox(
            height: 10,
          ),
          _getExtensionsTile(context),
          _getFlashCardExportTile(context),
        ],
      ),
    );
  }

  Widget _getExtensionsTile(context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DownloadView()),
          );
        },
        leading: const Icon(Icons.extension),
        title: ColoredText(
          AppLocalizations.of(context)!.extensions,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        trailing: const Icon(Icons.navigate_next),
      ),
    );
  }

  Widget _getFlashCardExportTile(context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: Icon(Icons.speaker_notes_outlined),
        title: ColoredText(AppLocalizations.of(context)!.flashcards),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        trailing: const Icon(Icons.navigate_next),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FlashCardSetupView()),
          );
        },
      ),
    );
  }
}
