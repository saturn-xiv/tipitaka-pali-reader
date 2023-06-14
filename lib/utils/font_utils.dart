import 'package:tipitaka_pali/utils/pali_script_converter.dart';

class FontUtils {
  FontUtils._();

  static String? getfontName({required Script script}) {
    switch (script) {
      case Script.myanmar:
        return 'PyidaungSu';
      case Script.sinhala:
        return 'NotoSansSinhala';
      case Script.devanagari:
        return 'NotoSansDevanagari';
      case Script.laos:
        return 'Lao Pali Regular';
      default:
        return null;
    }
  }
}
