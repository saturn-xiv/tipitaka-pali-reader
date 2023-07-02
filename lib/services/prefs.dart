// import to copy////////////////////
//import 'package:tipitaka_pali/services/prefs.dart';

// Shared prefs package import

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/constants.dart';

// preference names
const String localeValPref = "localeVal";
const String themeIndexPref = "themeIndex";
const String themeNamePref = "themeNamePref";
const String darkThemeOnPref = "darkThemeOn";
const String readerFontSizePref = "fontSize";
const String uiFontSizePref = "ui_fontSize";
const String dictionaryFontSizePref = "dictionaryFontSize";
const String databaseVersionPref = "databaseVersion";
const String isDatabaseSavedPref = "isDatabaseSaved";
const String isShowAlternatePaliPref = 'showAlternatePali';
const String isShowPtsNumberPref = 'showPtsNumber';
const String isShowThaiNumberPref = 'showThaiNumber';
const String isShowVriNumberPref = 'showVriNumber';
const String currentScriptLocaleCodePref = 'currentScriptLocaleCode';
const String queryModePref = 'queryMode';
const String wordDistancePref = 'wordDistance';
const String isPeuPref = "isPeuOn";
const String isDpdPref = "isDpdOn";
const String selectedPageColorPref = "selectedPageColor";
const String databaseDirPathPref = "databaseDirPath";
const String saveClickToClipboardPref = "saveClickToClipbard";
const String multiTabModePref = "multiTabMode";
const String animationSpeedPref = "animationSpeed";
const String selectedMainCategoryFiltersPref = "selectedMainCategoryFilters";
const String selectedSubCategoryFiltersPref = "selectedSubCategoryFilters";
const String tabsVisiblePref = "tabsVisible";
const String controlBarShowPref = "controlBarShow";
const String isFuzzyPref = "isFuzzy";
const String newTabAtEnd = 'newTabAtEnd';
const String isDpdGrammarOnPref = "isDpdGrammarOn";
const String alwaysShowDpdSplitterPref = "alwasyShowDpdSplitter";
const String numberBooksOpenedPref = "numberBooksOpened";
const String numberWordsLookedUpPref = "numberWordsLookedUp";
const String okToRatePref = "okToRate";
const String multiHighlightPref = "singleHighlight";
const String expandedBookListPref = "expandedBookList";
const String messagePref = "message";
const String messageDatePref = "messageDate";
const String lastDateCheckedMessagePref = "lastDateCheckedMessage";

// default pref values
const int defaultLocaleVal = 0;
const int defaultThemeIndex = 12;
const String defaultThemeName = '';

const bool defaultDarkThemeOn = false;
//ToDo something is not right with release and font size
const int defaultReaderFontSize = 14;
const double defaultUiFontSize = 14.0;
const int defaultDictionaryFontSize = 14;
const int defaultDatabaseVersion = 1;
const bool defaultIsDatabaseSaved = false;
const bool defaultShowAlternatePali = false;
const bool defaultShowPTSNumber = false;
const bool defaultShowThaiNumber = false;
const bool defaultShowVRINumber = false;
const String defaultScriptLanguage = 'ro';
const int defaultQueryModeIndex = 0;
const int defaultWordDistance = 10;
const bool defaultIsPeuOn = true;
const bool defaultIsDpdOn = true;
int defaultSelectedPageColor = 0;
const String defaultDatabaseDirPath = "";
const bool defaultSaveClickToClipboard = false;
const bool defaultmultiTabMode = false;
const double defaultAnimationSpeed = 400;
const int defaultTabsVisible = 3;
const bool defaultControlBarShow = true;
const bool defaultIsFuzzy = false;
const bool defaultNewTabAtEnd = false;
const bool defaultIsDpdGrammarOn = false;
const bool defaultAlwaysShowDpdSplitter = false;
const int defaultNumberBooksOpened = 0;
const int defaultNumberWordsLookedUp = 0;
const bool defaultOkToRate = true;
const bool defaultMultiHighlight = false;
const bool defaultExpandedBookList = false;
const String defaultMessage = "";
const String defaultMessageDate = "20230701";
const String defaultLastDateCheckedMessage = "20230701";

List<String> defaultSelectedMainCategoryFilters = [
  "mula",
  "annya",
  "attha",
  "tika"
];
List<String> defultSelectedSubCategoryFilters = [
  "_vi",
  "_di",
  "_ma",
  "_sa",
  "_an",
  "_ku",
  "_bi",
  "_pe"
];

class Prefs {
  // prevent object creation
  Prefs._();
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  // get and set the default member values if null
  static int get localeVal =>
      instance.getInt(localeValPref) ?? defaultLocaleVal;
  static set localeVal(int value) => instance.setInt(localeValPref, value);

  static int get themeIndex =>
      instance.getInt(themeIndexPref) ?? defaultThemeIndex;
  static set themeIndex(int value) => instance.setInt(themeIndexPref, value);

  static String get themeName =>
      instance.getString(themeNamePref) ?? defaultThemeName;
  static set themeName(String value) =>
      instance.setString(themeNamePref, value);

  static bool get darkThemeOn =>
      instance.getBool(darkThemeOnPref) ?? defaultDarkThemeOn;
  static set darkThemeOn(bool value) =>
      instance.setBool(darkThemeOnPref, value);

  static int get readerFontSize =>
      instance.getInt(readerFontSizePref) ?? defaultReaderFontSize;
  static set readerFontSize(int value) =>
      instance.setInt(readerFontSizePref, value);

  static double get uiFontSize =>
      instance.getDouble(uiFontSizePref) ?? defaultUiFontSize;
  static set uiFontSize(double value) =>
      instance.setDouble(uiFontSizePref, value);

  static int get dictionaryFontSize =>
      instance.getInt(dictionaryFontSizePref) ?? defaultDictionaryFontSize;
  static set dictionaryFontSize(int value) =>
      instance.setInt(dictionaryFontSizePref, value);

  static int get databaseVersion =>
      instance.getInt(databaseVersionPref) ?? defaultDatabaseVersion;
  static set databaseVersion(int value) =>
      instance.setInt(databaseVersionPref, value);

  static bool get isDatabaseSaved =>
      instance.getBool(isDatabaseSavedPref) ?? defaultIsDatabaseSaved;
  static set isDatabaseSaved(bool value) =>
      instance.setBool(isDatabaseSavedPref, value);

  static bool get isShowAlternatePali =>
      instance.getBool(isShowAlternatePaliPref) ?? defaultShowAlternatePali;
  static set isShowAlternatePali(bool value) =>
      instance.setBool(isShowAlternatePaliPref, value);

  static bool get isShowPtsNumber =>
      instance.getBool(isShowPtsNumberPref) ?? defaultShowPTSNumber;
  static set isShowPtsNumber(bool value) =>
      instance.setBool(isShowPtsNumberPref, value);

  static bool get isShowThaiNumber =>
      instance.getBool(isShowThaiNumberPref) ?? defaultShowThaiNumber;
  static set isShowThaiNumber(bool value) =>
      instance.setBool(isShowThaiNumberPref, value);

  static bool get isShowVriNumber =>
      instance.getBool(isShowVriNumberPref) ?? defaultShowVRINumber;
  static set isShowVriNumber(bool value) =>
      instance.setBool(isShowVriNumberPref, value);

  static String get currentScriptLanguage =>
      instance.getString(currentScriptLocaleCodePref) ?? defaultScriptLanguage;
  static set currentScriptLanguage(String value) =>
      instance.setString(currentScriptLocaleCodePref, value);

  static int get queryModeIndex =>
      instance.getInt(queryModePref) ?? defaultQueryModeIndex;
  static set queryModeIndex(int value) => instance.setInt(queryModePref, value);

  static int get wordDistance =>
      instance.getInt(wordDistancePref) ?? defaultWordDistance;
  static set wordDistance(int value) =>
      instance.setInt(wordDistancePref, value);

  static bool get isPeuOn => instance.getBool(isPeuPref) ?? defaultIsPeuOn;
  static set isPeuOn(bool value) => instance.setBool(isPeuPref, value);

  static bool get isDpdOn => instance.getBool(isDpdPref) ?? defaultIsDpdOn;
  static set isDpdOn(bool value) => instance.setBool(isDpdPref, value);

  static int get selectedPageColor =>
      instance.getInt(selectedPageColorPref) ?? defaultSelectedPageColor;
  static set selectedPageColor(int value) =>
      instance.setInt(selectedPageColorPref, value);

  static String get databaseDirPath =>
      instance.getString(databaseDirPathPref) ?? defaultDatabaseDirPath;
  static set databaseDirPath(String value) =>
      instance.setString(databaseDirPathPref, value);

  static bool get saveClickToClipboard =>
      instance.getBool(saveClickToClipboardPref) ?? defaultSaveClickToClipboard;
  static set saveClickToClipboard(bool value) =>
      instance.setBool(saveClickToClipboardPref, value);

  static bool get multiTabMode =>
      instance.getBool(multiTabModePref) ?? defaultmultiTabMode;
  static set multiTabMode(bool value) =>
      instance.setBool(multiTabModePref, value);

  static double get animationSpeed =>
      instance.getDouble(animationSpeedPref) ?? defaultAnimationSpeed;
  static set animationSpeed(double value) =>
      instance.setDouble(animationSpeedPref, value);

  static List<String> get selectedMainCategoryFilters =>
      instance.getStringList(selectedMainCategoryFiltersPref) ??
      defaultSelectedMainCategoryFilters;
  static set selectedMainCategoryFilters(List<String> value) =>
      instance.setStringList(selectedMainCategoryFiltersPref, value);

  static List<String> get selectedSubCategoryFilters =>
      instance.getStringList(selectedSubCategoryFiltersPref) ??
      defultSelectedSubCategoryFilters;
  static set selectedSubCategoryFilters(List<String> value) =>
      instance.setStringList(selectedSubCategoryFiltersPref, value);

  static int get tabsVisible =>
      instance.getInt(tabsVisiblePref) ?? defaultTabsVisible;
  static set tabsVisible(int value) => instance.setInt(tabsVisiblePref, value);

  static bool get controlBarShow =>
      instance.getBool(controlBarShowPref) ?? defaultControlBarShow;
  static set controlBarShow(bool value) =>
      instance.setBool(controlBarShowPref, value);

  static bool get isFuzzy => instance.getBool(isFuzzyPref) ?? defaultIsFuzzy;
  static set isFuzzy(bool value) => instance.setBool(isFuzzyPref, value);

  static bool get isNewTabAtEnd =>
      instance.getBool(newTabAtEnd) ?? defaultNewTabAtEnd;
  static set isNewTabAtEnd(bool value) => instance.setBool(newTabAtEnd, value);

  static bool get isDpdGrammarOn =>
      instance.getBool(isDpdGrammarOnPref) ?? defaultIsDpdGrammarOn;
  static set isDpdGrammarOn(bool value) =>
      instance.setBool(isDpdGrammarOnPref, value);

  static bool get alwaysShowDpdSplitter =>
      instance.getBool(alwaysShowDpdSplitterPref) ??
      defaultAlwaysShowDpdSplitter;
  static set alwaysShowDpdSplitter(bool value) =>
      instance.setBool(alwaysShowDpdSplitterPref, value);

  // Get and set the default member values if null
  static int get numberBooksOpened =>
      instance.getInt(numberBooksOpenedPref) ?? defaultNumberBooksOpened;

  static set numberBooksOpened(int value) =>
      instance.setInt(numberBooksOpenedPref, value);

  static int get numberWordsLookedUp =>
      instance.getInt(numberWordsLookedUpPref) ?? defaultNumberWordsLookedUp;

  static set numberWordsLookedUp(int value) =>
      instance.setInt(numberWordsLookedUpPref, value);

  static bool get okToRate => instance.getBool(okToRatePref) ?? defaultOkToRate;

  static set okToRate(bool value) => instance.setBool(okToRatePref, value);

  // Add getter and setter for singleHighlight
  static bool get multiHighlight =>
      instance.getBool(multiHighlightPref) ?? defaultMultiHighlight;
  static set multiHighlight(bool value) =>
      instance.setBool(multiHighlightPref, value);

  static bool get expandedBookList =>
      instance.getBool(expandedBookListPref) ?? defaultExpandedBookList;
  static set expandedBookList(bool value) =>
      instance.setBool(expandedBookListPref, value);

  static String get message =>
      instance.getString(messagePref) ?? defaultMessage;
  static set message(String value) => instance.setString(messagePref, value);

  static String get messageDate =>
      instance.getString(messageDatePref) ?? defaultMessageDate;
  static set messageDate(String value) =>
      instance.setString(messageDatePref, value);

  static String get lastDateCheckedMessage =>
      instance.getString(lastDateCheckedMessagePref) ??
      defaultLastDateCheckedMessage;
  static set lastDateCheckedMessage(String value) =>
      instance.setString(lastDateCheckedMessagePref, value);

  // ===========================================================================
  // Helpers

  static Color getChosenColor() {
    switch (Prefs.selectedPageColor) {
      case 0:
        return Color(Colors.white.value);
      case 1:
        return const Color(seypia);
      case 2:
        return Color(Colors.black.value);
      default:
        return Color(Colors.white.value);
    }
  }

  static bool isUsageAttained() {
    return (numberBooksOpened > maxBooksOpened &&
            numberWordsLookedUp > maxWordsLookedUp) &&
        okToRate;
  }
}
