import 'package:flutter/material.dart';
import 'package:tipitaka_pali/business_logic/models/tpr_message.dart';
import 'package:tipitaka_pali/services/get_database_status.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:tipitaka_pali/ui/screens/splash_screen.dart';

Future<bool> _isInternetAvailable() async {
  return await InternetConnection().hasInternetAccess;
}

Future<TprMessage> fetchMessageIfNeeded() async {
  TprMessage tprMessage = TprMessage();
  String storedMessage = Prefs.message;
  DateTime currentDate = DateTime.now();
  String formattedCurrentDate =
      "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

  DatabaseStatus databaseStatus = getDatabaseStatus();
  if (databaseStatus != DatabaseStatus.uptoDate) {
    return tprMessage;
  }

  // Check if the message has already been fetched today
  DateTime lastCheckedDate = DateTime.parse(Prefs.lastDateCheckedMessage);
  if (lastCheckedDate.year == currentDate.year &&
      lastCheckedDate.month == currentDate.month &&
      lastCheckedDate.day == currentDate.day) {
    // Message was already fetched today
    return tprMessage;
  }

  // If there is no internet, use the stored message.
  if (!await _isInternetAvailable()) {
    return tprMessage;
  }

  // Fetch the message from the internet
  try {
    final response = await http.get(Uri.parse(
        'https://github.com/bksubhuti/tipitaka-pali-reader/raw/master/messages.json'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      tprMessage = TprMessage.fromJson(data);

      // You can now use messageDetails object
      // For example: messageDetails.generalMessage
      // Store the fetched message and date
      Prefs.message = tprMessage.generalMessage;
      Prefs.lastDateCheckedMessage = formattedCurrentDate;

      // ...rest of your logic, like storing messages or comparing dates...

      return tprMessage; // return the object
    } else {
      debugPrint('Failed to load message');
      return tprMessage;
    }
  } catch (e) {
    return tprMessage;
  }
}
