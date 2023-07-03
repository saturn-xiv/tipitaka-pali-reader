import 'package:flutter/material.dart';
import 'package:tipitaka_pali/ui/widgets/colored_text.dart';
import '../../../business_logic/models/download_list_item.dart';
import 'download_service.dart';
import 'download_notifier.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:tipitaka_pali/services/prefs.dart';

class DownloadView extends StatelessWidget {
  const DownloadView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DownloadNotifier>(
      create: (context) => DownloadNotifier(),
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.downloadTitle),
          ),
          body: Consumer<DownloadNotifier>(
            builder: (context, downloadModel, child) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 50, // height fixed for two lines of text
                      alignment: Alignment.center,
                      child: Center(
                        child: ColoredText(
                          downloadModel.message,
                          maxLines: 2, // max two lines of text
                          overflow: TextOverflow
                              .ellipsis, // if the text is too long, show ellipsis
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (downloadModel.downloading ||
                        downloadModel.connectionChecking)
                      const CircularProgressIndicator(),
                    const SizedBox(
                      height: 20,
                    ),
                    FutureBuilder<bool>(
                      future: checkInternetConnection(downloadModel),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasData && snapshot.data!) {
                          return getFutureBuilder(context, downloadModel);
                        } else {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.signal_wifi_off,
                                    size: 80,
                                    color: (!Prefs.darkThemeOn)
                                        ? Theme.of(context)
                                            .appBarTheme
                                            .backgroundColor
                                        : null),
                                const SizedBox(
                                  height: 20,
                                ),
                                ColoredText(AppLocalizations.of(context)!
                                    .turnOnInternet),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> checkInternetConnection(DownloadNotifier downloadModel) async {
    if (downloadModel.downloading) {
      return true;
    }
    downloadModel.connectionChecking = true;
    bool hasInternet = await InternetConnection().hasInternetAccess;
    downloadModel.connectionChecking = false;
    return hasInternet;
  }

  getDownload(BuildContext context, DownloadNotifier dn,
      DownloadListItem downloadListItem) async {
    // give another check before downloading..
    // two times this is called..   to get the list.. and once before downloading
    // handled here in this view.
    if (await checkInternetConnection(dn)) {
      DownloadService downloadService = DownloadService(
          downloadNotifier: dn, downloadListItem: downloadListItem);

      dn.downloading = true;
      await downloadService.installSqlZip();
    } else {
      dn.message = "No Internet";
    }
  }

  getFutureBuilder(context, DownloadNotifier downloadModel) {
    if (downloadModel.downloading) {
      return const SizedBox.shrink();
    } else {
      return Expanded(
        child: FutureBuilder(
          future: http.get(Uri.parse(
              'https://github.com/bksubhuti/tpr_downloads/raw/master/download_source_files/download_list.json')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            List<DownloadListItem> dlList =
                downloadListItemFromJson(snapshot.data!.body);

            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: false,
              itemCount: dlList.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text("${dlList[index].name} ${dlList[index].size}"),
                    leading: Text(dlList[index].releaseDate),
                    onTap: () async {
                      await getDownload(context, downloadModel, dlList[index]);
                    },
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }
}
