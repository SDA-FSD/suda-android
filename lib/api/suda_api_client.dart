import 'dart:typed_data';

import '../models/auth_models.dart';
import '../models/home_models.dart';
import '../models/pagination.dart';
import '../models/roleplay_models.dart';
import '../models/series_models.dart';
import '../models/user_models.dart';
import '../models/version_models.dart';
import 'endpoints/auth_api.dart';
import 'endpoints/feedback_api.dart';
import 'endpoints/home_api.dart';
import 'endpoints/notice_api.dart';
import 'endpoints/purchase_api.dart';
import 'endpoints/push_api.dart';
import 'endpoints/roleplay_api.dart';
import 'endpoints/series_api.dart';
import 'endpoints/user_api.dart';
import 'endpoints/version_api.dart';
import '../services/subscription_status_cache.dart';

class SudaApiClient {
  static Future<HomeDto> getHomeContents({required String accessToken}) {
    return HomeApi.getHomeContents(accessToken: accessToken);
  }

  static Future<SudaAppPage<HomeSeriesDto>> getSeriesByCategory({
    required String accessToken,
    required String categoryEnumValue,
    required int pageNum,
  }) {
    return HomeApi.getSeriesByCategory(
      accessToken: accessToken,
      categoryEnumValue: categoryEnumValue,
      pageNum: pageNum,
    );
  }

  static Future<RpS2SeriesOverviewDto> getSeriesOverview({
    required String accessToken,
    required int seriesId,
  }) {
    return SeriesApi.getSeriesOverview(
      accessToken: accessToken,
      seriesId: seriesId,
    );
  }

  static Future<Map<int, int>> getSeriesBestScore({
    required String accessToken,
    required int seriesId,
  }) {
    return SeriesApi.getSeriesBestScore(
      accessToken: accessToken,
      seriesId: seriesId,
    );
  }

  static Future<RpS2SessionDto> createRpS2Session({
    required String accessToken,
    required int seriesId,
    required int episodeId,
  }) {
    return SeriesApi.createSession(
      accessToken: accessToken,
      seriesId: seriesId,
      episodeId: episodeId,
    );
  }

  static Future<String> getRpS2Translation({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) {
    return SeriesApi.getSessionTranslation(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      rpMsgId: rpMsgId,
    );
  }

  static Future<RpS2HintDto> getRpS2Hint({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) {
    return SeriesApi.getSessionHint(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      rpMsgId: rpMsgId,
    );
  }

  static Future<void> markRpS2HintDelivered({
    required String accessToken,
    required String rpSessionId,
    required int rpMsgId,
  }) {
    return SeriesApi.markSessionHintDelivered(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      rpMsgId: rpMsgId,
    );
  }

  static Future<TtsResultDto> getRpS2HintSound({
    required String accessToken,
    required String rpSessionId,
  }) {
    return SeriesApi.getSessionHintSound(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<TtsResultDto> getRpS2HintWordSound({
    required String accessToken,
    required String rpSessionId,
    required int wordIndex,
  }) {
    return SeriesApi.getSessionHintWordSound(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      wordIndex: wordIndex,
    );
  }

  static Future<RpS2UserMessageResponseDto> sendRpS2UserMessageAudio({
    required String accessToken,
    required String rpSessionId,
    required Uint8List audioData,
  }) {
    return SeriesApi.sendSessionUserMessageAudio(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      audioData: audioData,
    );
  }

  static Future<RpS2UserMessageResponseDto> sendRpS2UserMessageText({
    required String accessToken,
    required String rpSessionId,
    required String text,
  }) {
    return SeriesApi.sendSessionUserMessageText(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      text: text,
    );
  }

  static Future<RpS2SoundResDto> getRpS2AiMessageAudio({
    required String accessToken,
    required String rpSessionId,
  }) {
    return SeriesApi.getSessionAiMessageAudio(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<int> finishRpS2Session({
    required String accessToken,
    required String rpSessionId,
  }) {
    return SeriesApi.finishSession(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<RpS2UserHistoryDto> getRpS2UserHistory({
    required String accessToken,
    required int rpUserHistoryId,
  }) {
    return SeriesApi.getUserHistory(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
    );
  }

  /// GET /rps2/user-histories?pageNum=0 (0-based)
  static Future<SudaAppPage<RpS2SimpleHistoryDto>> getRpS2UserHistories({
    required String accessToken,
    required int pageNum,
  }) {
    return SeriesApi.getUserHistories(
      accessToken: accessToken,
      pageNum: pageNum,
    );
  }

  static Future<void> updateRpS2UserStarRating({
    required String accessToken,
    required int rpUserHistoryId,
    required int userStarRating,
  }) {
    return SeriesApi.updateUserStarRating(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
      userStarRating: userStarRating,
    );
  }

  /// POST /rps2/user-histories/{rpUserHistoryId}/report, body: { "content": content }
  static Future<void> sendRpS2UserHistoryReport({
    required String accessToken,
    required int rpUserHistoryId,
    required String content,
  }) {
    return SeriesApi.sendUserHistoryReport(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
      content: content,
    );
  }

  static Future<TtsResultDto> getRpS2UserHistoryExpressionSound({
    required String accessToken,
    required int rpUserHistoryId,
    required int expressionIndex,
  }) {
    return SeriesApi.getUserHistoryExpressionSound(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
      expressionIndex: expressionIndex,
    );
  }

  static Future<void> saveRpS2UserHistoryExpression({
    required String accessToken,
    required int rpUserHistoryId,
    required int expressionIndex,
  }) {
    return SeriesApi.saveUserHistoryExpression(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
      expressionIndex: expressionIndex,
    );
  }

  static Future<void> deleteRpS2UserHistoryExpression({
    required String accessToken,
    required int rpUserHistoryId,
    required int expressionIndex,
  }) {
    return SeriesApi.deleteUserHistoryExpression(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
      expressionIndex: expressionIndex,
    );
  }

  static Future<TtsResultDto> getRpS2UserHistoryMessageAudio({
    required String accessToken,
    required int rpUserHistoryId,
    required int rpMsgId,
  }) {
    return SeriesApi.getUserHistoryMessageAudio(
      accessToken: accessToken,
      rpUserHistoryId: rpUserHistoryId,
      rpMsgId: rpMsgId,
    );
  }

  static Future<RoleplayOverviewDto> getRoleplayOverview({
    required String accessToken,
    required int roleplayId,
  }) {
    return RoleplayApi.getRoleplayOverview(
      accessToken: accessToken,
      roleplayId: roleplayId,
    );
  }

  static Future<void> updateRoleplaySpeedRate({
    required String accessToken,
    required String speedRate,
  }) {
    return RoleplayApi.updateSpeedRate(
      accessToken: accessToken,
      speedRate: speedRate,
    );
  }

  static Future<VersionDto> getLatestVersion({
    required String clientVersion,
  }) {
    return VersionApi.getLatestVersion(clientVersion: clientVersion);
  }

  static Future<SudaAuthTokens> loginWithGoogle({
    required String idToken,
    required String deviceId,
  }) {
    return AuthApi.loginWithGoogle(idToken: idToken, deviceId: deviceId);
  }

  static Future<SudaAuthTokens> refreshToken({
    required String refreshToken,
    required String deviceId,
  }) {
    return AuthApi.refreshToken(refreshToken: refreshToken, deviceId: deviceId);
  }

  static Future<void> logout({
    required String refreshToken,
    required String deviceId,
  }) {
    return AuthApi.logout(refreshToken: refreshToken, deviceId: deviceId);
  }

  static Future<UserDto> getCurrentUser({required String accessToken}) {
    return UserApi.getCurrentUser(accessToken: accessToken);
  }

  static Future<ProfileDto> getUserProfile({required String accessToken}) {
    return UserApi.getUserProfile(accessToken: accessToken);
  }

  static Future<UserEnergyDto> getUserEnergy({required String accessToken}) async {
    final dto = await UserApi.getUserEnergy(accessToken: accessToken);
    SubscriptionStatusCache.apply(dto);
    return dto;
  }

  static Future<void> updateName({
    required String accessToken,
    required String name,
  }) {
    return UserApi.updateName(accessToken: accessToken, name: name);
  }

  static Future<void> deleteUserExpression({
    required String accessToken,
    required int rpResultId,
    required int expressionIndex,
  }) {
    return UserApi.deleteUserExpression(
      accessToken: accessToken,
      rpResultId: rpResultId,
      expressionIndex: expressionIndex,
    );
  }

  static Future<List<UserExpressionDto>> getUserExpressions({
    required String accessToken,
    int pageNum = 0,
  }) {
    return UserApi.getUserExpressions(
      accessToken: accessToken,
      pageNum: pageNum,
    );
  }

  static Future<void> deleteUser({required String accessToken}) {
    return UserApi.deleteUser(accessToken: accessToken);
  }

  static Future<void> deleteProfileImage({required String accessToken}) {
    return UserApi.deleteProfileImage(accessToken: accessToken);
  }

  static Future<void> registerPushToken({
    required String accessToken,
    required String pushToken,
    required String languageCode,
  }) {
    return PushApi.registerPushToken(
      accessToken: accessToken,
      pushToken: pushToken,
      languageCode: languageCode,
    );
  }

  static Future<void> completeTutorial({required String accessToken}) {
    return UserApi.completeTutorial(accessToken: accessToken);
  }

  static Future<void> tutorialShown({required String accessToken}) {
    return UserApi.tutorialShown(accessToken: accessToken);
  }

  static Future<void> postFirstOverview({required String accessToken}) {
    return UserApi.postFirstOverview(accessToken: accessToken);
  }

  static Future<void> updateAgreement({required String accessToken}) {
    return UserApi.updateAgreement(accessToken: accessToken);
  }

  static Future<void> grantWelcomeGift({required String accessToken}) {
    return UserApi.grantWelcomeGift(accessToken: accessToken);
  }

  static Future<void> updateLanguageLevel({
    required String accessToken,
    required String languageLevel,
  }) {
    return UserApi.updateLanguageLevel(
      accessToken: accessToken,
      languageLevel: languageLevel,
    );
  }

  static Future<QuestResultDto> updatePushAgreement({
    required String accessToken,
    required String agreementYn,
  }) {
    return UserApi.updatePushAgreement(
      accessToken: accessToken,
      agreementYn: agreementYn,
    );
  }

  static Future<void> sendFeedback({
    required String accessToken,
    required String content,
  }) {
    return FeedbackApi.sendFeedback(accessToken: accessToken, content: content);
  }

  /// POST /v1/purchases/verify — 구매 검증 (`successYn` / `pendingYn`).
  static Future<PurchaseVerifyResultDto> verifyPurchase({
    required String accessToken,
    required String purchaseToken,
    required String productId,
  }) {
    return PurchaseApi.verifyPurchase(
      accessToken: accessToken,
      purchaseToken: purchaseToken,
      productId: productId,
    );
  }

  /// GET /v1/users/notification?pageNum=… (pageNum은 0부터)
  static Future<List<NotificationDto>> getNotifications({
    required String accessToken,
    required int pageNum,
  }) {
    return UserApi.getNotifications(accessToken: accessToken, pageNum: pageNum);
  }

  /// POST /v1/users/notification/{notificationId}/read
  static Future<QuestResultDto> markNotificationRead({
    required String accessToken,
    required int notificationId,
  }) {
    return UserApi.markNotificationRead(
      accessToken: accessToken,
      notificationId: notificationId,
    );
  }

  /// GET /v1/notice?page=0&size=10
  static Future<SudaAppPage<AppNoticeDto>> getNotices({
    required String accessToken,
    required int page,
    int size = 10,
  }) {
    return NoticeApi.getNotices(
      accessToken: accessToken,
      page: page,
      size: size,
    );
  }

  /// GET /v1/notice/{noticeId}. Returns null on 404.
  static Future<AppNoticeDto?> getNotice({
    required String accessToken,
    required int noticeId,
  }) {
    return NoticeApi.getNotice(accessToken: accessToken, noticeId: noticeId);
  }
}
