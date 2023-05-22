import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/ui/screens/home/openning_books_provider.dart';
import 'package:tipitaka_pali/unsupported_language_classes/ccp_intl.dart';

import 'providers/font_provider.dart';
import 'routes.dart';
import 'services/provider/locale_change_notifier.dart';
import 'services/provider/script_language_provider.dart';
import 'services/provider/theme_change_notifier.dart';
import 'ui/screens/splash_screen.dart';

final Logger myLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
  level: kDebugMode ? Level.verbose : Level.nothing,
);

class App extends StatelessWidget {
  //final List<AppTheme> themes = MyTheme.fetchAll();
  final String _enLocale = 'en';
  final String _myLocale = 'my';
  final String _siLocale = 'si';
  final String _zhLocale = 'zh';
  final String _viLocale = 'vi';
  final String _hiLocale = 'hi';
  final String _ruLocale = 'ru';
  final String _bnLocale = 'bn';
  final String _chakmaLocale = 'ccp';

  final StreamingSharedPreferences rxPref;

  const App({required this.rxPref, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MultiProvider(
          providers: [
            Provider.value(
              value: rxPref,
            ),
            // placing at top of MaterialApp to access in differnt routes
            ChangeNotifierProvider<ThemeChangeNotifier>(
                create: (_) => ThemeChangeNotifier()),
            ChangeNotifierProvider<LocaleChangeNotifier>(
                create: (_) => LocaleChangeNotifier()),
            ChangeNotifierProvider<ScriptLanguageProvider>(
                create: (_) => ScriptLanguageProvider()),
            ChangeNotifierProvider<ReaderFontProvider>(
                create: (_) => ReaderFontProvider()),
            ChangeNotifierProvider<OpenningBooksProvider>(
                create: (_) => OpenningBooksProvider())
          ],
          builder: (context, _) {
            final themeChangeNotifier =
                Provider.of<ThemeChangeNotifier>(context);
            final localChangeNotifier =
                Provider.of<LocaleChangeNotifier>(context);
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: themeChangeNotifier.themeMode,
              theme: themeChangeNotifier.themeData,
              darkTheme: themeChangeNotifier.darkTheme,
              locale: Locale(localChangeNotifier.localeString, ''),
              onGenerateRoute: RouteGenerator.generateRoute,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                CcpMaterialLocalizations.delegate,
              ],
              supportedLocales: [
                Locale(_enLocale, ''), // English, no country code
                Locale(_myLocale, ''), // Myanmar, no country code
                Locale(_siLocale, ''), // Sinahala, no country code
                Locale(_zhLocale, ''), // Chinese, no country code
                Locale(_viLocale, ''), // Vietnamese, no country code
                Locale(_hiLocale, ''), // Hindi, no country code
                Locale(_ruLocale, ''), // Russian, no country code
                Locale(_bnLocale, ''), // Bengali, no country code
                Locale(
                    _chakmaLocale), // Chakma, no country code  //implemented as custom unsupported lang
              ],
              home: const SplashScreen(),
            );
          } // builder
          );
}
