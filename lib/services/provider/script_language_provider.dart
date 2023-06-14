import 'package:flutter/material.dart';
import 'package:tipitaka_pali/services/provider/theme_change_notifier.dart';

import '../prefs.dart';
import '../../utils/pali_script_converter.dart';

class ScriptLanguageProvider extends ChangeNotifier {
  String _currentlocaleCode = Prefs.currentScriptLanguage;
  List<ScriptInfo> get languages => listOfScripts;
  Script get currentScript => _getScriptFrom(localeCode: _currentlocaleCode);
  ScriptInfo get currentScriptInfo =>
      _getScriptInfoFrom(localeCode: _currentlocaleCode);

  void onLanguageChage(ScriptInfo? scriptInfo) {
    if (scriptInfo != null) {
      _currentlocaleCode = scriptInfo.localeCode;
      Prefs.currentScriptLanguage = _currentlocaleCode;
      notifyListeners();
    }
  }

  Script _getScriptFrom({required String localeCode}) {
    for (final scriptInfo in languages) {
      if (localeCode == scriptInfo.localeCode) {
        return scriptInfo.script;
      }
    }
    return Script.roman;
  }

  ScriptInfo _getScriptInfoFrom({required String localeCode}) {
    for (final scriptInfo in languages) {
      if (localeCode == scriptInfo.localeCode) {
        return scriptInfo;
      }
    }
    return languages.first;
  }
}
