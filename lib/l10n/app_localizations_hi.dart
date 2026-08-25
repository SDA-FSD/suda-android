// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get agreementHeading =>
      'जारी रखने के लिए नीचे दी गई शर्तें पढ़ें और सहमति दें।';

  @override
  String get agreementTermsLabel => 'मैं उपयोग की शर्तों से सहमत हूँ।';

  @override
  String get agreementPrivacyLabel => 'मैं गोपनीयता नीति से सहमत हूँ।';

  @override
  String get agreementTermsTitle => 'उपयोग की शर्तें';

  @override
  String get agreementPrivacyTitle => 'गोपनीयता नीति';

  @override
  String get agreementDetailsLink => 'जानकारी देखें';

  @override
  String get agreementButtonConfirm => 'सहमत होकर आगे बढ़ें';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsAccount => 'अकाउंट';

  @override
  String get settingsRestorePurchases => 'खरीदारी रीस्टोर करें';

  @override
  String get restorePurchasesNothing =>
      'रीस्टोर करने के लिए कोई खरीदारी नहीं है।';

  @override
  String get restorePurchasesCompleted => 'खरीदारी रीस्टोर हो गई।';

  @override
  String get settingsNotification => 'नोटिफ़िकेशन';

  @override
  String get settingsTutorial => 'ट्यूटोरियल';

  @override
  String get settingsCefrLevel => 'अंग्रेज़ी का स्तर';

  @override
  String get pushNotifications => 'पुश नोटिफ़िकेशन';

  @override
  String get pushNotificationsDesc => 'रिमाइंडर और ज़रूरी अपडेट पाएँ।';

  @override
  String get settingsFeedback => 'फ़ीडबैक';

  @override
  String get settingsAnnouncements => 'घोषणाएँ';

  @override
  String get announcementsEmpty => 'अभी कोई घोषणा नहीं है';

  @override
  String get noticesEmpty => 'अभी कोई पोस्ट नहीं है';

  @override
  String get deletedPost => 'यह पोस्ट डिलीट कर दी गई है।';

  @override
  String get postNoLongerAvailable => 'यह पोस्ट अब उपलब्ध नहीं है।';

  @override
  String get backToHome => 'होम पर वापस जाएँ';

  @override
  String get settingsSignOut => 'लॉग आउट';

  @override
  String get settingsFsdLaboratory => 'FSD लैब';

  @override
  String get settingsPrivacy => 'गोपनीयता नीति';

  @override
  String get settingsTerms => 'सेवा की शर्तें';

  @override
  String get settingsOpenSource => 'ओपन सोर्स लाइसेंस';

  @override
  String loginWelcome(String name) {
    return '$name, आपका स्वागत है!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'जारी रखकर, आप हमारी $terms और $privacy से सहमत होते हैं।';
  }

  @override
  String get loginTermsTitle => 'उपयोग की शर्तें';

  @override
  String get loginPrivacyTitle => 'गोपनीयता नीति';

  @override
  String get loginCatchphrase => 'बोलना शुरू करें—सीखने का यही तरीका है।';

  @override
  String get loginWelcomeTitle => 'SUDA में आपका स्वागत है!';

  @override
  String get loginWelcomeSubtitle =>
      'किसी कहानी का हिस्सा बनें और अंग्रेज़ी बोलना शुरू करें!';

  @override
  String get loginErrorIdToken =>
      'Google ID टोकन नहीं मिल सका। फिर कोशिश करें।';

  @override
  String loginErrorFailed(String error) {
    return 'लॉगिन नहीं हुआ: $error';
  }

  @override
  String get accountName => 'नाम';

  @override
  String get accountInfo => 'अकाउंट';

  @override
  String get accountDelete => 'अकाउंट डिलीट करें';

  @override
  String get accountDeleteTitle => 'अकाउंट डिलीट करें?';

  @override
  String get accountDeleteConfirmText =>
      'आपकी सारी प्रोग्रेस और डेटा हमेशा के लिए डिलीट हो जाएँगे। क्या आप वाकई ऐसा करना चाहते हैं?';

  @override
  String get accountDeleteProfileImageTitle => 'प्रोफ़ाइल फ़ोटो डिलीट करें?';

  @override
  String get accountDeleteProfileImageContent =>
      'डिलीट करने के बाद आपकी प्रोफ़ाइल फ़ोटो वापस नहीं मिल सकती।';

  @override
  String get accountGoBack => 'वापस जाएँ';

  @override
  String get accountDeleteAction => 'डिलीट करें';

  @override
  String get accountSubscription => 'सब्सक्रिप्शन';

  @override
  String get accountFreePlanTitle => 'फ़्री प्लान';

  @override
  String get accountFreePlanSubtitle =>
      'ज़्यादा फ़ीचर अनलॉक करने के लिए प्रीमियम लें';

  @override
  String get accountPremiumTitle => 'प्रीमियम';

  @override
  String get accountPremiumSubtitle => 'आपको प्रीमियम के फ़ायदे मिल रहे हैं';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'रिन्यू होने की तारीख: $date';
  }

  @override
  String get accountChangePlan => 'प्लान बदलें';

  @override
  String get changePlanTitle => 'प्लान बदलें';

  @override
  String get changePlanCurrentPlan => 'मौजूदा प्लान';

  @override
  String get changePlanAvailablePlans => 'उपलब्ध प्लान';

  @override
  String changePlanRenewsOn(String date) {
    return 'रिन्यू होने की तारीख: $date';
  }

  @override
  String get changePlanLoadFailed => 'जानकारी लोड नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get changePlanRetry => 'फिर कोशिश करें';

  @override
  String get changePlanConfirmTitle => 'प्लान बदलें?';

  @override
  String get changePlanConfirmBody =>
      'प्लान में बदलाव आपकी अगली बिलिंग तारीख से लागू होगा।';

  @override
  String get changePlanConfirmOk => 'कन्फ़र्म करें';

  @override
  String get changePlanConfirmCancel => 'मौजूदा प्लान रखें';

  @override
  String get changePlanOldPurchaseMissing =>
      'बदलने के लिए कोई ऐक्टिव सब्सक्रिप्शन नहीं मिला। सब्सक्रिप्शन ऐक्टिव होने के बाद फिर कोशिश करें।';

  @override
  String get changePlanChangeRequested =>
      'प्लान बदलने का अनुरोध भेज दिया गया है। यह अगली बिलिंग तारीख से लागू हो सकता है।';

  @override
  String get cefrLevelTitle => 'अपना अंग्रेज़ी स्तर चुनें';

  @override
  String get cefrLevelAbsoluteBeginner => 'एकदम शुरुआती';

  @override
  String get cefrLevelBeginner => 'शुरुआती';

  @override
  String get cefrLevelBasic => 'बेसिक';

  @override
  String get cefrLevelIntermediate => 'इंटरमीडिएट';

  @override
  String get firstCefrLevelTitle => 'आपका अंग्रेज़ी स्तर क्या है?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'मुझे अंग्रेज़ी पढ़नी आती है';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'मुझे सामान्य अभिवादन और आसान वाक्यांश आते हैं';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'मैं छोटे और आसान वाक्य समझ सकता हूँ और उनका इस्तेमाल कर सकता हूँ';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'मैं अपनी राय बता सकता हूँ और रोज़मर्रा की बातचीत कर सकता हूँ';

  @override
  String get firstCefrLevelSettingsHint => 'इसे कभी भी बदल सकते हैं';

  @override
  String get firstCefrLevelConfirm => 'कन्फ़र्म करें';

  @override
  String get feedbackPlaceholder =>
      'अपने विचार, सुझाव या सामने आई कोई समस्या बताएँ...';

  @override
  String get feedbackSend => 'भेजें';

  @override
  String get feedbackSuccess => 'फ़ीडबैक देने के लिए धन्यवाद।';

  @override
  String get microphonePermissionDenied =>
      'माइक्रोफ़ोन की अनुमति के बिना शुरू नहीं कर सकते।';

  @override
  String get holdMicrophoneToSpeak => 'बोलने के लिए माइक्रोफ़ोन दबाकर रखें';

  @override
  String get roleplayTypeMessagePlaceholder => 'अपना मैसेज लिखें...';

  @override
  String get yourTurnFirst => 'पहले आपकी बारी!';

  @override
  String get sayLineBelowToStart => 'शुरू करने के लिए नीचे दी गई लाइन बोलें।';

  @override
  String get roleplayExitWait => 'रुकिए!';

  @override
  String get roleplayExitMessage =>
      'अभी बाहर निकले तो आपका इनाम छूट जाएगा। क्या आप वाकई बाहर निकलना चाहते हैं?';

  @override
  String get roleplayExitKeepPlaying => 'रोलप्ले जारी रखें';

  @override
  String get roleplayExitExit => 'बाहर निकलें';

  @override
  String get roleplayAutoHint => 'ऑटो हिंट';

  @override
  String get roleplayHintLabel => 'हिंट';

  @override
  String get roleplayHintShowAnswer =>
      'सुझाया गया अंग्रेज़ी जवाब देखने के लिए टैप करें';

  @override
  String get roleplayVoiceSpeed => 'आवाज़ की स्पीड';

  @override
  String get roleplayEndedFailed => 'मिशन फ़ेल हो गया...';

  @override
  String get roleplayEndedComplete => 'रोलप्ले पूरा हुआ';

  @override
  String get roleplayEndedEnding => 'एंडिंग पर जा रहे हैं...';

  @override
  String get roleplayFinishNotEnoughProgress => 'पर्याप्त प्रोग्रेस नहीं हुई';

  @override
  String get roleplayFinishCompleted => 'रोलप्ले पूरा हुआ';

  @override
  String get roleplayFinishMovingToEnding => 'एंडिंग पर जा रहे हैं...';

  @override
  String get roleplayAnalyzing => 'आपके रोलप्ले का विश्लेषण हो रहा है...';

  @override
  String get roleplayOpeningAiCharacter => 'एआई कैरेक्टर';

  @override
  String get roleplayOpeningScenario => 'सिनेरियो';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'एआई से गलतियाँ हो सकती हैं।\nकृपया निजी या संवेदनशील जानकारी शेयर न करें।';

  @override
  String get endingFailTitle => 'आप सभी मिशन पूरे नहीं कर पाए!';

  @override
  String get endingFailSubtitle => 'फिर कोशिश करें और पूरी कहानी जानें।';

  @override
  String get roleplayTryAgainMessage =>
      'अफ़सोस, आपका स्कोर इनाम पाने के लिए काफ़ी नहीं था।';

  @override
  String get endingReport => 'समस्या रिपोर्ट करें';

  @override
  String get endingHowWas => 'रोलप्ले कैसा रहा?';

  @override
  String get endingNext => 'अगला';

  @override
  String get reportTitle => 'समस्या रिपोर्ट करें';

  @override
  String get profileHistory => 'हिस्ट्री';

  @override
  String get profileSaved => 'सेव किए गए';

  @override
  String get profileHistoryEmpty => 'अभी कोई हिस्ट्री नहीं है';

  @override
  String get profileSavedEmpty => 'अभी कोई एक्सप्रेशन सेव नहीं है।';

  @override
  String get profileSavedRemoveTitle => 'सेव से हटाएँ?';

  @override
  String get profileSavedRemoveContent =>
      'इसे बाद में हिस्ट्री में फिर से ढूँढ सकते हैं।';

  @override
  String get profileSavedRemoveOk => 'हटाएँ';

  @override
  String get profileSavedRemoveCancel => 'और प्रैक्टिस करें';

  @override
  String get seriesOverviewTabEpisodes => 'एपिसोड';

  @override
  String get seriesOverviewTabSimilarTopic => 'मिलता-जुलता टॉपिक';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'एपिसोड #$number';
  }

  @override
  String get seriesOverviewPlay => 'खेलें';

  @override
  String get seriesOverviewLocked => 'लॉक है';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'अनलॉक करने के लिए पिछला एपिसोड पूरा करें।';

  @override
  String get notificationPermissionBlockedTitle => 'नोटिफ़िकेशन बंद हैं';

  @override
  String get notificationPermissionBlockedMessage =>
      'पुश नोटिफ़िकेशन पाने के लिए डिवाइस सेटिंग्स में नोटिफ़िकेशन चालू करें।';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get notificationsTitle => 'नोटिफ़िकेशन';

  @override
  String get notificationsEmpty => 'अभी कोई नोटिफ़िकेशन नहीं है';

  @override
  String get notificationSendToday => 'आज';

  @override
  String get notificationSendOneDayAgo => '1 दिन पहले';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'अकाउंट डिलीट करने के 2 दिन बाद ही दोबारा साइन अप कर सकते हैं। कृपया बाद में फिर कोशिश करें।';

  @override
  String get expressionSavedToProfile => 'आपकी प्रोफ़ाइल में सेव हो गया';

  @override
  String get expressionUnsavedToProfile => 'सेव से हटा दिया गया';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'इस बार फ़ीडबैक नहीं दे पाए। 7 या उससे ज़्यादा शब्दों में जवाब देने की कोशिश करें!';

  @override
  String get roleplayResultScoreMeaning => 'अर्थ';

  @override
  String get roleplayResultScoreRelevance => 'प्रासंगिकता';

  @override
  String get roleplayResultScoreVocabulary => 'शब्दावली';

  @override
  String get roleplayResultScoreGrammar => 'व्याकरण';

  @override
  String get closePopup => 'बंद करें';

  @override
  String get reviewChatTapHint => 'ऑडियो चलाने के लिए चैट बबल पर टैप करें।';

  @override
  String get reviewChatNoAudioToPlay => 'चलाने के लिए कोई ऑडियो नहीं है।';

  @override
  String get seriesInformationTopicDifficulty => 'टॉपिक की कठिनाई';

  @override
  String get seriesInformationLearningGoals => 'सीखने के लक्ष्य';

  @override
  String get energyInfoTitle => 'एनर्जी';

  @override
  String get energyOutOfEnergyTitle => 'एनर्जी खत्म हो गई';

  @override
  String get energyInfoRechargeUntil => 'अगला रीचार्ज @@TIME@@ में';

  @override
  String get energyInfoFull => 'आपकी एनर्जी पूरी भरी है।';

  @override
  String get energyInfoUnlimitedEndsIn => 'अनलिमिटेड मोड चालू है';

  @override
  String get energyInsufficient => 'आपके पास पर्याप्त एनर्जी नहीं है।';

  @override
  String get endRoleplay => 'रोलप्ले खत्म करें';

  @override
  String get energyEnablePushTitle => 'नोटिफ़िकेशन चालू करें';

  @override
  String get energyEnablePushSubtitle =>
      'नोटिफ़िकेशन चालू करें और अपनी एनर्जी पूरी भरें।';

  @override
  String get energyEnablePushPrice => 'फ़्री';

  @override
  String get energyEnablePushOfferBadge => 'सिर्फ़ एक बार का ऑफ़र';

  @override
  String get energyEnablePushCompleted => 'एनर्जी पूरी भर गई!';

  @override
  String get energyPurchaseUnlimitedTitle => 'अनलिमिटेड पास';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'खरीदते ही शुरू होगा। 10 मिनट तक मान्य।';

  @override
  String get energyPurchaseCapacityTitle => 'अधिकतम एनर्जी अपग्रेड';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'रीचार्ज होने वाली आपकी अधिकतम एनर्जी हमेशा के लिए 1 बढ़ जाएगी।';

  @override
  String get energyGoPremiumTitle => 'प्रीमियम लें';

  @override
  String get energyGoPremiumExplore => 'देखें';

  @override
  String get profileGoPremiumTitle => 'SUDA प्रीमियम लें';

  @override
  String get profileGoPremiumExplore => 'देखें';

  @override
  String get energyPurchasePendingApproval =>
      'आपका पेमेंट मंज़ूरी के इंतज़ार में है';

  @override
  String get energyPurchaseNotCompleted => 'खरीद पूरी नहीं हुई।';

  @override
  String get welcomeGiftTitle => 'आपका वेलकम गिफ़्ट आ गया!';

  @override
  String get welcomeGiftBenefitLead => '10 मिनट तक अनलिमिटेड खेलें!';

  @override
  String get welcomeGiftLine2 => 'प्रीमियम फ़ीचर अनलॉक';

  @override
  String get welcomeGiftLine3 => 'अनलिमिटेड प्ले अनलॉक';

  @override
  String get welcomeGiftStartNow => 'अभी शुरू करें';

  @override
  String get paywallHeroTitle1 => 'ज़्यादा प्रैक्टिस करें';

  @override
  String get paywallHeroTitle2 => 'तेज़ी से सुधार करें';

  @override
  String get paywallHeroBody =>
      'प्रीमियम के साथ ज़्यादा देर प्रैक्टिस करें और एआई फ़ीडबैक से अंग्रेज़ी बोलने का आत्मविश्वास बढ़ाएँ।';

  @override
  String get paywallPremiumLabel => 'प्रीमियम';

  @override
  String get paywallBenefitDailyPractice => 'हर दिन ज़्यादा प्रैक्टिस';

  @override
  String get paywallBenefitMaxEnergy => 'अधिकतम 30 एनर्जी';

  @override
  String get paywallBenefitAiFeedback => 'वाक्यों पर एआई फ़ीडबैक';

  @override
  String get paywallChoosePlan => 'अपना प्लान चुनें';

  @override
  String get paywallAnnualPlanTitle => 'सालाना प्लान';

  @override
  String get paywallAnnualPlanSubtitle =>
      'मासिक प्लान की तुलना में 33% से ज़्यादा बचाएँ।';

  @override
  String get paywallMonthlyPlanTitle => 'मासिक प्लान';

  @override
  String get paywallMonthlyPlanSubtitle =>
      'महीने के हिसाब से सुविधाजनक ऐक्सेस।';

  @override
  String get paywallBestBadge => 'बेस्ट';

  @override
  String get paywallCta => 'अभी शुरू करें';

  @override
  String get paywallAutoRenewNotice =>
      'सब्सक्रिप्शन तब तक अपने-आप रिन्यू होता रहेगा, जब तक इसे मौजूदा बिलिंग अवधि खत्म होने से कम-से-कम 24 घंटे पहले कैंसल न किया जाए।';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/माह';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/वर्ष';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'बधाई हो!';

  @override
  String get paywallCompletedBody => 'आपके प्रीमियम फ़ायदे अब ऐक्टिव हैं।';

  @override
  String get paywallCompletedContinue => 'जारी रखें';
}
