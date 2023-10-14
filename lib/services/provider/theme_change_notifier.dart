import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/data/flex_theme_data.dart';
import 'package:tipitaka_pali/services/provider/script_language_provider.dart';

import '../../utils/font_utils.dart';

class ThemeChangeNotifier extends ChangeNotifier {
  ThemeMode themeMode = (Prefs.darkThemeOn) ? ThemeMode.dark : ThemeMode.light;
  // ignore: unused_field
  int _themeIndex = 1;
  final List<bool> _isSelected = [true, false, false];

  set themeIndex(int val) {
    _themeIndex = val;
    notifyListeners();
  }

  List<bool> get isSelected {
    Prefs.selectedPageColor;

    //make sure the list returned is the same as prefs given.
    for (int x = 0; x < _isSelected.length; x++) {
      _isSelected[x] = x == Prefs.selectedPageColor;
    }
    return _isSelected;
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;

  toggleTheme(int index) {
    themeMode = ThemeMode.light;
    for (int buttonIndex = 0; buttonIndex < isSelected.length; buttonIndex++) {
      if (buttonIndex == index) {
        _isSelected[buttonIndex] = true;
      } else {
        _isSelected[buttonIndex] = false;
      }
    }

    switch (index) {
      case 0:
        Prefs.selectedPageColor = 0;
        themeMode = ThemeMode.light;
        Prefs.darkThemeOn = false;
        break;
      case 1:
        Prefs.selectedPageColor = 1;
        themeMode = ThemeMode.light;
        Prefs.darkThemeOn = false;
        break;
      case 2:
        Prefs.selectedPageColor = 2;
        themeMode = ThemeMode.dark;
        Prefs.darkThemeOn = true;
        break;
      default:
        Prefs.selectedPageColor = 0;
        themeMode = ThemeMode.light;
        Prefs.darkThemeOn = false;
        break;
    }

    notifyListeners();
  }

  void onChangeFontSize(double fontSize) {
    Prefs.uiFontSize = fontSize;
    notifyListeners();
  }

  //returns // flexschemedata
  get darkTheme => FlexColorScheme.dark(
        // As scheme colors we use the one from our list
        // pointed to by the current themeIndex.
        colors: myFlexSchemes[Prefs.themeIndex].dark,
        // Medium strength surface branding used in this example.
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        textTheme: _textTheme,
      ).toTheme;

  ThemeData get themeData =>
      //ThemeData get themeData=>  myFlexSchemes[Prefs.themeIndex].light().toTheme();
      FlexColorScheme.light(
        // As scheme colors we use the one from our list
        // pointed to by the current themeIndex.
        useMaterial3: true,
        colors: myFlexSchemes[Prefs.themeIndex].light,
        // Medium strength surface branding used in this example.
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        textTheme: _textTheme,
      ).toTheme;

  TextTheme get _textTheme {
    // this was changed for getting the laos font to work in the UI section of the
    // choose book screen.  However, it was decided not to support the Laos fonts unless
    // the copyright is properly expressed.
    // there seemed to be a little bit of a bug with going from lao script back to other scripts
    // if you did, you needed to restart the app.  To remedy this.. you can totally remove the code that
    // has the fontFamily for TextStyle parameter.
    final theFont =
        FontUtils.getfontName(script: ScriptLanguageProvider().currentScript);

    return TextTheme(
      bodyLarge: TextStyle(
        fontSize: Prefs.uiFontSize + 2,
        fontWeight: FontWeight.w400,
        fontFamily: theFont, // passing the font name
      ),
      bodyMedium: TextStyle(
        fontSize: Prefs.uiFontSize,
        fontWeight: FontWeight.w400,
        fontFamily: theFont, // passing the font name
      ),
      bodySmall: TextStyle(
        fontSize: Prefs.uiFontSize - 3,
        fontWeight: FontWeight.w400,
        fontFamily: theFont, // passing the font name
      ),
      titleLarge: TextStyle(
        fontSize: Prefs.uiFontSize + 3,
        fontWeight: FontWeight.w600,
        fontFamily: theFont, // passing the font name
      ),
      titleMedium: TextStyle(
        fontSize: Prefs.uiFontSize + 2,
        fontWeight: FontWeight.w600,
        fontFamily: theFont, // passing the font name
      ),
      titleSmall: TextStyle(
        fontSize: Prefs.uiFontSize,
        fontWeight: FontWeight.w600,
        fontFamily: theFont, // passing the font name
      ),
    );
  }
}
