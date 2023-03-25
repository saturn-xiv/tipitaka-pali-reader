import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';
import 'package:tipitaka_pali/ui/screens/settings/panel_size_setting_view.dart';
import '../../widgets/colored_text.dart';
import 'package:url_launcher/url_launcher.dart';

enum Startup { quoteOfDay, restoreLastRead }

class GeneralSettingsView extends StatefulWidget {
  const GeneralSettingsView({Key? key}) : super(key: key);

  @override
  State<GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<GeneralSettingsView> {
  bool _clipboard = Prefs.saveClickToClipboard;
  bool _multiTab = Prefs.multiTabMode;
  int _tabsVisible = Prefs.tabsVisible;
  double _currentSliderValue = 1;
  double _currentPanelFontSizeValue = 11;
  late double _currentUiFontSizeValue;

  @override
  void initState() {
    super.initState();
    _clipboard = Prefs.saveClickToClipboard;
    _currentUiFontSizeValue = Prefs.uiFontSize;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUiFontSizeValue = Prefs.uiFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: ExpansionTile(
        leading: const Icon(Icons.settings),
        title: Text(AppLocalizations.of(context)!.generalSettings,
            style: Theme.of(context).textTheme.titleLarge),
        children: [
          _getAnimationsSwitch(),
          const SizedBox(
            height: 10,
          ),
          const Divider(),
          const SizedBox(
            height: 10,
          ),
          const PanelSizeControlView(),
          const Divider(),
          _getUiFontSizeSlider(),
          const SizedBox(height: 10),
          const Divider(),
          _getDictionaryFontSizeSlider(),
          const SizedBox(height: 10),
          const Divider(),
          _getDictionaryToClipboardSwitch(),
          const Divider(),
          _getMultiTabsModeSwitch(),
          const Divider(),
          _getHelpTile(context),
          _getAboutTile(context),
          //QuotesOrRestore(),
          _getReportIssueTile(context),
        ],
      ),
    );
  }

  Widget _getAnimationsSwitch() {
    return Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Column(
          children: [
            Slider(
              value: Prefs.animationSpeed,
              max: 800,
              divisions: 20,
              label: _currentUiFontSizeValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  Prefs.animationSpeed = _currentSliderValue = value;
                });
              },
            ),
            Text(AppLocalizations.of(context)!.animationSpeed),
          ],
        ));
  }

  Widget _getUiFontSizeSlider() {
    return Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Column(
          children: [
            Slider(
              value: Prefs.uiFontSize,
              min: 8,
              max: 24,
              divisions: 16,
              label: _currentUiFontSizeValue.round().toString(),
              onChanged: (double value) {
                context.read<ThemeChangeNotifier>().onChangeFontSize(value);
              },
            ),
            Text('UI fontSize'),
          ],
        ));
  }

  Widget _getDictionaryFontSizeSlider() {
    return Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Column(
          children: [
            Slider(
              value: Prefs.dictionaryFontSize.toDouble(),
              min: 8,
              max: 20,
              divisions: 12,
              label: _currentPanelFontSizeValue.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentPanelFontSizeValue = value;
                  Prefs.dictionaryFontSize = value.toInt();
                });
              },
            ),
            Text(AppLocalizations.of(context)!.dictionaryFontSize),
          ],
        ));
  }

  Widget _getDictionaryToClipboardSwitch() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        title: Text(AppLocalizations.of(context)!.dictionaryToClipboard),
        trailing: Switch(
          onChanged: (value) {
            setState(() {
              _clipboard = Prefs.saveClickToClipboard = value;
            });
          },
          value: _clipboard,
        ),
      ),
    );
  }

  Widget _getMultiTabsModeSwitch() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: Column(
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.multiViewsMode),
            trailing: Switch(
              onChanged: (value) {
                setState(() {
                  _multiTab = Prefs.multiTabMode = value;
                });
              },
              value: _multiTab,
            ),
          ),
          (!Prefs.multiTabMode)
              ? const SizedBox.shrink()
              : _getNumTabsVisibleWidget(),
        ],
      ),
    );
  }

  Widget _getNumTabsVisibleWidget() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Text(AppLocalizations.of(context)!.numVisibleViews),
        ),
        IconButton(
          onPressed: () async {
            setState(() {
              if (_tabsVisible > 2) {
                _tabsVisible = _tabsVisible - 1;
                Prefs.tabsVisible = _tabsVisible;
              }
            });
          },
          icon: const Icon(Icons.remove),
        ),
        Text(
          _tabsVisible.toInt().toString(),
        ),
        IconButton(
          onPressed: () async {
            setState(() {
              if (_tabsVisible < 5) {
                _tabsVisible = _tabsVisible + 1;
                Prefs.tabsVisible = _tabsVisible;
              }
            });
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _getQuotesOrRestore() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        title: const Text("Quote -> Restore:"),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        trailing: Switch(
          onChanged: (value) => {
            //prefs
          },
          value: true,
        ),
      ),
    );
  }

  Widget _getAboutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        title: ColoredText(AppLocalizations.of(context)!.about),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => _showAboutDialog(context),
      ),
    );
  }

  _showAboutDialog(BuildContext context) {
    showAboutDialog(
        context: context,
        applicationName: AppLocalizations.of(context)!.tipitaka_pali_reader,
        applicationVersion: 'Version 1.7',
        children: [ColoredText(AppLocalizations.of(context)!.about_info)]);
  }

  Widget _getHelpTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        title: ColoredText(AppLocalizations.of(context)!.help),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => launchUrl(
            Uri.parse("https://americanmonk.org/tipitaka-pali-reader/"),
            mode: LaunchMode.externalApplication),
      ),
    );
  }

  Widget _getReportIssueTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        title: ColoredText(AppLocalizations.of(context)!.reportIssue),
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () => launchUrl(
            Uri.parse(
                "https://github.com/bksubhuti/tipitaka-pali-reader/issues"),
            mode: LaunchMode.externalApplication),
      ),
    );
  }
}
