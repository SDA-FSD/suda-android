// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get agreementHeading =>
      'Pakisuri at sang-ayunan ang mga tuntunin sa ibaba para magpatuloy.';

  @override
  String get agreementTermsLabel =>
      'Sumasang-ayon ako sa Mga Tuntunin ng Paggamit.';

  @override
  String get agreementPrivacyLabel =>
      'Sumasang-ayon ako sa Patakaran sa Privacy.';

  @override
  String get agreementTermsTitle => 'Mga Tuntunin ng Paggamit';

  @override
  String get agreementPrivacyTitle => 'Patakaran sa Privacy';

  @override
  String get agreementDetailsLink => 'Tingnan ang detalye';

  @override
  String get agreementButtonConfirm => 'Kumpirmahin at magpatuloy';

  @override
  String get settingsTitle => 'Mga Setting';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsRestorePurchases => 'I-restore ang mga binili';

  @override
  String get restorePurchasesNothing => 'Walang biniling maire-restore.';

  @override
  String get restorePurchasesCompleted => 'Na-restore na ang mga binili.';

  @override
  String get settingsNotification => 'Mga Notification';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Antas ng English';

  @override
  String get pushNotifications => 'Mga Push Notification';

  @override
  String get pushNotificationsDesc =>
      'Makatanggap ng mga paalala at mahahalagang update.';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsAnnouncements => 'Mga Anunsyo';

  @override
  String get announcementsEmpty => 'Wala pang anunsyo';

  @override
  String get noticesEmpty => 'Wala pang post';

  @override
  String get deletedPost => 'Na-delete na ang post na ito.';

  @override
  String get postNoLongerAvailable => 'Hindi na available ang post na ito.';

  @override
  String get backToHome => 'Bumalik sa Home';

  @override
  String get settingsSignOut => 'Mag-log out';

  @override
  String get settingsFsdLaboratory => 'FSD Laboratory';

  @override
  String get settingsPrivacy => 'Patakaran sa Privacy';

  @override
  String get settingsTerms => 'Mga Tuntunin ng Serbisyo';

  @override
  String get settingsOpenSource => 'Mga Lisensya ng Open Source';

  @override
  String loginWelcome(String name) {
    return 'Maligayang pagdating, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Sa pagpapatuloy, sumasang-ayon ka sa aming $terms at $privacy.';
  }

  @override
  String get loginTermsTitle => 'Mga Tuntunin ng Paggamit';

  @override
  String get loginPrivacyTitle => 'Patakaran sa Privacy';

  @override
  String get loginCatchphrase => 'Magsalita ka lang. Doon ka matututo.';

  @override
  String get loginWelcomeTitle => 'Welcome sa SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Pumasok sa isang kuwento at magsimulang magsalita ng English!';

  @override
  String get loginErrorIdToken =>
      'Hindi nakuha ang Google ID Token. Pakisubukang muli.';

  @override
  String loginErrorFailed(String error) {
    return 'Hindi nagtagumpay ang login: $error';
  }

  @override
  String get accountName => 'Pangalan';

  @override
  String get accountInfo => 'Account';

  @override
  String get accountDelete => 'I-delete ang Account';

  @override
  String get accountDeleteTitle => 'I-delete ang Account?';

  @override
  String get accountDeleteConfirmText =>
      'Permanenteng mawawala ang lahat ng progreso at data mo. Sigurado ka ba?';

  @override
  String get accountDeleteProfileImageTitle => 'I-delete ang profile image?';

  @override
  String get accountDeleteProfileImageContent =>
      'Kapag na-delete na, hindi na mare-recover ang profile image mo.';

  @override
  String get accountGoBack => 'Bumalik';

  @override
  String get accountDeleteAction => 'I-delete';

  @override
  String get accountSubscription => 'Subscription';

  @override
  String get accountFreePlanTitle => 'Libreng Plan';

  @override
  String get accountFreePlanSubtitle =>
      'Mag-Premium para ma-unlock ang iba pang feature';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Aktibo ang mga benepisyo mo sa Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Magre-renew sa $date';
  }

  @override
  String get accountChangePlan => 'Baguhin ang Plan';

  @override
  String get changePlanTitle => 'Baguhin ang Plan';

  @override
  String get changePlanCurrentPlan => 'Kasalukuyang Plan';

  @override
  String get changePlanAvailablePlans => 'Mga Available na Plan';

  @override
  String changePlanRenewsOn(String date) {
    return 'Magre-renew sa $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Hindi ma-load ang impormasyon. Pakisubukang muli.';

  @override
  String get changePlanRetry => 'Subukan muli';

  @override
  String get changePlanConfirmTitle => 'Baguhin ang Plan?';

  @override
  String get changePlanConfirmBody =>
      'Magkakabisa ang pagbabago ng plan sa susunod mong billing date.';

  @override
  String get changePlanConfirmOk => 'Kumpirmahin';

  @override
  String get changePlanConfirmCancel => 'Panatilihin ang Kasalukuyang Plan';

  @override
  String get changePlanOldPurchaseMissing =>
      'Walang nakitang active na subscription na puwedeng baguhin. Subukan muli kapag active na ang subscription mo.';

  @override
  String get changePlanChangeRequested =>
      'Naisumite ang request na baguhin ang plan. Maaaring magkabisa ito sa susunod mong billing date.';

  @override
  String get cefrLevelTitle => 'Piliin ang antas mo sa English';

  @override
  String get cefrLevelAbsoluteBeginner => 'Baguhang-baguhan';

  @override
  String get cefrLevelBeginner => 'Baguhan';

  @override
  String get cefrLevelBasic => 'Basic';

  @override
  String get cefrLevelIntermediate => 'Intermediate';

  @override
  String get firstCefrLevelTitle => 'Ano ang antas mo sa English?';

  @override
  String get firstCefrLevelDescriptionPreA1 =>
      'Marunong akong magbasa ng English';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Alam ko ang mga basic na pagbati at simpleng parirala';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Nakakagamit at nakakaintindi ako ng maiikli at simpleng pangungusap';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Naibabahagi ko ang opinyon ko at nakakasali sa pang-araw-araw na usapan';

  @override
  String get firstCefrLevelSettingsHint =>
      'Maaari mo itong baguhin anumang oras';

  @override
  String get firstCefrLevelConfirm => 'Kumpirmahin';

  @override
  String get feedbackPlaceholder =>
      'Ibahagi ang opinyon, mungkahi, o anumang problemang naranasan mo...';

  @override
  String get feedbackSend => 'Ipadala';

  @override
  String get feedbackSuccess => 'Salamat sa feedback mo.';

  @override
  String get microphonePermissionDenied =>
      'Hindi makapagsimula nang walang pahintulot sa microphone.';

  @override
  String get holdMicrophoneToSpeak =>
      'Pindutin nang matagal ang mic para magsalita';

  @override
  String get roleplayTypeMessagePlaceholder => 'I-type ang mensahe mo...';

  @override
  String get yourTurnFirst => 'Ikaw muna!';

  @override
  String get sayLineBelowToStart =>
      'Sabihin ang linya sa ibaba para magsimula.';

  @override
  String get roleplayExitWait => 'Teka!';

  @override
  String get roleplayExitMessage =>
      'Kapag umalis ka ngayon, hindi mo makukuha ang reward. Sigurado ka bang aalis ka?';

  @override
  String get roleplayExitKeepPlaying => 'Magpatuloy';

  @override
  String get roleplayExitExit => 'Umalis';

  @override
  String get roleplayAutoHint => 'Auto Hint';

  @override
  String get roleplayHintLabel => 'Hint';

  @override
  String get roleplayHintShowAnswer =>
      'I-tap para makita ang mungkahing sagot sa English';

  @override
  String get roleplayVoiceSpeed => 'Bilis ng pagsasalita';

  @override
  String get roleplayEndedFailed => 'Hindi nakumpleto ang mission...';

  @override
  String get roleplayEndedComplete => 'Nakumpleto ang Roleplay';

  @override
  String get roleplayEndedEnding => 'Papunta na sa ending...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Kulang ang progreso';

  @override
  String get roleplayFinishCompleted => 'Nakumpleto ang Roleplay';

  @override
  String get roleplayFinishMovingToEnding => 'Papunta na sa ending...';

  @override
  String get roleplayAnalyzing => 'Sinusuri ang roleplay mo...';

  @override
  String get roleplayOpeningAiCharacter => 'AI Character';

  @override
  String get roleplayOpeningScenario => 'Scenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'Maaaring magkamali ang AI.\nHuwag magbahagi ng personal o sensitibong impormasyon.';

  @override
  String get endingFailTitle => 'Hindi mo nakumpleto ang lahat ng mission!';

  @override
  String get endingFailSubtitle =>
      'Subukan muli at tuklasin ang buong kuwento.';

  @override
  String get roleplayTryAgainMessage =>
      'Sayang, hindi sapat ang score mo para makuha ang reward.';

  @override
  String get endingReport => 'I-report ang problema';

  @override
  String get endingHowWas => 'Kumusta ang Roleplay?';

  @override
  String get endingNext => 'Susunod';

  @override
  String get reportTitle => 'I-report ang Problema';

  @override
  String get profileHistory => 'History';

  @override
  String get profileSaved => 'Mga Naka-save';

  @override
  String get profileHistoryEmpty => 'Wala pang history';

  @override
  String get profileSavedEmpty => 'Wala pang naka-save na expression.';

  @override
  String get profileSavedRemoveTitle => 'Alisin sa mga naka-save?';

  @override
  String get profileSavedRemoveContent =>
      'Mahahanap mo ulit ito sa History sa ibang pagkakataon.';

  @override
  String get profileSavedRemoveOk => 'Alisin';

  @override
  String get profileSavedRemoveCancel => 'Magpraktis pa';

  @override
  String get seriesOverviewTabEpisodes => 'Episode';

  @override
  String get seriesOverviewTabSimilarTopic => 'Katulad na Paksa';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episode #$number';
  }

  @override
  String get seriesOverviewPlay => 'I-play';

  @override
  String get seriesOverviewLocked => 'Naka-lock';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Tapusin muna ang nakaraang episode para ma-unlock ito.';

  @override
  String get notificationPermissionBlockedTitle =>
      'Naka-off ang mga notification';

  @override
  String get notificationPermissionBlockedMessage =>
      'I-on ang mga notification sa settings ng device para makatanggap ng mga push notification.';

  @override
  String get openSettings => 'Buksan ang Settings';

  @override
  String get notificationsTitle => 'Mga Notification';

  @override
  String get notificationsEmpty => 'Wala pang notification';

  @override
  String get notificationSendToday => 'Ngayong araw';

  @override
  String get notificationSendOneDayAgo => '1 araw ang nakalipas';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count araw ang nakalipas';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Maaari kang mag-sign up muli 2 araw pagkatapos i-delete ang account mo. Pakisubukang muli mamaya.';

  @override
  String get expressionSavedToProfile => 'Na-save sa Profile mo';

  @override
  String get expressionUnsavedToProfile => 'Hindi na naka-save';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Hindi kami makapagbigay ng feedback sa pagkakataong ito. Subukang pahabain ang sagot mo sa 7 salita o higit pa!';

  @override
  String get roleplayResultScoreMeaning => 'Kahulugan';

  @override
  String get roleplayResultScoreRelevance => 'Kaugnayan';

  @override
  String get roleplayResultScoreVocabulary => 'Bokabularyo';

  @override
  String get roleplayResultScoreGrammar => 'Gramatika';

  @override
  String get closePopup => 'Isara';

  @override
  String get reviewChatTapHint =>
      'I-tap ang chat bubble para i-play ang audio.';

  @override
  String get reviewChatNoAudioToPlay => 'Walang audio na puwedeng i-play.';

  @override
  String get seriesInformationTopicDifficulty => 'Antas ng Hirap ng Paksa';

  @override
  String get seriesInformationLearningGoals => 'Mga Layunin sa Pag-aaral';

  @override
  String get energyInfoTitle => 'Energy';

  @override
  String get energyOutOfEnergyTitle => 'Ubos na ang Energy';

  @override
  String get energyInfoRechargeUntil =>
      'Susunod na recharge sa loob ng @@TIME@@';

  @override
  String get energyInfoFull => 'Puno ang Energy mo.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Aktibo ang Unlimited Mode';

  @override
  String get energyInsufficient => 'Kulang ang Energy mo.';

  @override
  String get endRoleplay => 'Tapusin ang Roleplay';

  @override
  String get energyEnablePushTitle => 'I-on ang mga Notification';

  @override
  String get energyEnablePushSubtitle =>
      'I-on ang mga notification at punuin ang Energy mo.';

  @override
  String get energyEnablePushPrice => 'Libre';

  @override
  String get energyEnablePushOfferBadge => 'ALOK NA ISANG BESES LANG';

  @override
  String get energyEnablePushCompleted => 'Napuno na ang Energy!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Pass para sa Unlimited Mode';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Magsisimula agad pagkatapos bilhin. Valid sa loob ng 10 minuto.';

  @override
  String get energyPurchaseCapacityTitle => 'Upgrade sa Max Energy';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Permanenteng tataas nang 1 ang maximum na Energy na mare-recharge mo.';

  @override
  String get energyGoPremiumTitle => 'Mag-Premium';

  @override
  String get energyGoPremiumExplore => 'Tingnan';

  @override
  String get profileGoPremiumTitle => 'Kunin ang SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Tingnan';

  @override
  String get energyPurchasePendingApproval =>
      'Naghihintay pa ng approval ang payment mo';

  @override
  String get energyPurchaseNotCompleted => 'Hindi nakumpleto ang pagbili.';

  @override
  String get welcomeGiftTitle => 'Dumating na ang Welcome Gift Mo!';

  @override
  String get welcomeGiftBenefitLead =>
      'Mag-enjoy sa unlimited play nang 10 minuto!';

  @override
  String get welcomeGiftLine2 => 'Na-unlock ang mga Premium feature';

  @override
  String get welcomeGiftLine3 => 'Na-unlock ang unlimited play';

  @override
  String get welcomeGiftStartNow => 'Magsimula Ngayon';

  @override
  String get paywallHeroTitle1 => 'Magpraktis Pa';

  @override
  String get paywallHeroTitle2 => 'Mas Mabilis na Gumaling';

  @override
  String get paywallHeroBody =>
      'Magpraktis nang mas matagal gamit ang Premium at makakuha ng AI feedback para mas maging confident sa English.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Mas Maraming Practice Kada Araw';

  @override
  String get paywallBenefitMaxEnergy => 'Hanggang 30 ang Max Energy';

  @override
  String get paywallBenefitAiFeedback => 'AI Feedback sa Pangungusap';

  @override
  String get paywallChoosePlan => 'Piliin ang Plan Mo';

  @override
  String get paywallAnnualPlanTitle => 'Taunang Plan';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Makatipid nang mahigit 33% kumpara sa buwanang plan.';

  @override
  String get paywallMonthlyPlanTitle => 'Buwanang Plan';

  @override
  String get paywallMonthlyPlanSubtitle => 'Flexible na access buwan-buwan.';

  @override
  String get paywallBestBadge => 'PINAKASULIT';

  @override
  String get paywallCta => 'Mag-subscribe Ngayon';

  @override
  String get paywallAutoRenewNotice =>
      'Awtomatikong mare-renew ang subscription maliban kung kanselahin ito nang hindi bababa sa 24 na oras bago matapos ang kasalukuyang billing period.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/buwan';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/taon';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Binabati ka!';

  @override
  String get paywallCompletedBody =>
      'Aktibo na ang mga benepisyo mo sa Premium.';

  @override
  String get paywallCompletedContinue => 'Magpatuloy';

  @override
  String get roleplayChooseYourRole => 'Piliin ang iyong papel';

  @override
  String get roleplaySimilarRoleplays => 'Mga katulad na roleplay';

  @override
  String get roleplayBeingPrepared => 'Inihanda pa ang roleplay na ito.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Tapusin ang lahat ng ending ng naunang papel para i-unlock ang papel na ito.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% tapos na';
  }

  @override
  String get roleplayTurnGradeA => 'wow!';

  @override
  String get roleplayTurnGradeB => 'ok!';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'oh…';
}
