import 'dart:typed_data';

import '../models/auth_models.dart';
import '../models/home_models.dart';
import '../models/pagination.dart';
import '../models/roleplay_models.dart';
import '../models/user_models.dart';
import '../models/version_models.dart';
import 'endpoints/auth_api.dart';
import 'endpoints/feedback_api.dart';
import 'endpoints/home_api.dart';
import 'endpoints/notice_api.dart';
import 'endpoints/push_api.dart';
import 'endpoints/roleplay_api.dart';
import 'endpoints/user_api.dart';
import 'endpoints/version_api.dart';

class SudaApiClient {
  static Future<HomeDto> getHomeContents({
    required String accessToken,
  }) {
    return HomeApi.getHomeContents(accessToken: accessToken);
  }

  static Future<SudaAppPage<AppHomeRoleplayDto>> getRoleplaysByCategory({
    required String accessToken,
    required int categoryId,
    required int pageNum,
  }) {
    return HomeApi.getRoleplaysByCategory(
      accessToken: accessToken,
      categoryId: categoryId,
      pageNum: pageNum,
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

  static Future<RoleplaySessionDto> createRoleplaySession({
    required String accessToken,
    required int roleplayId,
    required int roleId,
  }) {
    return RoleplayApi.createRoleplaySession(
      accessToken: accessToken,
      roleplayId: roleplayId,
      roleId: roleId,
    );
  }

  static Future<RoleplayUserMessageResponseDto> sendRoleplayUserMessageText({
    required String accessToken,
    required String rpSessionId,
    required String text,
  }) {
    return RoleplayApi.sendUserMessageText(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      text: text,
    );
  }

  static Future<RoleplayUserMessageResponseDto> sendRoleplayUserMessageAudio({
    required String accessToken,
    required String rpSessionId,
    required Uint8List audioData,
  }) {
    return RoleplayApi.sendUserMessageAudio(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      audioData: audioData,
    );
  }

  static Future<RoleplayAiMessageDto> getRoleplayAiMessage({
    required String accessToken,
    required String rpSessionId,
  }) {
    return RoleplayApi.getAiMessage(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<RoleplayNarrationDto> getRoleplayNarration({
    required String accessToken,
    required String rpSessionId,
  }) {
    return RoleplayApi.getNarration(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<String> getRoleplayHint({
    required String accessToken,
    required String rpSessionId,
  }) {
    return RoleplayApi.getHint(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<RoleplayAiMessageDto> getRoleplayHintAudio({
    required String accessToken,
    required String rpSessionId,
  }) {
    return RoleplayApi.getHintAudio(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
    );
  }

  static Future<RoleplayAiMessageDto> getRoleplayHintWordAudio({
    required String accessToken,
    required String rpSessionId,
    required int wordIndex,
  }) {
    return RoleplayApi.getHintWordAudio(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      wordIndex: wordIndex,
    );
  }

  static Future<String> getRoleplayTranslation({
    required String accessToken,
    required String rpSessionId,
    required int index,
  }) {
    return RoleplayApi.getTranslation(
      accessToken: accessToken,
      rpSessionId: rpSessionId,
      index: index,
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

  /// GET /v1/roleplays/results?pageNum=0 (0-based, 9 per page)
  static Future<SudaAppPage<RpSimpleResultDto>> getRoleplayResults({
    required String accessToken,
    required int pageNum,
  }) {
    return RoleplayApi.getResults(
      accessToken: accessToken,
      pageNum: pageNum,
    );
  }

  static Future<RoleplayResultDto> getRoleplayResult({
    required String accessToken,
    required int resultId,
  }) {
    return RoleplayApi.getRoleplayResult(
      accessToken: accessToken,
      resultId: resultId,
    );
  }

  /// GET /v1/roleplays/results-reload/{resultId} (operator refresh test; 2xx → dto, else null)
  static Future<RoleplayResultDto?> getRoleplayResultReload({
    required String accessToken,
    required int resultId,
  }) {
    return RoleplayApi.getRoleplayResultReload(
      accessToken: accessToken,
      resultId: resultId,
    );
  }

  /// GET /v1/roleplays/{rpId}/roles/{rpRoleId}/endings/{endingId}
  static Future<RoleplayEndingDto> getRoleplayEnding({
    required String accessToken,
    required int rpId,
    required int rpRoleId,
    required int endingId,
  }) {
    return RoleplayApi.getRoleplayEnding(
      accessToken: accessToken,
      rpId: rpId,
      rpRoleId: rpRoleId,
      endingId: endingId,
    );
  }

  static Future<void> updateRoleplayResultStar({
    required String accessToken,
    required int resultId,
    required int star,
  }) {
    return RoleplayApi.updateRoleplayResultStar(
      accessToken: accessToken,
      resultId: resultId,
      star: star,
    );
  }

  /// POST /v1/roleplays/results/{roleplayResultId}/report, body: { "content": content }
  static Future<void> sendResultReport({
    required String accessToken,
    required int roleplayResultId,
    required String content,
  }) {
    return RoleplayApi.sendResultReport(
      accessToken: accessToken,
      roleplayResultId: roleplayResultId,
      content: content,
    );
  }

  static Future<VersionDto> getLatestVersion() {
    return VersionApi.getLatestVersion();
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

  static Future<UserDto> getCurrentUser({
    required String accessToken,
  }) {
    return UserApi.getCurrentUser(accessToken: accessToken);
  }

  static Future<ProfileDto> getUserProfile({
    required String accessToken,
  }) {
    return UserApi.getUserProfile(accessToken: accessToken);
  }

  static Future<UserTicketDto> getUserTicket({
    required String accessToken,
  }) {
    return UserApi.getUserTicket(accessToken: accessToken);
  }

  static Future<QuestResultDto> claimDailyTicket({
    required String accessToken,
  }) {
    return UserApi.claimDailyTicket(accessToken: accessToken);
  }

  static Future<void> updateName({
    required String accessToken,
    required String name,
  }) {
    return UserApi.updateName(accessToken: accessToken, name: name);
  }

  static Future<void> deleteUser({
    required String accessToken,
  }) {
    return UserApi.deleteUser(accessToken: accessToken);
  }

  static Future<void> deleteProfileImage({
    required String accessToken,
  }) {
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

  static Future<void> completeTutorial({
    required String accessToken,
  }) {
    return UserApi.completeTutorial(accessToken: accessToken);
  }

  static Future<void> updateAgreement({
    required String accessToken,
  }) {
    return UserApi.updateAgreement(accessToken: accessToken);
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

  static Future<QuestResultDto> postUserQuest({
    required String accessToken,
    required String questId,
  }) {
    return UserApi.postUserQuest(
      accessToken: accessToken,
      questId: questId,
    );
  }

  static Future<String> submitSurvey({
    required String accessToken,
    required int age,
    required int gender,
    required int source,
  }) {
    return UserApi.submitSurvey(
      accessToken: accessToken,
      age: age,
      gender: gender,
      source: source,
    );
  }

  static Future<void> sendFeedback({
    required String accessToken,
    required String content,
  }) {
    return FeedbackApi.sendFeedback(accessToken: accessToken, content: content);
  }

  /// GET /v1/users/notification?pageNum=… (pageNum은 0부터)
  static Future<List<NotificationDto>> getNotifications({
    required String accessToken,
    required int pageNum,
  }) {
    return UserApi.getNotifications(
      accessToken: accessToken,
      pageNum: pageNum,
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
    return NoticeApi.getNotice(
      accessToken: accessToken,
      noticeId: noticeId,
    );
  }
}
