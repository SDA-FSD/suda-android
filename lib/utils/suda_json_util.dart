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

  /// tag → language → `en`. 없으면 null (다른 언어로 폴백하지 않음).
  static String? localizedMapTextOrNull(
    Map<String, String>? values, {
    String? languageCode,
  }) {
    if (values == null || values.isEmpty) return null;
    for (final key in LanguageUtil.localizationLookupKeys(
      languageCode: languageCode,
    )) {
      final localized = values[key];
      if (localized != null && localized.isNotEmpty) return localized;
    }
    return null;
  }

  static String localizedMapText(
    Map<String, String>? values, {
    String? languageCode,
  }) {
    if (values == null || values.isEmpty) return '';
    final matched = localizedMapTextOrNull(
      values,
      languageCode: languageCode,
    );
    if (matched != null) return matched;
    return values.values.firstWhere((v) => v.isNotEmpty, orElse: () => '');
  }

  static String localizedText(List<SudaJson>? values, {String? languageCode}) {
    if (values == null || values.isEmpty) return '';
    for (final key in LanguageUtil.localizationLookupKeys(
      languageCode: languageCode,
    )) {
      for (final value in values) {
        if (value.key == key && value.value.isNotEmpty) return value.value;
      }
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
