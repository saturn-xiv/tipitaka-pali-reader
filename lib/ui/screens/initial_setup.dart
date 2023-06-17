import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/business_logic/view_models/initial_setup_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tipitaka_pali/providers/initial_setup_notifier.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';
import 'package:tipitaka_pali/ui/widgets/colored_text.dart';
import 'package:tipitaka_pali/ui/widgets/select_language_widget.dart';
import 'package:tipitaka_pali/ui/screens/settings/select_script_language.dart';
import 'package:path/path.dart' as path;
import '../dialogs/reset_dialog.dart';
import 'package:tipitaka_pali/ui/dialogs/extension_prompt_dialog.dart';

class InitialSetup extends StatelessWidget {
  final bool isUpdateMode;
  InitialSetup({Key? key, this.isUpdateMode = false}) : super(key: key) {}

  @override
  Widget build(BuildContext context) {
    final initialSetupNotifier =
        Provider.of<InitialSetupNotifier>(context, listen: false);
    final initialSetupService =
        InitialSetupService(context, initialSetupNotifier, isUpdateMode);
    initialSetupService.setUp(isUpdateMode);

    return Material(
      child: ChangeNotifierProvider.value(
        value: initialSetupNotifier,
        child: Center(
          child: _buildHomeView(context, initialSetupNotifier),
        ),
      ),
    );
  }

  Widget _buildHomeView(BuildContext context, InitialSetupNotifier notifier) {
    if (notifier.setupIsFinished) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        concludeTheSetup(context);
      });
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.resetData),
          onPressed: () {
            doResetDialog(context);
          },
        ),
        const SizedBox(height: 20),
        const Text(
          "Set Language \nသင်၏ဘာသာစကားကိုရွေးပါ\nඔබේ භාෂාව තෝරන්න\n选择你的语言\nChọn ngôn ngữ\nभाषा चयन करें\n",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SelectLanguageWidget(),
        const SizedBox(height: 20),
        const SelectScriptLanguageWidget(),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        isUpdateMode
            ? Text(
                AppLocalizations.of(context)!.updatingStatus,
                textAlign: TextAlign.center,
              )
            : Text(
                AppLocalizations.of(context)!.copyingStatus,
                textAlign: TextAlign.center,
              ),
        const SizedBox(height: 10),
        Consumer<InitialSetupNotifier>(
          builder: (context, notifier, child) {
            return ColoredText(notifier.status);
          },
        ),
        const SizedBox(height: 20),
        Consumer<InitialSetupNotifier>(
          builder: (context, notifier, _) {
            if (notifier.setupIsFinished) {
              notifier.setupIsFinished = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                concludeTheSetup(context);
              });
            }
            // Return your desired UI here
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void concludeTheSetup(BuildContext context) async {
    List<File> extensions = getExtensionFiles();
    String exlist = "";
    for (final file in extensions) {
      final fileName = path.basename(file.path);
      exlist += "$fileName\n";
    }
    if (extensions.isNotEmpty) {
      final message =
          "${AppLocalizations.of(context)!.folloingExtensions}\n$exlist \n ${AppLocalizations.of(context)!.wouldYouLikeToInstall}";

      // Prompt the user to install extensions
      final shouldInstall = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return ExtensionPromptDialog(message: message);
        },
      );

      if (shouldInstall ?? false) {
        // User selected Yes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DownloadView(),
          ),
        ).then((_) {
          _openHomePage(context);
        });
      } else {
        // User selected No or dismissed the dialog
        _openHomePage(context);
      }
    } else {
      // No extensions found, directly open the home page
      _openHomePage(context);
    }
  }

  void _openHomePage(context) {
    //Navigator.of(context).pop();
    Navigator.of(context).pushNamed('/home');
  }

  List<File> getExtensionFiles() {
    final directory = Directory(Prefs.databaseDirPath);
    final files = directory.listSync().whereType<File>().toList();
    List<File> extensions = [];

    for (final file in files) {
      if (file.path.endsWith('.sql')) {
        //await processLocalFile(file);
        extensions.add(file);
      }
    }
    return extensions;
  }
}
