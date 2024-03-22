import 'package:tipitaka_pali/services/prefs.dart';

class PaliTools {
  PaliTools._();
  static String velthuisToUni({required String velthiusInput}) {
    if (velthiusInput.isEmpty) return velthiusInput;
    if (Prefs.disableVelthuis) return velthiusInput;

    const nigahita = 'ṃ';
    const capitalNigahita = 'Ṃ';

    final uni = velthiusInput
        .replaceAll('aa', 'ā')
        .replaceAll('ii', 'ī')
        .replaceAll('uu', 'ū')
        .replaceAll('.t', 'ṭ')
        .replaceAll('.d', 'ḍ')
        .replaceAll('"n', 'ṅ') // double quote
        .replaceAll('\u201Dn', 'ṅ') // \u201D = Right Double Quotation Mark
        .replaceAll('“n', 'ṅ') // apple curly quote
        .replaceAll('”n', 'ṅ') // apple curlyquote
        .replaceAll(';n', 'ṅ') // my easier vel ṅ
        .replaceAll('~n', 'ñ')
        .replaceAll(';y', 'ñ') // my easier vel ñ
        .replaceAll('.n', 'ṇ')
        .replaceAll('.m', nigahita)
        .replaceAll('\u1E41', nigahita) // ṁ
        .replaceAll('.l', 'ḷ')
        .replaceAll('AA', 'Ā')
        .replaceAll('II', 'Ī')
        .replaceAll('UU', 'Ū')
        .replaceAll('.T', 'Ṭ')
        .replaceAll('.D', 'Ḍ')
        .replaceAll('"N', 'Ṅ')
        .replaceAll('\u201DN', 'Ṅ')
        .replaceAll('~N', 'Ñ')
        .replaceAll('.N', 'Ṇ')
        .replaceAll('.M', capitalNigahita)
        .replaceAll('\u1E40', capitalNigahita) // Ṁ
        .replaceAll('.L', 'Ḷ')
        .replaceAll('.ll', 'ḹ')
        .replaceAll('.r', 'ṛ')
        .replaceAll('.rr', 'ṝ')
        .replaceAll('.s', 'ṣ')
        .replaceAll('"s', 'ś')
        .replaceAll('\u201Ds', 'ś')
        .replaceAll('.h', 'ḥ');

    return uni;
  }
}
