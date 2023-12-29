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
      case Script.taitham:
        return 'NotoSansTaiTham';
      case Script.roman:
        return 'DejaVu Sans';
      //return 'Langar';
      default:
        return null;
    }
  }

  static String? getfontNameByLocale({required String locale}) {
    return switch (locale) {
      'en' => 'DejaVu Sans',
      //'en' => 'Langar',
      'my' => 'PyidaungSu',
      'si' => 'NotoSansSinhala',
      'hi' => 'NotoSansDevanagari',
      'lo' => 'Lao Pali Regular',
      _ => null,
    };
  }
}
