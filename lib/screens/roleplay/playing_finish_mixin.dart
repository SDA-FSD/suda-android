import 'dart:async' show unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../api/endpoints/series_api.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import 'playing_conversation_mixin.dart';
import 'playing_input_mixin.dart';

/// S2 Playing 세션 종료 — `PUT /rps2/sessions/{id}/finish` 및 분기(A/B/C).
///
/// 트리거:
/// - 사용자 유발 API 404 → finish 시도 → 실패 시 즉시 Try Again, `0`이면 3초 메시지 후 Try Again
/// - 마지막 사용자 발화 응답 직후 finish 백그라운드 호출 → 나레이션·AI·분석중 후 전환
mixin PlayingFinishMixin<T extends StatefulWidget>
    on State<T>, PlayingInputMixin<T>, PlayingConversationMixin<T> {
  bool _finishRequested = false;
  Future<int?>? _finishFuture;
  bool _finishDispatchStarted = false;
  bool _lastTurnPresentationComplete = false;

  /// 사용자 유발 RpS2 세션 API가 404일 때 호출.
  void onRpS2SessionNotFound() {
    if (_finishDispatchStarted || !mounted) return;
    unawaited(_handleSessionExpiredFinish());
  }

  /// 마지막 사용자 발화 응답 수신 직후 호출.
  void requestFinishAfterLastUserResponse() {
    if (_finishRequested) return;
    _finishRequested = true;
    _finishFuture = _callFinishApi();
    _finishFuture!.whenComplete(() {
      if (mounted && _lastTurnPresentationComplete) {
        unawaited(_tryDispatchFinishAfterLastTurn());
      }
    });
  }

  /// 마지막 턴 나레이션·후속 AI 종료 후 분석중 blink 시작 시점에 호출.
  void onLastTurnPresentationComplete() {
    _lastTurnPresentationComplete = true;
    unawaited(_tryDispatchFinishAfterLastTurn());
  }

  Future<int?> _callFinishApi() async {
    final accessToken = await TokenStorage.loadAccessToken();
    final sessionId = SeriesStateService.instance.sessionId;
    if (accessToken == null || sessionId == null || sessionId.isEmpty) {
      return null;
    }
    try {
      return await SudaApiClient.finishRpS2Session(
        accessToken: accessToken,
        rpSessionId: sessionId,
      );
    } on RpS2SessionNotFoundException catch (e) {
      debugPrint('[DEBUG] RpS2 finish session not found: $e');
      return null;
    } catch (e, st) {
      debugPrint('[DEBUG] RpS2 finish error: $e\n$st');
      return null;
    }
  }

  Future<void> _handleSessionExpiredFinish() async {
    if (_finishDispatchStarted) return;
    _finishDispatchStarted = true;
    _lockPlayingForFinish();

    if (!_finishRequested) {
      _finishRequested = true;
      _finishFuture = _callFinishApi();
    }

    final finishResult = await _finishFuture;
    if (!mounted) return;

    if (finishResult == null) {
      RoleplayRouter.replaceWithTryAgain(context);
      return;
    }

    if (finishResult <= 0) {
      await _showTransitionThenNavigateToTryAgain();
      return;
    }

    await _dispatchSuccessFinish(finishResult);
  }

  Future<void> _tryDispatchFinishAfterLastTurn() async {
    if (_finishDispatchStarted || !_lastTurnPresentationComplete) return;
    if (!_finishRequested || _finishFuture == null) return;

    final finishResult = await _finishFuture;
    if (!mounted || _finishDispatchStarted) return;
    _finishDispatchStarted = true;
    _lockPlayingForFinish();
    stopPlayingAnalyzingBlink();

    if (finishResult == null) {
      showPlayingServiceMessage('Network Error', persistent: true);
      return;
    }

    if (finishResult <= 0) {
      await _showTransitionThenNavigateToTryAgain();
      return;
    }

    await _dispatchSuccessFinish(finishResult);
  }

  void _lockPlayingForFinish() {
    deactivateUserTurnHandler?.call();
    lockPlayingInputForSessionEnd();
    unawaited(stopPlayingConversationAudio());
  }

  Future<void> _showTransitionThenNavigateToTryAgain() async {
    final l10n = AppLocalizations.of(context)!;
    showPlayingEndedServiceMessage(l10n.roleplayFinishNotEnoughProgress);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    RoleplayRouter.replaceWithTryAgain(context);
  }

  Future<void> _dispatchSuccessFinish(int rpUserHistoryId) async {
    final l10n = AppLocalizations.of(context)!;
    final isLastEpisode = SeriesStateService.instance.isLastEpisode;
    final transitionMessage = isLastEpisode
        ? l10n.roleplayFinishMovingToEnding
        : l10n.roleplayFinishCompleted;

    showPlayingEndedServiceMessage(transitionMessage);

    final futures = <Future<dynamic>>[
      Future<void>.delayed(const Duration(seconds: 3)),
      _fetchUserHistoryWithRetry(rpUserHistoryId),
    ];

    if (isLastEpisode) {
      final imgPath = SeriesStateService.instance.overview?.endingImgPath;
      if (imgPath != null && imgPath.isNotEmpty && mounted) {
        final imageUrl = '${AppConfig.cdnBaseUrl}$imgPath';
        futures.add(
          precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          ).then((_) => null),
        );
      }
    }

    RpS2UserHistoryDto? history;
    try {
      final results = await Future.wait(futures);
      history = results[1] as RpS2UserHistoryDto?;
    } catch (e, st) {
      debugPrint('[DEBUG] RpS2 finish dispatch error: $e\n$st');
    }

    if (!mounted) return;

    if (history == null) {
      showPlayingServiceMessage('Network Error', persistent: true);
      return;
    }

    SeriesStateService.instance.setCachedUserHistory(history);

    if (isLastEpisode) {
      RoleplayRouter.replaceWithEnding(context);
    } else {
      RoleplayRouter.replaceWithResultV2(context);
    }
  }

  Future<RpS2UserHistoryDto?> _fetchUserHistoryWithRetry(int rpUserHistoryId) async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (accessToken == null) return null;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await SudaApiClient.getRpS2UserHistory(
          accessToken: accessToken,
          rpUserHistoryId: rpUserHistoryId,
        );
      } catch (e, st) {
        debugPrint(
          '[DEBUG] RpS2 getUserHistory error(attempt=$attempt): $e\n$st',
        );
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (!mounted) return null;
          continue;
        }
        return null;
      }
    }
    return null;
  }
}
