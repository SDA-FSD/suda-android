/// Paywall mount 통계용 `screen` 값 (서버 contract).
///
/// 에너지 팝업 경로는 [energyPopup]으로 `energy_popup_{screen}` 형태.
/// [lab]은 mount/탭 impression 수집 제외.
class PaywallImpressionScreen {
  PaywallImpressionScreen._();

  static const String profile = 'profile';
  static const String account = 'account';
  /// Pre-split aggregate; legacy DB/Redis only — app no longer sends.
  static const String speechFeedbackLegacy = 'speech_feedback';
  static const String speechFeedbackRpResult = 'speech_feedback_rp_result';
  static const String speechFeedbackHistory = 'speech_feedback_history';
  static const String speechFeedbackViewChat = 'speech_feedback_view_chat';
  static const String rpResultGotIt = 'rp_result_got_it';
  static const String lab = 'lab';

  static String energyPopup(String energyOfferScreen) =>
      'energy_popup_$energyOfferScreen';

  static bool shouldCollect(String screen) => screen != lab;
}
