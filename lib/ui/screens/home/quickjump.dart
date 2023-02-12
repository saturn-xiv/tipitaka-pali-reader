import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/database/database_helper.dart';

import '../../../business_logic/models/book.dart';
import '../../../services/repositories/paragraph_repo.dart';
import '../../../utils/platform_info.dart';
import '../../widgets/colored_text.dart';
import '../reader/mobile_reader_container.dart';
import 'openning_books_provider.dart';
//import 'package:provider/provider.dart';
//import 'package:tipitaka_pali/data/constants.dart';

//import '../settings/download_view.dart';

class QuickJumpPage extends StatefulWidget {
  const QuickJumpPage({Key? key}) : super(key: key);

  @override
  State<QuickJumpPage> createState() => _QuickJumpPageState();
}

class _QuickJumpPageState extends State<QuickJumpPage> {
  late TextEditingController _controller;
  late bool _isValid;
  @override
  void initState() {
    _controller = TextEditingController();
    _isValid = false;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.quickjump),
          actions: const [],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 150,
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32.0),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextField(
                        decoration: InputDecoration(border: InputBorder.none),
                        maxLines: 1,
                        controller: _controller,
                        onSubmitted: (text) {
                          quickJump(context, text);
                        }),
                  ),
                  const SizedBox(width: 50),
                  FloatingActionButton(
                      onPressed: () {
                        quickJump(context, _controller.text);
                      },
                      child: const Text("go")),
                ],
              ),
              const ColoredText(
                  "You may use shortcut \nnotation to jump to a sutta:\n\nExample:\n\nmn118\nMajjhima Sutta 118\n\ndn10\nDīgha sutta 10\n\nsn5.20 \nsaṃyutta 5 sutta 20\n\nan4.50 \nbook 4 and sutta 50"),
            ],
          ),
        ));
  }

  quickJump(BuildContext context, String qj) async {
    Book book = Book(id: "mula_di_01", name: "dn");
    _isValid = false; // let the if statements turn it true;

    if (qj.toLowerCase().contains("dn")) {
      book = getDnBookDetails(qj, book); // get the number
    }
    if (qj.toLowerCase().contains("mn")) {
      book = getMnBookDetails(qj, book); // get the number
    }
    if (qj.toLowerCase().contains("sn")) {
      final snFormat = RegExp(r'^sn\d+\.\d+$');
      if (snFormat.hasMatch(qj)) {
        book = await getSnBookDetails(qj, book);
      } // get the number
    }
    if (qj.toLowerCase().contains("an")) {
      final anFormat = RegExp(r'^an\d+\.\d+$');
      if (anFormat.hasMatch(qj)) {
        book = await getAnBookDetails(qj, book); // get the number
      }
    }

    if (_isValid) {
      final openningBookProvider = context.read<OpenningBooksProvider>();
      openningBookProvider.add(book: book, currentPage: book.firstPage
          // textToHighlight: searchWord,
          );
    }
/*
      if (Mobile.isPhone(context)) {
        // Navigator.pushNamed(context, readerRoute,
          //   arguments: {'book': bookItem.book});
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MobileReaderContrainer()));
      }
    }
*/
  }

  Book getDnBookDetails(String qj, Book book) {
    int suttaNumber = -1;
    _isValid = true;
    String aStr = qj.replaceAll(RegExp(r'[^0-9]'), ''); // '23'
    if (aStr.trim().contains(RegExp(r'[0-9]'))) {
      suttaNumber = int.parse(aStr);
    }
    int openPage = 1;
    switch (suttaNumber) {
      case 1:
        openPage = 1;
        break;
      case 2:
        openPage = 44;
        break;
      case 3:
        openPage = 82;
        break;
      case 4:
        openPage = 104;
        break;
      case 5:
        openPage = 120;
        break;
      case 6:
        openPage = 143;
        break;
      case 7:
        openPage = 151;
        break;
      case 8:
        openPage = 153;
        break;
      case 9:
        openPage = 167;
        break;
      case 10:
        openPage = 188;
        break;
      case 11:
        openPage = 205;
        break;
      case 12:
        openPage = 214;
        break;
      case 13:
        openPage = 222;
        break;
      case 14:
        openPage = 1;
        break;
      case 15:
        openPage = 47;
        break;
      case 16:
        openPage = 61;
        break;
      case 17:
        openPage = 139;
        break;
      case 18:
        openPage = 162;
        break;
      case 19:
        openPage = 178;
        break;
      case 20:
        openPage = 203;
        break;
      case 21:
        openPage = 211;
        break;
      case 22:
        openPage = 231;
        break;
      case 23:
        openPage = 253;
        break;
      case 24:
        openPage = 1;
        break;
      case 25:
        openPage = 30;
        break;
      case 26:
        openPage = 48;
        break;
      case 27:
        openPage = 66;
        break;
      case 28:
        openPage = 82;
        break;
      case 29:
        openPage = 97;
        break;
      case 30:
        openPage = 117;
        break;
      case 31:
        openPage = 146;
        break;
      case 32:
        openPage = 158;
        break;
      case 33:
        openPage = 175;
        break;
      case 34:
        openPage = 227;
        break;
      default:
        _isValid = false;
    }

    book.firstPage = openPage;
    book.id = getDnBookID(suttaNumber);

    return book;
  }

  String getDnBookID(int suttaNumber) {
    String bookId = "mula_di_01";
    // if 14 or higher change
    // if higher than 23 change again to 3rd vol
    if (suttaNumber > 13) {
      bookId = (suttaNumber <= 23) ? "mula_di_02" : "mula_di_03";
    }
    return bookId;
  }

  Book getMnBookDetails(String qj, Book book) {
    _isValid = true;
    int suttaNumber = -1;
    String aStr = qj.replaceAll(RegExp(r'[^0-9]'), ''); // '23'
    if (aStr.trim().contains(RegExp(r'[0-9]'))) {
      suttaNumber = int.parse(aStr);
    }
    int openPage = 1;
    switch (suttaNumber) {
      case 1:
        openPage = 1;
        break;
      case 2:
        openPage = 8;
        break;
      case 3:
        openPage = 15;
        break;
      case 4:
        openPage = 20;
        break;
      case 5:
        openPage = 29;
        break;
      case 6:
        openPage = 39;
        break;
      case 7:
        openPage = 43;
        break;
      case 8:
        openPage = 48;
        break;
      case 9:
        openPage = 57;
        break;
      case 10:
        openPage = 70;
        break;
      case 11:
        openPage = 92;
        break;
      case 12:
        openPage = 97;
        break;
      case 13:
        openPage = 118;
        break;
      case 14:
        openPage = 126;
        break;
      case 15:
        openPage = 132;
        break;
      case 16:
        openPage = 145;
        break;
      case 17:
        openPage = 149;
        break;
      case 18:
        openPage = 154;
        break;
      case 19:
        openPage = 161;
        break;
      case 20:
        openPage = 167;
        break;
      case 21:
        openPage = 92;
        break;
      case 22:
        openPage = 97;
        break;
      case 23:
        openPage = 118;
        break;
      case 24:
        openPage = 126;
        break;
      case 25:
        openPage = 132;
        break;
      case 26:
        openPage = 145;
        break;
      case 27:
        openPage = 149;
        break;
      case 28:
        openPage = 154;
        break;
      case 29:
        openPage = 161;
        break;
      case 30:
        openPage = 167;
        break;
      case 31:
        openPage = 173;
        break;
      case 32:
        openPage = 182;
        break;
      case 33:
        openPage = 195;
        break;
      case 34:
        openPage = 199;
        break;
      case 35:
        openPage = 205;
        break;
      case 36:
        openPage = 216;
        break;
      case 37:
        openPage = 232;
        break;
      case 38:
        openPage = 242;
        break;
      case 39:
        openPage = 250;
        break;
      case 40:
        openPage = 257;
        break;
      case 41:
        openPage = 266;
        break;
      case 42:
        openPage = 272;
        break;
      case 43:
        openPage = 281;
        break;
      case 44:
        openPage = 286;
        break;
      case 45:
        openPage = 289;
        break;
      case 46:
        openPage = 299;
        break;
      case 47:
        openPage = 318;
        break;
      case 48:
        openPage = 323;
        break;
      case 49:
        openPage = 338;
        break;
      case 50:
        openPage = 349;
        break;
      case 51:
        openPage = 1;
        break;
      case 52:
        openPage = 12;
        break;
      case 53:
        openPage = 16;
        break;
      case 54:
        openPage = 22;
        break;
      case 55:
        openPage = 31;
        break;
      case 56:
        openPage = 35;
        break;
      case 57:
        openPage = 50;
        break;
      case 58:
        openPage = 54;
        break;
      case 59:
        openPage = 59;
        break;
      case 60:
        openPage = 62;
        break;
      case 61:
        openPage = 77;
        break;
      case 62:
        openPage = 83;
        break;
      case 63:
        openPage = 89;
        break;
      case 64:
        openPage = 95;
        break;
      case 65:
        openPage = 100;
        break;
      case 66:
        openPage = 111;
        break;
      case 67:
        openPage = 119;
        break;
      case 68:
        openPage = 125;
        break;
      case 69:
        openPage = 133;
        break;
      case 70:
        openPage = 138;
        break;
      case 71:
        openPage = 148;
        break;
      case 72:
        openPage = 150;
        break;
      case 73:
        openPage = 156;
        break;
      case 74:
        openPage = 165;
        break;
      case 75:
        openPage = 169;
        break;
      case 76:
        openPage = 180;
        break;
      case 77:
        openPage = 194;
        break;
      case 78:
        openPage = 214;
        break;
      case 79:
        openPage = 221;
        break;
      case 80:
        openPage = 231;
        break;
      case 81:
        openPage = 236;
        break;
      case 82:
        openPage = 244;
        break;
      case 83:
        openPage = 262;
        break;
      case 84:
        openPage = 270;
        break;
      case 85:
        openPage = 277;
        break;
      case 86:
        openPage = 301;
        break;
      case 87:
        openPage = 309;
        break;
      case 88:
        openPage = 314;
        break;
      case 89:
        openPage = 320;
        break;
      case 90:
        openPage = 327;
        break;
      case 91:
        openPage = 334;
        break;
      case 92:
        openPage = 347;
        break;
      case 93:
        openPage = 354;
        break;
      case 94:
        openPage = 364;
        break;
      case 95:
        openPage = 375;
        break;
      case 96:
        openPage = 388;
        break;
      case 97:
        openPage = 395;
        break;
      case 98:
        openPage = 406;
        break;
      case 99:
        openPage = 413;
        break;
      case 100:
        openPage = 424;
        break;
      case 101:
        openPage = 1;
        break;
      case 102:
        openPage = 18;
        break;
      case 103:
        openPage = 26;
        break;
      case 104:
        openPage = 32;
        break;
      case 105:
        openPage = 39;
        break;
      case 106:
        openPage = 48;
        break;
      case 107:
        openPage = 52;
        break;
      case 108:
        openPage = 58;
        break;
      case 109:
        openPage = 66;
        break;
      case 110:
        openPage = 70;
        break;
      case 111:
        openPage = 75;
        break;
      case 112:
        openPage = 79;
        break;
      case 113:
        openPage = 86;
        break;
      case 114:
        openPage = 93;
        break;
      case 115:
        openPage = 106;
        break;
      case 116:
        openPage = 112;
        break;
      case 117:
        openPage = 116;
        break;
      case 118:
        openPage = 122;
        break;
      case 119:
        openPage = 130;
        break;
      case 120:
        openPage = 140;
        break;
      case 121:
        openPage = 147;
        break;
      case 122:
        openPage = 151;
        break;
      case 123:
        openPage = 159;
        break;
      case 124:
        openPage = 166;
        break;
      case 125:
        openPage = 169;
        break;
      case 126:
        openPage = 177;
        break;
      case 127:
        openPage = 184;
        break;
      case 128:
        openPage = 191;
        break;
      case 129:
        openPage = 201;
        break;
      case 130:
        openPage = 216;
        break;
      case 131:
        openPage = 226;
        break;
      case 132:
        openPage = 228;
        break;
      case 133:
        openPage = 231;
        break;
      case 134:
        openPage = 240;
        break;
      case 135:
        openPage = 243;
        break;
      case 136:
        openPage = 249;
        break;
      case 137:
        openPage = 258;
        break;
      case 138:
        openPage = 265;
        break;
      case 139:
        openPage = 273;
        break;
      case 140:
        openPage = 281;
        break;
      case 141:
        openPage = 291;
        break;
      case 142:
        openPage = 295;
        break;
      case 143:
        openPage = 301;
        break;
      case 144:
        openPage = 307;
        break;
      case 145:
        openPage = 311;
        break;
      case 146:
        openPage = 314;
        break;
      case 147:
        openPage = 324;
        break;
      case 148:
        openPage = 327;
        break;
      case 149:
        openPage = 335;
        break;
      case 150:
        openPage = 339;
        break;
      case 151:
        openPage = 342;
        break;
      case 152:
        openPage = 347;
        break;
      default:
        _isValid = false;
    }

    book.firstPage = openPage;
    book.id = getMnBookID(suttaNumber);
    book.name = "mn";

    return book;
  }

  String getMnBookID(suttaNumber) {
    String bookId = "mula_ma_01";
    // if 14 or higher change
    // if higher than 23 change again to 3rd vol
    if (suttaNumber > 50) {
      bookId = (suttaNumber <= 100) ? "mula_ma_02" : "mula_ma_03";
    }
    return bookId;
  }

  Future<Book> getSnBookDetails(String qj, Book book) async {
    _isValid = true;
    String aStr = qj.replaceAll(RegExp(r'[^0-9\.]'), '');
    String bookID = getSnBookID(aStr);
    int paranum = getSNParagraph(aStr);
    final dbHelper = DatabaseHelper();
    final paraRepo = ParagraphDatabaseRepository(dbHelper);
    book.firstPage = await paraRepo.getPageNumber(bookID, paranum);
    book.id = bookID;
    book.name = bookID;
    return book;
  } // get the number

  String getSnBookID(String notation) {
    // there are 55 samyuttas.
    // get the first number from the string
    String bookID = "mula_sa_01";
    var samyuttaAndSutta = notation.split('.');
    var samyutta = int.parse(samyuttaAndSutta[0]);
    if (samyutta <= 11) {
      bookID = "mula_sa_01";
    }
    if (samyutta >= 12 && samyutta <= 21) {
      bookID = "mula_sa_02";
    }
    if (samyutta >= 22 && samyutta <= 34) {
      bookID = "mula_sa_03";
    }
    if (samyutta >= 35 && samyutta <= 44) {
      bookID = "mula_sa_04";
    }
    if (samyutta >= 45 && samyutta <= 56) {
      bookID = "mula_sa_05";
    }

    return bookID;
  }

  String getAnBookID(String notation) {
    // there are 55 samyuttas.
    // get the first number from the string
    String bookID = "mula_an_0";
    var anguttaraBookSutta = notation.split('.');
    int anguttaraBook = int.parse(anguttaraBookSutta[0]);
    if (anguttaraBook < 10) {
      bookID = bookID + anguttaraBook.toString();
    } else {
      bookID = "mula_an_" + anguttaraBook.toString();
    }
    return bookID;
  }

  int getAnParagraph(String notation) {
    var anguttaraBookAndSutta = notation.split('.');
    //var book = int.parse(anguttaraBookAndSutta[0]);
    var sutta = int.parse(anguttaraBookAndSutta[1]);
    return sutta;
  }

  int getSNParagraph(String notation) {
    var samyuttaAndSutta = notation.split('.');
    var samyutta = int.parse(samyuttaAndSutta[0]);
    var sutta = int.parse(samyuttaAndSutta[1]) - 1;
    switch (samyutta) {
      case 1:
        return sutta;
      case 2:
        return 81 + sutta;
      case 3:
        return 111 + sutta;
      case 4:
        return 136 + sutta;
      case 5:
        return 161 + sutta;
      case 6:
        return 171 + sutta;
      case 7:
        return 186 + sutta;
      case 8:
        return 208 + sutta;
      case 9:
        return 220 + sutta;
      case 10:
        return 234 + sutta;
      case 11:
        return 246 + sutta;
      // book 2 below
      case 12:
        return sutta;
      case 13:
        return 74 + sutta;
      case 14:
        return 85 + sutta;
      case 15:
        return 124 + sutta;
      case 16:
        return 144 + sutta;
      case 17:
        return 157 + sutta;
      case 18:
        return 188 + sutta;
      case 19:
        return 202 + sutta;
      case 20:
        return 223 + sutta;
      case 21:
        return 235 + sutta;
      // book 3 below
      case 22:
        return sutta;
      case 23:
        return 160 + sutta;
      case 24:
        return 206 + sutta;
      case 25:
        return 302 + sutta;
      case 26:
        return 312 + sutta;
      case 27:
        return 322 + sutta;
      case 28:
        return 332 + sutta;
      case 29:
        return 342 + sutta;
      case 30:
        return 392 + sutta;
      case 31:
        return 438 + sutta;
      case 32:
        return 550 + sutta;
      case 33:
        return 607 + sutta;
      case 34:
        return 662 + sutta;
      // book 3 below
      case 35:
        return sutta;
      case 36:
        return 249 + sutta;
      case 37:
        return 280 + sutta;
      case 38:
        return 314 + sutta;
      case 39:
        return 330 + sutta;
      case 40:
        return 332 + sutta;
      case 41:
        return 343 + sutta;
      case 42:
        return 353 + sutta;
      case 43:
        return 366 + sutta;
      case 44:
        return 410 + sutta;
      // book 4 below
      case 45:
        return sutta;
      case 46:
        return 182 + sutta;
      case 47:
        return 367 + sutta;
      case 48:
        return 471 + sutta;
      case 49:
        return 651 + sutta;
      case 50:
        return 705 + sutta;
      case 51:
        return 813 + sutta;
      case 52:
        return 899 + sutta;
      case 53:
        return 923 + sutta;
      case 54:
        return 977 + sutta;
      case 55:
        return 997 + sutta;
      case 56:
        return 1071 + sutta;
      default:
        return 0;
    }
  }

  Future<Book> getAnBookDetails(String qj, Book book) async {
    // we will get some type of number like an4.12
    // an = anguttara
    // 4 = book number
    // 12 = paragraph or sutta number (they are the same)
    _isValid = true;
    String aStr = qj.replaceAll(RegExp(r'[^0-9\.]'), '');
    String bookID = getAnBookID(aStr);
    int paranum = getAnParagraph(aStr);
    final dbHelper = DatabaseHelper();
    final paraRepo = ParagraphDatabaseRepository(dbHelper);
    book.firstPage = await paraRepo.getPageNumber(bookID, paranum);
    book.id = bookID;
    book.name = bookID;
    return book;
  }
}
