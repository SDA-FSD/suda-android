import 'dart:async' show unawaited;
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../config/app_config.dart';
import 'ios_audio_teardown.dart';

/// Result / View Chat / Profile Saved TTS.
/// iOS는 Playing과 같이 byte[]·CDN을 임시 파일로 받아 [AudioPlayer.setFilePath].
/// `data:` URI는 AVPlayer에서 첫 생성분 byte[]가 재생되지 않는다.
class SudaTtsAudioPlayer {
  AudioPlayer _player = AudioPlayer();
  String? _iosAudioPath;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> play() => _player.play();

  Future<AudioSource?> prepare({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) {
    if (Platform.isIOS) {
      return _prepareIos(
        cdnYn: cdnYn,
        cdnPath: cdnPath,
        soundBytes: soundBytes,
      );
    }
    return _prepareAndroid(
      cdnYn: cdnYn,
      cdnPath: cdnPath,
      soundBytes: soundBytes,
    );
  }

  void dispose() {
    final old = _player;
    final path = _iosAudioPath;
    _iosAudioPath = null;
    if (Platform.isIOS) {
      IosAudioTeardown.enqueue(() async {
        try {
          await old.stop();
        } catch (_) {}
        try {
          await old.dispose();
        } catch (_) {}
        _deleteAudioFileAt(path);
      });
    } else {
      unawaited(old.dispose());
      _deleteAudioFileAt(path);
    }
  }

  Future<AudioSource?> _prepareAndroid({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    await stop();
    if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
      final url = '${AppConfig.cdnBaseUrl}$cdnPath';
      final source = AudioSource.uri(Uri.parse(url));
      await _player.setAudioSource(source);
      return source;
    }
    if (soundBytes != null && soundBytes.isNotEmpty) {
      final source = AudioSource.uri(
        Uri.dataFromBytes(soundBytes, mimeType: 'audio/mpeg'),
      );
      await _player.setAudioSource(source);
      return source;
    }
    debugPrint(
      '[DEBUG] SudaTtsAudio source empty: cdnYn=$cdnYn cdnPath=$cdnPath bytes=${soundBytes?.length ?? 0}',
    );
    return null;
  }

  Future<AudioSource?> _prepareIos({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    await IosAudioTeardown.wait();
    await _activateIosPlaybackSession();
    try {
      await _player.stop().timeout(IosAudioTeardown.jobTimeout);
    } catch (_) {
      await _recreateIos();
    }

    Future<AudioSource?> load() async {
      Uint8List? bytes =
          (soundBytes != null && soundBytes.isNotEmpty) ? soundBytes : null;
      if (bytes == null && cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
        bytes = await _downloadCdnBytes('${AppConfig.cdnBaseUrl}$cdnPath');
      }
      if (bytes == null || bytes.isEmpty) {
        debugPrint(
          '[DEBUG] SudaTtsAudio source empty: cdnYn=$cdnYn cdnPath=$cdnPath bytes=${soundBytes?.length ?? 0}',
        );
        return null;
      }
      return _loadIosFromBytes(bytes);
    }

    try {
      return await load();
    } catch (e) {
      debugPrint('[DEBUG] SudaTtsAudio iOS prepare error: $e');
      await _recreateIos();
      await _activateIosPlaybackSession();
      try {
        if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
          final downloaded =
              await _downloadCdnBytes('${AppConfig.cdnBaseUrl}$cdnPath');
          return await _loadIosFromBytes(downloaded);
        }
        return await load();
      } catch (e2) {
        debugPrint('[DEBUG] SudaTtsAudio iOS prepare retry error: $e2');
        return null;
      }
    }
  }

  Future<void> _activateIosPlaybackSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      await session.setActive(true);
    } catch (e) {
      debugPrint('[DEBUG] SudaTtsAudio iOS audio session: $e');
    }
  }

  Future<void> _recreateIos() async {
    final old = _player;
    _player = AudioPlayer();
    IosAudioTeardown.enqueue(() async {
      try {
        await old.stop();
      } catch (_) {}
      try {
        await old.dispose();
      } catch (_) {}
    });
    await IosAudioTeardown.wait();
  }

  Future<AudioSource> _loadIosFromBytes(Uint8List bytes) async {
    _deleteIosAudioFile();
    final ext = _detectAudioExt(bytes);
    final path =
        '${Directory.systemTemp.path}/suda_tts_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(path).writeAsBytes(bytes, flush: true);
    _iosAudioPath = path;
    final source = AudioSource.file(path);
    await _player.setFilePath(path).timeout(const Duration(seconds: 8));
    return source;
  }

  Future<Uint8List> _downloadCdnBytes(String url) async {
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      throw StateError(
        'cdn http ${resp.statusCode} bytes=${resp.bodyBytes.length}',
      );
    }
    return Uint8List.fromList(resp.bodyBytes);
  }

  void _deleteIosAudioFile() {
    final path = _iosAudioPath;
    _iosAudioPath = null;
    _deleteAudioFileAt(path);
  }

  static String _detectAudioExt(Uint8List bytes) {
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45) {
      return 'wav';
    }
    return 'mp3';
  }

  static void _deleteAudioFileAt(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
