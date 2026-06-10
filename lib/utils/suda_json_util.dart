import '../models/common_models.dart';
import 'language_util.dart';

class SudaJsonUtil {
  static Map<String, String> localizedMapFromJson(dynamic value) {
    if (value == null) return const {};
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
      );
    }
    return const {};
  }

  static String localizedMapText(
    Map<String, String>? values, {
    String? languageCode,
  }) {
    if (values == null || values.isEmpty) return '';
    final langCode = languageCode ?? LanguageUtil.getCurrentLanguageCode();
    final localized = values[langCode];
    if (localized != null && localized.isNotEmpty) return localized;
    final english = values['en'];
    if (english != null && english.isNotEmpty) return english;
    return values.values.firstWhere((v) => v.isNotEmpty, orElse: () => '');
  }

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
