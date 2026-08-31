// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get agreementHeading =>
      'Để tiếp tục, vui lòng xem và đồng ý với các điều khoản dưới đây.';

  @override
  String get agreementTermsLabel => 'Tôi đồng ý với Điều khoản sử dụng.';

  @override
  String get agreementPrivacyLabel =>
      'Tôi đồng ý với Chính sách quyền riêng tư.';

  @override
  String get agreementTermsTitle => 'Điều khoản sử dụng';

  @override
  String get agreementPrivacyTitle => 'Chính sách quyền riêng tư';

  @override
  String get agreementDetailsLink => 'Xem chi tiết';

  @override
  String get agreementButtonConfirm => 'Đồng ý và tiếp tục';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsAccount => 'Tài khoản';

  @override
  String get settingsRestorePurchases => 'Khôi phục giao dịch mua';

  @override
  String get restorePurchasesNothing =>
      'Không có giao dịch mua nào để khôi phục.';

  @override
  String get restorePurchasesCompleted => 'Đã khôi phục giao dịch mua.';

  @override
  String get settingsNotification => 'Thông báo';

  @override
  String get settingsTutorial => 'Hướng dẫn';

  @override
  String get settingsCefrLevel => 'Trình độ tiếng Anh';

  @override
  String get pushNotifications => 'Thông báo đẩy';

  @override
  String get pushNotificationsDesc =>
      'Nhận lời nhắc và các cập nhật quan trọng.';

  @override
  String get settingsFeedback => 'Góp ý';

  @override
  String get settingsAnnouncements => 'Tin mới';

  @override
  String get announcementsEmpty => 'Chưa có thông báo';

  @override
  String get noticesEmpty => 'Chưa có bài đăng';

  @override
  String get deletedPost => 'Bài đăng này đã bị xóa.';

  @override
  String get postNoLongerAvailable => 'Bài đăng này không còn xem được.';

  @override
  String get backToHome => 'Về trang chủ';

  @override
  String get settingsSignOut => 'Đăng xuất';

  @override
  String get settingsFsdLaboratory => 'Phòng thí nghiệm FSD';

  @override
  String get settingsPrivacy => 'Chính sách quyền riêng tư';

  @override
  String get settingsTerms => 'Điều khoản dịch vụ';

  @override
  String get settingsOpenSource => 'Giấy phép mã nguồn mở';

  @override
  String loginWelcome(String name) {
    return 'Chào mừng $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Khi tiếp tục, bạn đồng ý với $terms và $privacy của chúng tôi.';
  }

  @override
  String get loginTermsTitle => 'Điều khoản sử dụng';

  @override
  String get loginPrivacyTitle => 'Chính sách quyền riêng tư';

  @override
  String get loginCatchphrase => 'Cứ nói đi. Đó là cách bạn học.';

  @override
  String get loginWelcomeTitle => 'Chào mừng bạn đến với SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Bước vào câu chuyện và bắt đầu nói tiếng Anh!';

  @override
  String get loginErrorIdToken =>
      'Không thể lấy mã xác thực Google. Vui lòng thử lại.';

  @override
  String loginErrorFailed(String error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String get accountName => 'Tên';

  @override
  String get accountInfo => 'Tài khoản';

  @override
  String get accountDelete => 'Xóa tài khoản';

  @override
  String get accountDeleteTitle => 'Xóa tài khoản?';

  @override
  String get accountDeleteConfirmText =>
      'Toàn bộ tiến trình và dữ liệu của bạn sẽ bị xóa vĩnh viễn. Bạn chắc chắn muốn tiếp tục?';

  @override
  String get accountDeleteProfileImageTitle => 'Xóa ảnh đại diện?';

  @override
  String get accountDeleteProfileImageContent =>
      'Ảnh đại diện đã xóa sẽ không thể khôi phục.';

  @override
  String get accountGoBack => 'Quay lại';

  @override
  String get accountDeleteAction => 'Xóa';

  @override
  String get accountSubscription => 'Gói đăng ký';

  @override
  String get accountFreePlanTitle => 'Gói miễn phí';

  @override
  String get accountFreePlanSubtitle =>
      'Đăng ký Premium để mở khóa thêm tính năng';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Bạn đang sử dụng các quyền lợi Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Tự động gia hạn vào $date';
  }

  @override
  String get accountChangePlan => 'Đổi gói';

  @override
  String get changePlanTitle => 'Đổi gói';

  @override
  String get changePlanCurrentPlan => 'Gói hiện tại';

  @override
  String get changePlanAvailablePlans => 'Các gói hiện có';

  @override
  String changePlanRenewsOn(String date) {
    return 'Tự động gia hạn vào $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Không thể tải thông tin. Vui lòng thử lại.';

  @override
  String get changePlanRetry => 'Thử lại';

  @override
  String get changePlanConfirmTitle => 'Đổi gói?';

  @override
  String get changePlanConfirmBody =>
      'Gói mới sẽ có hiệu lực vào ngày thanh toán tiếp theo.';

  @override
  String get changePlanConfirmOk => 'Xác nhận';

  @override
  String get changePlanConfirmCancel => 'Giữ gói hiện tại';

  @override
  String get changePlanOldPurchaseMissing =>
      'Không tìm thấy gói đăng ký đang hoạt động để thay đổi. Hãy thử lại sau khi gói được kích hoạt.';

  @override
  String get changePlanChangeRequested =>
      'Đã yêu cầu đổi gói. Thay đổi có thể được áp dụng vào ngày thanh toán tiếp theo.';

  @override
  String get cefrLevelTitle => 'Chọn trình độ tiếng Anh của bạn';

  @override
  String get cefrLevelAbsoluteBeginner => 'Mới bắt đầu';

  @override
  String get cefrLevelBeginner => 'Sơ cấp';

  @override
  String get cefrLevelBasic => 'Cơ bản';

  @override
  String get cefrLevelIntermediate => 'Trung cấp';

  @override
  String get firstCefrLevelTitle => 'Trình độ tiếng Anh của bạn là gì?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Tôi có thể đọc tiếng Anh';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Tôi biết các câu chào hỏi và cụm từ đơn giản';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Tôi có thể hiểu và dùng các câu ngắn, đơn giản';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Tôi có thể nêu ý kiến và tham gia hội thoại hằng ngày';

  @override
  String get firstCefrLevelSettingsHint => 'Bạn có thể thay đổi bất cứ lúc nào';

  @override
  String get firstCefrLevelConfirm => 'Xác nhận';

  @override
  String get feedbackPlaceholder =>
      'Hãy chia sẻ cảm nhận, đề xuất hoặc vấn đề bạn gặp phải...';

  @override
  String get feedbackSend => 'Gửi';

  @override
  String get feedbackSuccess => 'Cảm ơn bạn đã góp ý.';

  @override
  String get microphonePermissionDenied =>
      'Không thể bắt đầu khi chưa có quyền dùng micrô.';

  @override
  String get holdMicrophoneToSpeak => 'Nhấn giữ micrô để nói';

  @override
  String get roleplayTypeMessagePlaceholder => 'Nhập câu trả lời...';

  @override
  String get yourTurnFirst => 'Bạn nói trước nhé!';

  @override
  String get sayLineBelowToStart => 'Hãy nói câu bên dưới để bắt đầu.';

  @override
  String get roleplayExitWait => 'Khoan đã!';

  @override
  String get roleplayExitMessage =>
      'Nếu thoát bây giờ, bạn sẽ mất phần thưởng. Bạn vẫn muốn thoát?';

  @override
  String get roleplayExitKeepPlaying => 'Chơi tiếp';

  @override
  String get roleplayExitExit => 'Thoát';

  @override
  String get roleplayAutoHint => 'Gợi ý tự động';

  @override
  String get roleplayHintLabel => 'Gợi ý';

  @override
  String get roleplayHintShowAnswer =>
      'Nhấn để xem gợi ý trả lời bằng tiếng Anh';

  @override
  String get roleplayVoiceSpeed => 'Tốc độ giọng đọc';

  @override
  String get roleplayEndedFailed => 'Nhiệm vụ thất bại...';

  @override
  String get roleplayEndedComplete => 'Đã hoàn thành phần nhập vai';

  @override
  String get roleplayEndedEnding => 'Đang chuyển đến phần kết...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Chưa đủ tiến độ';

  @override
  String get roleplayFinishCompleted => 'Đã hoàn thành phần nhập vai';

  @override
  String get roleplayFinishMovingToEnding => 'Đang chuyển đến phần kết...';

  @override
  String get roleplayAnalyzing => 'Đang phân tích phần nhập vai của bạn...';

  @override
  String get roleplayOpeningAiCharacter => 'Nhân vật AI';

  @override
  String get roleplayOpeningScenario => 'Tình huống';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI có thể mắc lỗi.\nĐừng chia sẻ thông tin cá nhân hoặc thông tin nhạy cảm.';

  @override
  String get endingFailTitle => 'Bạn chưa hoàn thành tất cả nhiệm vụ!';

  @override
  String get endingFailSubtitle => 'Thử lại để khám phá toàn bộ câu chuyện.';

  @override
  String get roleplayTryAgainMessage =>
      'Tiếc quá, điểm của bạn chưa đủ để nhận phần thưởng.';

  @override
  String get endingReport => 'Báo cáo sự cố';

  @override
  String get endingHowWas => 'Phần nhập vai vừa rồi thế nào?';

  @override
  String get endingNext => 'Tiếp';

  @override
  String get reportTitle => 'Báo cáo sự cố';

  @override
  String get profileHistory => 'Lịch sử';

  @override
  String get profileSaved => 'Đã lưu';

  @override
  String get profileHistoryEmpty => 'Chưa có lịch sử';

  @override
  String get profileSavedEmpty => 'Chưa có mẫu câu nào được lưu.';

  @override
  String get profileSavedRemoveTitle => 'Bỏ khỏi mục Đã lưu?';

  @override
  String get profileSavedRemoveContent =>
      'Bạn có thể tìm lại mẫu câu này trong Lịch sử.';

  @override
  String get profileSavedRemoveOk => 'Bỏ lưu';

  @override
  String get profileSavedRemoveCancel => 'Luyện tập thêm';

  @override
  String get seriesOverviewTabEpisodes => 'Tập';

  @override
  String get seriesOverviewTabSimilarTopic => 'Chủ đề tương tự';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Tập #$number';
  }

  @override
  String get seriesOverviewPlay => 'Chơi';

  @override
  String get seriesOverviewLocked => 'Đã khóa';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Hoàn thành tập trước để mở khóa.';

  @override
  String get notificationPermissionBlockedTitle => 'Thông báo đang tắt';

  @override
  String get notificationPermissionBlockedMessage =>
      'Bật thông báo trong phần cài đặt của thiết bị để nhận thông báo đẩy.';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get notificationsEmpty => 'Chưa có thông báo';

  @override
  String get notificationSendToday => 'Hôm nay';

  @override
  String get notificationSendOneDayAgo => '1 ngày trước';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Bạn có thể đăng ký lại sau 2 ngày kể từ khi xóa tài khoản. Vui lòng thử lại sau.';

  @override
  String get expressionSavedToProfile => 'Đã lưu vào hồ sơ';

  @override
  String get expressionUnsavedToProfile => 'Đã bỏ lưu';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Chưa thể đưa ra phản hồi vì câu trả lời quá ngắn. Hãy thử dùng ít nhất 7 từ!';

  @override
  String get roleplayResultScoreMeaning => 'Ý nghĩa';

  @override
  String get roleplayResultScoreRelevance => 'Độ phù hợp';

  @override
  String get roleplayResultScoreVocabulary => 'Từ vựng';

  @override
  String get roleplayResultScoreGrammar => 'Ngữ pháp';

  @override
  String get closePopup => 'Đóng';

  @override
  String get reviewChatTapHint => 'Nhấn vào tin nhắn để phát âm thanh.';

  @override
  String get reviewChatNoAudioToPlay => 'Không có âm thanh để phát.';

  @override
  String get seriesInformationTopicDifficulty => 'Độ khó của chủ đề';

  @override
  String get seriesInformationLearningGoals => 'Mục tiêu học tập';

  @override
  String get energyInfoTitle => 'Năng lượng';

  @override
  String get energyOutOfEnergyTitle => 'Hết năng lượng';

  @override
  String get energyInfoRechargeUntil => 'Năng lượng sẽ hồi sau @@TIME@@';

  @override
  String get energyInfoFull => 'Năng lượng đã đầy.';

  @override
  String get energyInfoUnlimitedEndsIn =>
      'Chế độ không giới hạn đang hoạt động';

  @override
  String get energyInsufficient => 'Bạn không có đủ năng lượng.';

  @override
  String get endRoleplay => 'Kết thúc nhập vai';

  @override
  String get energyEnablePushTitle => 'Bật thông báo';

  @override
  String get energyEnablePushSubtitle => 'Bật thông báo để nạp đầy năng lượng.';

  @override
  String get energyEnablePushPrice => 'Miễn phí';

  @override
  String get energyEnablePushOfferBadge => 'ƯU ĐÃI MỘT LẦN';

  @override
  String get energyEnablePushCompleted => 'Đã nạp đầy năng lượng!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Vé chơi không giới hạn';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Có hiệu lực ngay sau khi mua và kéo dài 10 phút.';

  @override
  String get energyPurchaseCapacityTitle => 'Nâng giới hạn năng lượng';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Tăng vĩnh viễn giới hạn năng lượng thêm 1 điểm.';

  @override
  String get energyGoPremiumTitle => 'Nâng cấp lên Premium';

  @override
  String get energyGoPremiumExplore => 'Khám phá';

  @override
  String get profileGoPremiumTitle => 'Đăng ký SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Khám phá';

  @override
  String get energyPurchasePendingApproval =>
      'Thanh toán của bạn đang chờ phê duyệt.';

  @override
  String get energyPurchaseNotCompleted => 'Giao dịch mua chưa hoàn tất.';

  @override
  String get iapPurchaseProcessing => 'Giao dịch mua đang được xử lý.';

  @override
  String get iapPurchaseCompleted => 'Giao dịch mua đã hoàn tất.';

  @override
  String get welcomeGiftTitle => 'Quà chào mừng đã đến!';

  @override
  String get welcomeGiftBenefitLead => 'Chơi không giới hạn trong 10 phút!';

  @override
  String get welcomeGiftLine2 => 'Đã mở khóa các tính năng Premium';

  @override
  String get welcomeGiftLine3 => 'Đã mở khóa chế độ chơi không giới hạn';

  @override
  String get welcomeGiftStartNow => 'Chơi ngay';

  @override
  String get paywallHeroTitle1 => 'Luyện tập nhiều hơn';

  @override
  String get paywallHeroTitle2 => 'Tiến bộ nhanh hơn';

  @override
  String get paywallHeroBody =>
      'Luyện tập lâu hơn với Premium và nhận phản hồi từ AI để tự tin nói tiếng Anh.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Luyện tập nhiều hơn mỗi ngày';

  @override
  String get paywallBenefitMaxEnergy => 'Năng lượng tối đa lên đến 30';

  @override
  String get paywallBenefitAiFeedback => 'AI góp ý từng câu';

  @override
  String get paywallChoosePlan => 'Chọn gói của bạn';

  @override
  String get paywallAnnualPlanTitle => 'Gói năm';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Tiết kiệm hơn 33% so với gói theo tháng.';

  @override
  String get paywallMonthlyPlanTitle => 'Gói tháng';

  @override
  String get paywallMonthlyPlanSubtitle => 'Linh hoạt theo từng tháng.';

  @override
  String get paywallBestBadge => 'TỐT NHẤT';

  @override
  String get paywallCta => 'Đăng ký ngay';

  @override
  String get paywallAutoRenewNotice =>
      'Gói đăng ký sẽ tự động gia hạn, trừ khi bạn hủy ít nhất 24 giờ trước khi kỳ thanh toán hiện tại kết thúc.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/tháng';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/năm';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '220.833 ₫';

  @override
  String get paywallFallbackAnnual => '2.650.000 ₫';

  @override
  String get paywallFallbackMonthly => '367.000 ₫';

  @override
  String get paywallFallbackMonthlyTimes12 => '4.404.000 ₫';

  @override
  String get paywallCompletedTitle => 'Chúc mừng!';

  @override
  String get paywallCompletedBody =>
      'Các quyền lợi Premium của bạn đã được kích hoạt.';

  @override
  String get paywallCompletedContinue => 'Tiếp tục';

  @override
  String get roleplayChooseYourRole => 'Chọn vai của bạn';

  @override
  String get roleplaySimilarRoleplays => 'Roleplay tương tự';

  @override
  String get roleplayBeingPrepared => 'Roleplay này đang được chuẩn bị.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Hoàn thành mọi ending của vai trước để mở khóa vai này.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return 'Hoàn thành $percent%';
  }

  @override
  String get roleplayTurnGradeA => 'wow!';

  @override
  String get roleplayTurnGradeB => 'ok!';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'ồ…';

  @override
  String get tutorialPage1Title =>
      'Xem **Nhiệm vụ** của bạn\nvà bắt đầu trò chuyện.';

  @override
  String get tutorialPage1Tip =>
      '*Mẹo: Bạn nói càng tự nhiên,\nphần thưởng càng lớn!';

  @override
  String get tutorialPage2Title => 'Dùng **Trình dịch**\nkhi bạn không hiểu.';

  @override
  String get tutorialPage3Title => 'Dùng **Gợi ý**\nkhi bạn bị kẹt.';

  @override
  String get tutorialPage3Subtitle =>
      'Bạn có thể bật hoặc tắt\ngợi ý tự động bất cứ lúc nào.';

  @override
  String get tutorialPage4Title =>
      'Nếu phát âm khó,\nhãy nghe trước rồi nhắc lại.';

  @override
  String get tutorialPage4Tip =>
      '*Mẹo: Hãy trả lời mà không nhìn bản dịch\nđể được điểm cao hơn.';

  @override
  String get tutorialPage5Title => 'Không thể nói to?';

  @override
  String get tutorialPage5Subtitle => 'Chuyển sang **Chế độ văn bản**.';

  @override
  String get tutorialPage6Title => 'Không ai đang đánh giá bạn.\nBạn làm được!';
}
