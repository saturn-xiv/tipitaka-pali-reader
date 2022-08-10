import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/ui/screens/home/opened_books_provider.dart';
import 'package:tipitaka_pali/utils/platform_info.dart';

import '../../../business_logic/models/list_item.dart';
import '../../../business_logic/view_models/home_page_view_model.dart';
import '../../../routes.dart';
import '../../../services/provider/script_language_provider.dart';
import '../../../utils/pali_script.dart';
import '../../widgets/colored_text.dart';

class HomePage extends StatelessWidget {
  // key will be use for load book list from database
  // value will be use for TabBar Title

  final Map<String, String> _mainCategories = {
    'mula': 'Pāḷi',
    'attha': 'Aṭṭhakathā',
    'tika': 'Ṭīkā',
    'annya': 'Añña'
  };

  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isMobile = Platform.isAndroid || Platform.isIOS;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.tipitaka_pali_reader),
            centerTitle: true,
            actions: const [],
            bottom: TabBar(
              tabs: _mainCategories.entries
                  .map((category) => Tab(
                      text: PaliScript.getScriptOf(
                          script: context
                              .watch<ScriptLanguageProvider>()
                              .currentScript,
                          romanText: category.value)))
                  .toList(),
            ),
          ),
          drawer: isMobile ? _buildDrawer(context) : null,
          body: TabBarView(
              children: _mainCategories.entries
                  .map((category) => _buildBookList(category.key))
                  .toList())),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 250,
            child: DrawerHeader(
              decoration: const BoxDecoration(),
              child: Column(
                children: [
                  ColoredText(
                      AppLocalizations.of(context)!.tipitaka_pali_reader,
                      style: const TextStyle(
                        fontSize: 17,
                      )),
                  const SizedBox(height: 25.0),
                  Image.asset(
                    "assets/icon/icon.png",
                    height: 90,
                    width: 90,
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: ColoredText(AppLocalizations.of(context)!.dictionary,
                style: const TextStyle()),
            onTap: () => _openDictionaryPage(context),
          ),
          ListTile(
            title: ColoredText(AppLocalizations.of(context)!.settings,
                style: const TextStyle()),
            onTap: () => _openSettingPage(context),
          ),
          ListTile(
            title: ColoredText(AppLocalizations.of(context)!.about,
                style: const TextStyle()),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(String category) {
    return FutureBuilder(
        future: _loadBooks(category),
        builder: (context, AsyncSnapshot<List<ListItem>> snapshot) {
          if (snapshot.hasData) {
            final listItems = snapshot.data!;
            return ListView.separated(
                itemCount: listItems.length,
                itemBuilder: (context, index) => ListTile(
                      title: listItems[index].build(context),
                      onTap: () => _openBook(context, listItems[index]),
                    ),
                separatorBuilder: (context, index) {
                  return const Divider(
                    color: Colors.grey,
                  );
                });
          }
          // will be dispaly blank while loading instead of circular progress indicator
          return const Center(child: CircularProgressIndicator());
        });
  }

  Future<List<ListItem>> _loadBooks(String category) async {
    // await Future.delayed(Duration(seconds: 2));
    return await HomePageViewModel().fecthItems(category);
  }

  _openSettingPage(BuildContext context) async {
    await Navigator.pushNamed(context, settingRoute);
  }

  _openBook(BuildContext context, ListItem listItem) {
    if (listItem.runtimeType == BookItem) {
      BookItem bookItem = listItem as BookItem;
      debugPrint('book name: ${bookItem.book.name}');

      if (PlatformInfo.isDesktop) {
        final homeController = context.read<OpenedBooksProvider>();
        homeController.add(book: bookItem.book);
      } else {
        Navigator.pushNamed(context, readerRoute,
            arguments: {'book': bookItem.book});
      }
    }
  }

  _openDictionaryPage(BuildContext context) {
    Navigator.pushNamed(context, dictionaryRoute);
  }

  _showAboutDialog(BuildContext context) {
    showAboutDialog(
        context: context,
        applicationName: AppLocalizations.of(context)!.tipitaka_pali_reader,
        applicationVersion: 'Version 1.0',
        children: [ColoredText(AppLocalizations.of(context)!.about_info)]);
  }
}
