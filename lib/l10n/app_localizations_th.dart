// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get agreementHeading => 'อ่านและยอมรับข้อตกลงด้านล่างเพื่อใช้งานต่อ';

  @override
  String get agreementTermsLabel => 'ยอมรับข้อกำหนดการใช้งาน';

  @override
  String get agreementPrivacyLabel => 'ยอมรับนโยบายความเป็นส่วนตัว';

  @override
  String get agreementTermsTitle => 'ข้อกำหนดการใช้งาน';

  @override
  String get agreementPrivacyTitle => 'นโยบายความเป็นส่วนตัว';

  @override
  String get agreementDetailsLink => 'ดูรายละเอียด';

  @override
  String get agreementButtonConfirm => 'ยอมรับและไปต่อ';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get settingsAccount => 'บัญชี';

  @override
  String get settingsRestorePurchases => 'กู้คืนรายการซื้อ';

  @override
  String get restorePurchasesNothing => 'ไม่มีรายการซื้อให้กู้คืน';

  @override
  String get restorePurchasesCompleted => 'กู้คืนรายการซื้อแล้ว';

  @override
  String get settingsNotification => 'การแจ้งเตือน';

  @override
  String get settingsTutorial => 'บทแนะนำ';

  @override
  String get settingsCefrLevel => 'ระดับภาษาอังกฤษ';

  @override
  String get pushNotifications => 'การแจ้งเตือนแบบพุช';

  @override
  String get pushNotificationsDesc => 'รับการเตือนและอัปเดตสำคัญ';

  @override
  String get settingsFeedback => 'ความคิดเห็น';

  @override
  String get settingsAnnouncements => 'ประกาศ';

  @override
  String get announcementsEmpty => 'ยังไม่มีประกาศ';

  @override
  String get noticesEmpty => 'ยังไม่มีโพสต์';

  @override
  String get deletedPost => 'โพสต์นี้ถูกลบแล้ว';

  @override
  String get postNoLongerAvailable => 'โพสต์นี้ไม่สามารถดูได้แล้ว';

  @override
  String get backToHome => 'กลับหน้าหลัก';

  @override
  String get settingsSignOut => 'ออกจากระบบ';

  @override
  String get settingsFsdLaboratory => 'ห้องทดลอง FSD';

  @override
  String get settingsPrivacy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get settingsTerms => 'ข้อกำหนดการให้บริการ';

  @override
  String get settingsOpenSource => 'ใบอนุญาตโอเพนซอร์ส';

  @override
  String loginWelcome(String name) {
    return 'ยินดีต้อนรับ $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'เมื่อไปต่อ คุณยอมรับ $terms และ $privacy ของเรา';
  }

  @override
  String get loginTermsTitle => 'ข้อกำหนดการใช้งาน';

  @override
  String get loginPrivacyTitle => 'นโยบายความเป็นส่วนตัว';

  @override
  String get loginCatchphrase => 'แค่เริ่มพูด ก็เริ่มเรียนรู้ได้แล้ว';

  @override
  String get loginWelcomeTitle => 'ยินดีต้อนรับสู่ SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'ก้าวเข้าสู่เรื่องราว แล้วเริ่มพูดภาษาอังกฤษกัน!';

  @override
  String get loginErrorIdToken => 'ยืนยันตัวตนกับ Google ไม่สำเร็จ ลองอีกครั้ง';

  @override
  String loginErrorFailed(String error) {
    return 'เข้าสู่ระบบไม่สำเร็จ: $error';
  }

  @override
  String get accountName => 'ชื่อ';

  @override
  String get accountInfo => 'บัญชี';

  @override
  String get accountDelete => 'ลบบัญชี';

  @override
  String get accountDeleteTitle => 'ลบบัญชีไหม?';

  @override
  String get accountDeleteConfirmText =>
      'ความคืบหน้าและข้อมูลทั้งหมดจะถูกลบอย่างถาวรและกู้คืนไม่ได้ ต้องการลบบัญชีไหม?';

  @override
  String get accountDeleteProfileImageTitle => 'ลบรูปโปรไฟล์ไหม?';

  @override
  String get accountDeleteProfileImageContent =>
      'เมื่อลบแล้ว จะกู้คืนรูปโปรไฟล์ไม่ได้';

  @override
  String get accountGoBack => 'ย้อนกลับ';

  @override
  String get accountDeleteAction => 'ลบ';

  @override
  String get accountSubscription => 'การสมัครสมาชิก';

  @override
  String get accountFreePlanTitle => 'แพ็กเกจฟรี';

  @override
  String get accountFreePlanSubtitle =>
      'สมัคร Premium เพื่อปลดล็อกฟีเจอร์เพิ่มเติม';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'คุณกำลังใช้สิทธิประโยชน์ Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'ต่ออายุวันที่ $date';
  }

  @override
  String get accountChangePlan => 'เปลี่ยนแพ็กเกจ';

  @override
  String get changePlanTitle => 'เปลี่ยนแพ็กเกจ';

  @override
  String get changePlanCurrentPlan => 'แพ็กเกจปัจจุบัน';

  @override
  String get changePlanAvailablePlans => 'แพ็กเกจที่เลือกได้';

  @override
  String changePlanRenewsOn(String date) {
    return 'ต่ออายุวันที่ $date';
  }

  @override
  String get changePlanLoadFailed => 'โหลดข้อมูลไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get changePlanRetry => 'ลองอีกครั้ง';

  @override
  String get changePlanConfirmTitle => 'เปลี่ยนแพ็กเกจไหม?';

  @override
  String get changePlanConfirmBody =>
      'การเปลี่ยนแพ็กเกจจะมีผลในวันเรียกเก็บเงินรอบถัดไป';

  @override
  String get changePlanConfirmOk => 'ยืนยัน';

  @override
  String get changePlanConfirmCancel => 'ใช้แพ็กเกจเดิม';

  @override
  String get changePlanOldPurchaseMissing =>
      'ไม่พบการสมัครสมาชิกที่ใช้งานอยู่สำหรับเปลี่ยนแพ็กเกจ ลองอีกครั้งเมื่อการสมัครสมาชิกเปิดใช้งานแล้ว';

  @override
  String get changePlanChangeRequested =>
      'ส่งคำขอเปลี่ยนแพ็กเกจแล้ว การเปลี่ยนแปลงอาจมีผลในวันเรียกเก็บเงินรอบถัดไป';

  @override
  String get cefrLevelTitle => 'เลือกระดับภาษาอังกฤษของคุณ';

  @override
  String get cefrLevelAbsoluteBeginner => 'เริ่มต้นจากศูนย์';

  @override
  String get cefrLevelBeginner => 'เริ่มต้น';

  @override
  String get cefrLevelBasic => 'พื้นฐาน';

  @override
  String get cefrLevelIntermediate => 'ระดับกลาง';

  @override
  String get firstCefrLevelTitle => 'ภาษาอังกฤษของคุณอยู่ระดับไหน?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'ฉันอ่านภาษาอังกฤษได้';

  @override
  String get firstCefrLevelDescriptionA1 => 'ฉันรู้คำทักทายพื้นฐานและวลีง่าย ๆ';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'ฉันเข้าใจและใช้ประโยคสั้น ๆ ง่าย ๆ ได้';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'ฉันแสดงความคิดเห็นและร่วมบทสนทนาในชีวิตประจำวันได้';

  @override
  String get firstCefrLevelSettingsHint => 'เปลี่ยนได้ทุกเมื่อ';

  @override
  String get firstCefrLevelConfirm => 'ยืนยัน';

  @override
  String get feedbackPlaceholder =>
      'แชร์ความคิดเห็น ข้อเสนอแนะ หรือปัญหาที่พบ...';

  @override
  String get feedbackSend => 'ส่ง';

  @override
  String get feedbackSuccess => 'ขอบคุณสำหรับความคิดเห็น';

  @override
  String get microphonePermissionDenied =>
      'เริ่มไม่ได้หากไม่อนุญาตให้ใช้ไมโครโฟน';

  @override
  String get holdMicrophoneToSpeak => 'กดไมโครโฟนค้างไว้แล้วพูด';

  @override
  String get roleplayTypeMessagePlaceholder => 'พิมพ์ข้อความ...';

  @override
  String get yourTurnFirst => 'คุณพูดก่อนเลย!';

  @override
  String get sayLineBelowToStart => 'พูดประโยคด้านล่างเพื่อเริ่ม';

  @override
  String get roleplayExitWait => 'เดี๋ยวก่อน!';

  @override
  String get roleplayExitMessage =>
      'ถ้าออกตอนนี้ คุณจะพลาดรางวัล ยังต้องการออกไหม?';

  @override
  String get roleplayExitKeepPlaying => 'เล่นต่อ';

  @override
  String get roleplayExitExit => 'ออก';

  @override
  String get roleplayAutoHint => 'คำใบ้อัตโนมัติ';

  @override
  String get roleplayHintLabel => 'คำใบ้';

  @override
  String get roleplayHintShowAnswer => 'แตะเพื่อดูคำตอบภาษาอังกฤษที่แนะนำ';

  @override
  String get roleplayVoiceSpeed => 'ความเร็วในการพูด';

  @override
  String get roleplayEndedFailed => 'ทำภารกิจไม่สำเร็จ...';

  @override
  String get roleplayEndedComplete => 'โรลเพลย์เสร็จแล้ว';

  @override
  String get roleplayEndedEnding => 'กำลังไปยังตอนจบ...';

  @override
  String get roleplayFinishNotEnoughProgress => 'ความคืบหน้ายังไม่พอ';

  @override
  String get roleplayFinishCompleted => 'โรลเพลย์เสร็จแล้ว';

  @override
  String get roleplayFinishMovingToEnding => 'กำลังไปยังตอนจบ...';

  @override
  String get roleplayAnalyzing => 'กำลังวิเคราะห์โรลเพลย์ของคุณ...';

  @override
  String get roleplayOpeningAiCharacter => 'ตัวละคร AI';

  @override
  String get roleplayOpeningScenario => 'สถานการณ์';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI อาจผิดพลาดได้\nอย่าแชร์ข้อมูลส่วนตัวหรือข้อมูลที่ละเอียดอ่อน';

  @override
  String get endingFailTitle => 'คุณทำภารกิจไม่ครบ!';

  @override
  String get endingFailSubtitle => 'ลองอีกครั้งเพื่อดูเรื่องราวทั้งหมด';

  @override
  String get roleplayTryAgainMessage =>
      'น่าเสียดาย คะแนนของคุณยังไม่พอรับรางวัล';

  @override
  String get endingReport => 'รายงานปัญหา';

  @override
  String get endingHowWas => 'โรลเพลย์เป็นอย่างไรบ้าง?';

  @override
  String get endingNext => 'ถัดไป';

  @override
  String get reportTitle => 'รายงานปัญหา';

  @override
  String get profileHistory => 'ประวัติ';

  @override
  String get profileSaved => 'บันทึกไว้';

  @override
  String get profileHistoryEmpty => 'ยังไม่มีประวัติ';

  @override
  String get profileSavedEmpty => 'ยังไม่มีวลีที่บันทึกไว้';

  @override
  String get profileSavedRemoveTitle => 'นำออกจากรายการที่บันทึกไหม?';

  @override
  String get profileSavedRemoveContent => 'คุณยังค้นหาวลีนี้ได้ในประวัติ';

  @override
  String get profileSavedRemoveOk => 'นำออก';

  @override
  String get profileSavedRemoveCancel => 'ฝึกต่อ';

  @override
  String get seriesOverviewTabEpisodes => 'ตอน';

  @override
  String get seriesOverviewTabSimilarTopic => 'หัวข้อคล้ายกัน';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'ตอนที่ #$number';
  }

  @override
  String get seriesOverviewPlay => 'เล่น';

  @override
  String get seriesOverviewLocked => 'ล็อกอยู่';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'เล่นตอนก่อนหน้าให้จบเพื่อปลดล็อก';

  @override
  String get notificationPermissionBlockedTitle => 'ปิดการแจ้งเตือนอยู่';

  @override
  String get notificationPermissionBlockedMessage =>
      'เปิดการแจ้งเตือนในการตั้งค่าอุปกรณ์เพื่อรับการแจ้งเตือนแบบพุช';

  @override
  String get openSettings => 'เปิดการตั้งค่า';

  @override
  String get notificationsTitle => 'การแจ้งเตือน';

  @override
  String get notificationsEmpty => 'ยังไม่มีการแจ้งเตือน';

  @override
  String get notificationSendToday => 'วันนี้';

  @override
  String get notificationSendOneDayAgo => '1 วันที่แล้ว';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count วันที่แล้ว';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'สมัครใหม่ได้หลังจากลบบัญชีแล้ว 2 วัน ลองอีกครั้งภายหลัง';

  @override
  String get expressionSavedToProfile => 'บันทึกในโปรไฟล์แล้ว';

  @override
  String get expressionUnsavedToProfile => 'ยกเลิกการบันทึกแล้ว';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'ครั้งนี้ยังให้ฟีดแบ็กไม่ได้ ลองตอบอย่างน้อย 7 คำ!';

  @override
  String get roleplayResultScoreMeaning => 'ความหมาย';

  @override
  String get roleplayResultScoreRelevance => 'ความสอดคล้อง';

  @override
  String get roleplayResultScoreVocabulary => 'คำศัพท์';

  @override
  String get roleplayResultScoreGrammar => 'ไวยากรณ์';

  @override
  String get closePopup => 'ปิด';

  @override
  String get reviewChatTapHint => 'แตะข้อความเพื่อฟังเสียง';

  @override
  String get reviewChatNoAudioToPlay => 'ไม่มีเสียงให้เล่น';

  @override
  String get seriesInformationTopicDifficulty => 'ความยากของหัวข้อ';

  @override
  String get seriesInformationLearningGoals => 'เป้าหมายการเรียนรู้';

  @override
  String get energyInfoTitle => 'พลังงาน';

  @override
  String get energyOutOfEnergyTitle => 'พลังงานหมด';

  @override
  String get energyInfoRechargeUntil => 'พลังงานจะฟื้นฟูในอีก @@TIME@@';

  @override
  String get energyInfoFull => 'พลังงานเต็มแล้ว';

  @override
  String get energyInfoUnlimitedEndsIn => 'กำลังใช้โหมดไม่จำกัด';

  @override
  String get energyInsufficient => 'พลังงานไม่พอ';

  @override
  String get endRoleplay => 'จบโรลเพลย์';

  @override
  String get energyEnablePushTitle => 'เปิดการแจ้งเตือน';

  @override
  String get energyEnablePushSubtitle =>
      'เปิดการแจ้งเตือนเพื่อเติมพลังงานให้เต็ม';

  @override
  String get energyEnablePushPrice => 'ฟรี';

  @override
  String get energyEnablePushOfferBadge => 'ข้อเสนอครั้งเดียว';

  @override
  String get energyEnablePushCompleted => 'เติมพลังงานเต็มแล้ว!';

  @override
  String get energyPurchaseUnlimitedTitle => 'บัตรเล่นไม่จำกัด';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'เริ่มทันทีหลังซื้อ ใช้ได้ 10 นาที';

  @override
  String get energyPurchaseCapacityTitle => 'เพิ่มพลังงานสูงสุด';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'เพิ่มพลังงานสูงสุดที่เติมได้ 1 หน่วยอย่างถาวร';

  @override
  String get energyGoPremiumTitle => 'สมัคร Premium';

  @override
  String get energyGoPremiumExplore => 'ดูเพิ่มเติม';

  @override
  String get profileGoPremiumTitle => 'สมัคร SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'ดูเพิ่มเติม';

  @override
  String get energyPurchasePendingApproval => 'การชำระเงินกำลังรอการอนุมัติ';

  @override
  String get energyPurchaseNotCompleted => 'ดำเนินการซื้อไม่สำเร็จ';

  @override
  String get iapPurchaseProcessing => 'กำลังดำเนินการซื้อของคุณ';

  @override
  String get iapPurchaseCompleted => 'การซื้อเสร็จสมบูรณ์';

  @override
  String get welcomeGiftTitle => 'ของขวัญต้อนรับมาถึงแล้ว!';

  @override
  String get welcomeGiftBenefitLead => 'เล่นได้ไม่จำกัด 10 นาที!';

  @override
  String get welcomeGiftLine2 => 'ปลดล็อกฟีเจอร์ Premium';

  @override
  String get welcomeGiftLine3 => 'ปลดล็อกการเล่นไม่จำกัด';

  @override
  String get welcomeGiftStartNow => 'เริ่มเลย';

  @override
  String get paywallHeroTitle1 => 'ฝึกให้มากขึ้น';

  @override
  String get paywallHeroTitle2 => 'เก่งเร็วขึ้น';

  @override
  String get paywallHeroBody =>
      'ฝึกได้นานขึ้นด้วย Premium พร้อมรับฟีดแบ็กจาก AI เพื่อเพิ่มความมั่นใจในการใช้ภาษาอังกฤษ';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'ฝึกได้มากขึ้นทุกวัน';

  @override
  String get paywallBenefitMaxEnergy => 'พลังงานสูงสุด 30';

  @override
  String get paywallBenefitAiFeedback => 'ฟีดแบ็กจาก AI รายประโยค';

  @override
  String get paywallChoosePlan => 'เลือกแพ็กเกจ';

  @override
  String get paywallAnnualPlanTitle => 'แพ็กเกจรายปี';

  @override
  String get paywallAnnualPlanSubtitle =>
      'ประหยัดมากกว่า 33% เมื่อเทียบกับแพ็กเกจรายเดือน';

  @override
  String get paywallMonthlyPlanTitle => 'แพ็กเกจรายเดือน';

  @override
  String get paywallMonthlyPlanSubtitle => 'ใช้งานแบบรายเดือนได้อย่างยืดหยุ่น';

  @override
  String get paywallBestBadge => 'คุ้มที่สุด';

  @override
  String get paywallCta => 'สมัครเลย';

  @override
  String get paywallAutoRenewNotice =>
      'การสมัครสมาชิกจะต่ออายุอัตโนมัติ เว้นแต่จะยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดรอบการเรียกเก็บเงินปัจจุบัน';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/เดือน';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/ปี';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'ยินดีด้วย!';

  @override
  String get paywallCompletedBody =>
      'สิทธิประโยชน์ Premium ของคุณเปิดใช้งานแล้ว';

  @override
  String get paywallCompletedContinue => 'ไปต่อ';

  @override
  String get roleplayChooseYourRole => 'เลือกบทบาทของคุณ';

  @override
  String get roleplaySimilarRoleplays => 'บทบาทสมมติที่คล้ายกัน';

  @override
  String get roleplayBeingPrepared => 'บทบาทสมมตินี้กำลังเตรียมอยู่';

  @override
  String get roleplayUnlockPreviousRole =>
      'จบตอนจบทั้งหมดของบทบาทก่อนหน้าเพื่อปลดล็อกบทบาทนี้';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return 'เสร็จแล้ว $percent%';
  }

  @override
  String get roleplayTurnGradeA => 'ว้าว!';

  @override
  String get roleplayTurnGradeB => 'โอเค!';

  @override
  String get roleplayTurnGradeC => 'อืม…';

  @override
  String get roleplayTurnGradeD => 'โอ้…';

  @override
  String get tutorialPage1Title => 'ดู**ภารกิจ**แล้ว\nเริ่มบทสนทนาเลย';

  @override
  String get tutorialPage1Tip =>
      '*ทิป: พูดได้เป็นธรรมชาติมากเท่าไหร่\nรางวัลยิ่งมากขึ้น!';

  @override
  String get tutorialPage2Title => 'ใช้**ตัวแปล**\nเมื่อคุณไม่เข้าใจ';

  @override
  String get tutorialPage3Title => 'ใช้**คำใบ้**\nเมื่อคุณติดขัด';

  @override
  String get tutorialPage3Subtitle => 'เปิดหรือปิดคำใบ้อัตโนมัติ\nได้ทุกเมื่อ';

  @override
  String get tutorialPage4Title => 'ถ้าออกเสียงยาก\nให้ฟังก่อนแล้วค่อยพูดตาม';

  @override
  String get tutorialPage4Tip =>
      '*ทิป: ลองตอบโดยไม่ดูคำแปล\nเพื่อได้คะแนนสูงขึ้น';

  @override
  String get tutorialPage5Title => 'พูดออกเสียงไม่ได้?';

  @override
  String get tutorialPage5Subtitle => 'สลับเป็น**โหมดข้อความ**';

  @override
  String get tutorialPage6Title => 'ไม่มีใครตัดสินคุณ\nสู้ ๆ นะ!';
}
