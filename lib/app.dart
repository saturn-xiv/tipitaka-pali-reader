import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/business_logic/models/tpr_message.dart';
import 'package:tipitaka_pali/providers/initial_setup_notifier.dart';
import 'package:tipitaka_pali/ui/dialogs/show_tpr_message_dlg.dart';
import 'package:tipitaka_pali/ui/screens/home/openning_books_provider.dart';
import 'package:tipitaka_pali/unsupported_language_classes/ccp_intl.dart';

import 'providers/font_provider.dart';
import 'routes.dart';
import 'services/provider/locale_change_notifier.dart';
import 'services/provider/script_language_provider.dart';
import 'services/provider/theme_change_notifier.dart';
import 'ui/screens/splash_screen.dart';
import 'package:tipitaka_pali/services/fetch_messages_if_needed.dart';
import 'package:tipitaka_pali/ui/screens/settings/download_view.dart';

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
  final String _kmLocale = 'km';
  final String _loLocale = 'lo';
  final String _chakmaLocale = 'ccp';

  final StreamingSharedPreferences rxPref;

  const App({required this.rxPref, Key? key}) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider.value(
            value: rxPref,
          ),
          // placing at top of MaterialApp to access in different routes
          ChangeNotifierProvider<InitialSetupNotifier>(
              create: (_) => InitialSetupNotifier()),
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
          final themeChangeNotifier = context.watch<ThemeChangeNotifier>();
          final localChangeNotifier = context.watch<LocaleChangeNotifier>();
          final scriptChangeNotifier = context.watch<ScriptLanguageProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeChangeNotifier.themeMode,
            theme: themeChangeNotifier.themeData,
            darkTheme: themeChangeNotifier.darkTheme,
            locale: Locale(localChangeNotifier.localeString, ''),
            onGenerateRoute: RouteGenerator.generateRoute,
            localizationsDelegates: const [
              CcpMaterialLocalizations.delegate,
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
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
              Locale(_kmLocale, ''), // khmer, no country code
              Locale(_loLocale, ''), // Lao country code
              Locale(_chakmaLocale), // Chakma, no country code
            ],
            home: FutureBuilder(
              future: fetchMessageIfNeeded(),
              builder:
                  (BuildContext context, AsyncSnapshot<TprMessage> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData &&
                      snapshot.data!.generalMessage.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showWhatsNewDialog(context, snapshot.data!);
                    });
                  }
                }
                return const SplashScreen();
              },
            ),
          );
        },
      );
}
