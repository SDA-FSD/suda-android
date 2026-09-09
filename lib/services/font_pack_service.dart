import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../config/font_pack_catalog.dart';
import '../utils/language_util.dart';

/// locale에 맞는 CDN 폰트 팩을 캐시·등록한다.
///
/// 기동은 번들 `latn`을 등록하고, 캐시된 locale 팩을 합친 뒤 네트워크는
/// 최대 [_bootDownloadWait]만 기다린다. 같은 family에 팩을 추가할 때는
/// [FontLoader]로 해당 family 전체를 다시 올려 글리프가 덮이지 않게 한다.
class FontPackService {
  FontPackService._();
  static final FontPackService instance = FontPackService._();

  static const _downloadTimeout = Duration(seconds: 15);
  static const _bootDownloadWait = Duration(seconds: 4);

  final Set<String> _registered = {};

  Future<void> loadForCurrentLocale() async {
    await _addPack(FontPackCatalog.bundledPackId);
    final wanted = FontPackCatalog.packsForLocale(
      LanguageUtil.localizationLookupKeys(),
    );
    await _registerCached(wanted);
    final download = _downloadMissing(wanted);
    try {
      await download.timeout(_bootDownloadWait);
    } on TimeoutException {
      debugPrint('[DEBUG] FontPack boot wait elapsed; remaining packs continue');
    }
  }

  Future<void> _registerCached(List<String> wanted) async {
    for (final family in FontPackCatalog.families) {
      for (final packId in FontPackCatalog.packsForFamily(family, wanted)) {
        if (packId == FontPackCatalog.bundledPackId) continue;
        final file = await _cacheFile(family, packId);
        if (!file.existsSync() || file.lengthSync() < 1024) continue;
        await _addPack(packId, family: family);
      }
    }
  }

  Future<void> _downloadMissing(List<String> wanted) async {
    for (final family in FontPackCatalog.families) {
      for (final packId in FontPackCatalog.packsForFamily(family, wanted)) {
        if (packId == FontPackCatalog.bundledPackId) continue;
        if (_registered.contains(_key(family, packId))) continue;
        try {
          final file = await _downloadToCache(family, packId);
          if (file == null) continue;
          await _addPack(packId, family: family);
        } catch (e) {
          debugPrint('[DEBUG] FontPack download $family-$packId: $e');
        }
      }
    }
  }

  Future<void> _addPack(String packId, {String? family}) async {
    final families =
        family == null ? FontPackCatalog.families : <String>[family];
    final changed = <String>[];
    for (final f in families) {
      if (!FontPackCatalog.publishedPacks[f]!.contains(packId)) continue;
      final key = _key(f, packId);
      if (_registered.contains(key)) continue;
      final bytes = await _readPackBytes(f, packId);
      if (bytes == null || bytes.length < 1024) continue;
      _registered.add(key);
      changed.add(f);
    }
    for (final f in changed) {
      await _reloadFamily(f);
    }
  }

  Future<void> _reloadFamily(String family) async {
    final packIds = _registered
        .where((k) => k.startsWith('$family-'))
        .map((k) => k.substring(family.length + 1))
        .toList();
    if (packIds.isEmpty) return;
    final loader = FontLoader(family);
    for (final packId in packIds) {
      final bytes = await _readPackBytes(family, packId);
      if (bytes == null || bytes.length < 1024) continue;
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
    // OS `fontsChange`와 같이 Text relayout. protected hook.
    // ignore: invalid_use_of_protected_member
    await PaintingBinding.instance.handleSystemMessage(
      <String, dynamic>{'type': 'fontsChange'},
    );
    debugPrint('[DEBUG] FontPack family $family packs=$packIds');
  }

  Future<Uint8List?> _readPackBytes(String family, String packId) async {
    if (packId == FontPackCatalog.bundledPackId) {
      final asset = FontPackCatalog.bundledAsset[family];
      if (asset == null) return null;
      final data = await rootBundle.load(asset);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    final file = await _cacheFile(family, packId);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  Future<File?> _downloadToCache(String family, String packId) async {
    final dest = await _cacheFile(family, packId);
    if (dest.existsSync() && dest.lengthSync() > 1024) return dest;
    final uri = Uri.parse(
      '${AppConfig.cdnBaseUrl}${FontPackCatalog.cdnPath(family, packId)}',
    );
    final resp = await http.get(uri).timeout(_downloadTimeout);
    if (resp.statusCode != 200 || resp.bodyBytes.length < 1024) {
      debugPrint(
        '[DEBUG] FontPack http ${resp.statusCode} $uri bytes=${resp.bodyBytes.length}',
      );
      return null;
    }
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(resp.bodyBytes, flush: true);
    return dest;
  }

  Future<File> _cacheFile(String family, String packId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(
      '${dir.path}/fonts/${FontPackCatalog.version}/${FontPackCatalog.fileName(family, packId)}',
    );
  }

  String _key(String family, String packId) => '$family-$packId';
}
