import '../models/common_models.dart';
import 'language_util.dart';

class SudaJsonUtil {
  static String localizedText(List<SudaJson>? values, {String? languageCode}) {
    if (values == null || values.isEmpty) return '';
    final langCode = languageCode ?? LanguageUtil.getCurrentLanguageCode();
    for (final value in values) {
      if (value.key == langCode) return value.value;
    }
    for (final value in values) {
      if (value.key == 'en') return value.value;
    }
    return values.first.value;
  }

  static String englishText(List<SudaJson>? values) {
    if (values == null || values.isEmpty) return '';
    for (final value in values) {
      if (value.key == 'en') return value.value;
    }
    return values.first.value;
  }
}
