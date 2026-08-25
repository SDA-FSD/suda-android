// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get agreementHeading =>
      'Devam etmek için lütfen aşağıdaki koşulları inceleyip kabul et.';

  @override
  String get agreementTermsLabel => 'Kullanım Koşulları\'nı kabul ediyorum.';

  @override
  String get agreementPrivacyLabel => 'Gizlilik Politikası\'nı kabul ediyorum.';

  @override
  String get agreementTermsTitle => 'Kullanım Koşulları';

  @override
  String get agreementPrivacyTitle => 'Gizlilik Politikası';

  @override
  String get agreementDetailsLink => 'Ayrıntıları gör';

  @override
  String get agreementButtonConfirm => 'Onayla ve devam et';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsAccount => 'Hesap';

  @override
  String get settingsRestorePurchases => 'Satın Alımları Geri Yükle';

  @override
  String get restorePurchasesNothing => 'Geri yüklenecek satın alım yok.';

  @override
  String get restorePurchasesCompleted => 'Satın alımlar geri yüklendi.';

  @override
  String get settingsNotification => 'Bildirimler';

  @override
  String get settingsTutorial => 'Eğitim';

  @override
  String get settingsCefrLevel => 'İngilizce Seviyesi';

  @override
  String get pushNotifications => 'Anlık Bildirimler';

  @override
  String get pushNotificationsDesc =>
      'Hatırlatmaları ve önemli güncellemeleri al.';

  @override
  String get settingsFeedback => 'Geri Bildirim';

  @override
  String get settingsAnnouncements => 'Duyurular';

  @override
  String get announcementsEmpty => 'Henüz duyuru yok';

  @override
  String get noticesEmpty => 'Henüz gönderi yok';

  @override
  String get deletedPost => 'Bu gönderi silindi.';

  @override
  String get postNoLongerAvailable => 'Bu gönderi artık kullanılamıyor.';

  @override
  String get backToHome => 'Ana Sayfaya Dön';

  @override
  String get settingsSignOut => 'Çıkış Yap';

  @override
  String get settingsFsdLaboratory => 'FSD Laboratuvarı';

  @override
  String get settingsPrivacy => 'Gizlilik Politikası';

  @override
  String get settingsTerms => 'Hizmet Koşulları';

  @override
  String get settingsOpenSource => 'Açık Kaynak Lisansları';

  @override
  String loginWelcome(String name) {
    return 'Hoş geldin, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Devam ederek $terms ve $privacy hükümlerini kabul etmiş olursun.';
  }

  @override
  String get loginTermsTitle => 'Kullanım Koşulları';

  @override
  String get loginPrivacyTitle => 'Gizlilik Politikası';

  @override
  String get loginCatchphrase => 'Konuşmaya başla. Böyle öğrenirsin.';

  @override
  String get loginWelcomeTitle => 'SUDA\'ya hoş geldin!';

  @override
  String get loginWelcomeSubtitle =>
      'Bir hikâyeye adım at ve İngilizce konuşmaya başla!';

  @override
  String get loginErrorIdToken =>
      'Google ID Token alınamadı. Lütfen tekrar dene.';

  @override
  String loginErrorFailed(String error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String get accountName => 'Ad';

  @override
  String get accountInfo => 'Hesap';

  @override
  String get accountDelete => 'Hesabı Sil';

  @override
  String get accountDeleteTitle => 'Hesap silinsin mi?';

  @override
  String get accountDeleteConfirmText =>
      'Tüm ilerlemen ve verilerin kalıcı olarak silinecek. Emin misin?';

  @override
  String get accountDeleteProfileImageTitle => 'Profil resmi silinsin mi?';

  @override
  String get accountDeleteProfileImageContent =>
      'Silinen profil resmi geri getirilemez.';

  @override
  String get accountGoBack => 'Geri Dön';

  @override
  String get accountDeleteAction => 'Sil';

  @override
  String get accountSubscription => 'Abonelik';

  @override
  String get accountFreePlanTitle => 'Ücretsiz Plan';

  @override
  String get accountFreePlanSubtitle =>
      'Daha fazla özelliğin kilidini açmak için Premium\'a geç';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle =>
      'Premium avantajlarından yararlanıyorsun';

  @override
  String accountPremiumRenewsOn(String date) {
    return '$date tarihinde yenilenir';
  }

  @override
  String get accountChangePlan => 'Planı Değiştir';

  @override
  String get changePlanTitle => 'Planı Değiştir';

  @override
  String get changePlanCurrentPlan => 'Mevcut Plan';

  @override
  String get changePlanAvailablePlans => 'Kullanılabilir Planlar';

  @override
  String changePlanRenewsOn(String date) {
    return '$date tarihinde yenilenir';
  }

  @override
  String get changePlanLoadFailed =>
      'Bilgiler yüklenemedi. Lütfen tekrar dene.';

  @override
  String get changePlanRetry => 'Tekrar dene';

  @override
  String get changePlanConfirmTitle => 'Plan değiştirilsin mi?';

  @override
  String get changePlanConfirmBody =>
      'Plan değişikliği bir sonraki faturalandırma tarihinde geçerli olur.';

  @override
  String get changePlanConfirmOk => 'Onayla';

  @override
  String get changePlanConfirmCancel => 'Mevcut Planı Koru';

  @override
  String get changePlanOldPurchaseMissing =>
      'Değiştirilecek aktif abonelik bulunamadı. Aboneliğin etkinleştikten sonra tekrar dene.';

  @override
  String get changePlanChangeRequested =>
      'Plan değişikliği talebiniz alındı. Bir sonraki faturalandırma tarihinde uygulanabilir.';

  @override
  String get cefrLevelTitle => 'İngilizce seviyeni seç';

  @override
  String get cefrLevelAbsoluteBeginner => 'Sıfırdan Başlangıç';

  @override
  String get cefrLevelBeginner => 'Başlangıç';

  @override
  String get cefrLevelBasic => 'Temel';

  @override
  String get cefrLevelIntermediate => 'Orta';

  @override
  String get firstCefrLevelTitle => 'İngilizce seviyen nedir?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'İngilizce okuyabiliyorum';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Temel selamlaşmaları ve basit ifadeleri biliyorum';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Kısa ve basit cümleleri anlayıp kullanabiliyorum';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Fikrimi söyleyip günlük konuşmalara katılabiliyorum';

  @override
  String get firstCefrLevelSettingsHint => 'İstediğin zaman değiştirebilirsin';

  @override
  String get firstCefrLevelConfirm => 'Onayla';

  @override
  String get feedbackPlaceholder =>
      'Fikirlerini, önerilerini veya karşılaştığın sorunları paylaş...';

  @override
  String get feedbackSend => 'Gönder';

  @override
  String get feedbackSuccess => 'Geri bildirimin için teşekkürler.';

  @override
  String get microphonePermissionDenied => 'Mikrofon izni olmadan başlanamaz.';

  @override
  String get holdMicrophoneToSpeak => 'Konuşmak için mikrofona basılı tut';

  @override
  String get roleplayTypeMessagePlaceholder => 'Mesajını yaz...';

  @override
  String get yourTurnFirst => 'İlk sıra sende!';

  @override
  String get sayLineBelowToStart => 'Başlamak için aşağıdaki cümleyi söyle.';

  @override
  String get roleplayExitWait => 'Bekle!';

  @override
  String get roleplayExitMessage =>
      'Şimdi çıkarsan ödülünü kaçıracaksın. Çıkmak istediğine emin misin?';

  @override
  String get roleplayExitKeepPlaying => 'Oynamaya Devam Et';

  @override
  String get roleplayExitExit => 'Çık';

  @override
  String get roleplayAutoHint => 'Otomatik İpucu';

  @override
  String get roleplayHintLabel => 'İpucu';

  @override
  String get roleplayHintShowAnswer =>
      'Önerilen İngilizce yanıtı görmek için dokun';

  @override
  String get roleplayVoiceSpeed => 'Ses Hızı';

  @override
  String get roleplayEndedFailed => 'Görev başarısız oldu...';

  @override
  String get roleplayEndedComplete => 'Rol yapmayı tamamladın';

  @override
  String get roleplayEndedEnding => 'Finale geçiliyor...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Yeterli ilerleme yok';

  @override
  String get roleplayFinishCompleted => 'Rol yapmayı tamamladın';

  @override
  String get roleplayFinishMovingToEnding => 'Finale geçiliyor...';

  @override
  String get roleplayAnalyzing => 'Rol yapman analiz ediliyor...';

  @override
  String get roleplayOpeningAiCharacter => 'Yapay Zekâ Karakteri';

  @override
  String get roleplayOpeningScenario => 'Senaryo';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'Yapay zekâ hata yapabilir.\nLütfen kişisel veya hassas bilgilerini paylaşma.';

  @override
  String get endingFailTitle => 'Tüm görevleri tamamlayamadın!';

  @override
  String get endingFailSubtitle => 'Tekrar dene ve hikâyenin tamamını keşfet.';

  @override
  String get roleplayTryAgainMessage =>
      'Ne yazık ki puanın ödül kazanmak için yeterince yüksek değildi.';

  @override
  String get endingReport => 'Sorun Bildir';

  @override
  String get endingHowWas => 'Rol yapma nasıldı?';

  @override
  String get endingNext => 'İleri';

  @override
  String get reportTitle => 'Sorun Bildir';

  @override
  String get profileHistory => 'Geçmiş';

  @override
  String get profileSaved => 'Kaydedilenler';

  @override
  String get profileHistoryEmpty => 'Henüz geçmiş yok';

  @override
  String get profileSavedEmpty => 'Henüz kaydedilmiş ifade yok.';

  @override
  String get profileSavedRemoveTitle => 'Kaydedilenlerden kaldırılsın mı?';

  @override
  String get profileSavedRemoveContent =>
      'Bu ifadeyi daha sonra Geçmiş bölümünde yeniden bulabilirsin.';

  @override
  String get profileSavedRemoveOk => 'Kaldır';

  @override
  String get profileSavedRemoveCancel => 'Biraz daha pratik yap';

  @override
  String get seriesOverviewTabEpisodes => 'Bölümler';

  @override
  String get seriesOverviewTabSimilarTopic => 'Benzer Konular';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Bölüm #$number';
  }

  @override
  String get seriesOverviewPlay => 'Oyna';

  @override
  String get seriesOverviewLocked => 'Kilitli';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Kilidi açmak için önceki bölümü tamamla.';

  @override
  String get notificationPermissionBlockedTitle => 'Bildirimler kapalı';

  @override
  String get notificationPermissionBlockedMessage =>
      'Anlık bildirimleri almak için cihaz ayarlarından bildirimleri aç.';

  @override
  String get openSettings => 'Ayarları Aç';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get notificationsEmpty => 'Henüz bildirim yok';

  @override
  String get notificationSendToday => 'Bugün';

  @override
  String get notificationSendOneDayAgo => '1 gün önce';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Hesabını sildikten 2 gün sonra tekrar kaydolabilirsin. Lütfen daha sonra tekrar dene.';

  @override
  String get expressionSavedToProfile => 'Profiline kaydedildi';

  @override
  String get expressionUnsavedToProfile => 'Kaydedilenlerden kaldırıldı';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Bu kez geri bildirim veremedik. Yanıtını 7 veya daha fazla kelimeyle genişletmeyi dene!';

  @override
  String get roleplayResultScoreMeaning => 'Anlam';

  @override
  String get roleplayResultScoreRelevance => 'Uygunluk';

  @override
  String get roleplayResultScoreVocabulary => 'Kelime Bilgisi';

  @override
  String get roleplayResultScoreGrammar => 'Dil Bilgisi';

  @override
  String get closePopup => 'Kapat';

  @override
  String get reviewChatTapHint => 'Sesi oynatmak için sohbet balonuna dokun.';

  @override
  String get reviewChatNoAudioToPlay => 'Oynatılacak ses yok.';

  @override
  String get seriesInformationTopicDifficulty => 'Konu Zorluğu';

  @override
  String get seriesInformationLearningGoals => 'Öğrenme Hedefleri';

  @override
  String get energyInfoTitle => 'Enerji';

  @override
  String get energyOutOfEnergyTitle => 'Enerjin Bitti';

  @override
  String get energyInfoRechargeUntil =>
      'Sonraki enerji dolumuna @@TIME@@ kaldı';

  @override
  String get energyInfoFull => 'Enerjin dolu.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Sınırsız Mod Aktif';

  @override
  String get energyInsufficient => 'Yeterli enerjin yok.';

  @override
  String get endRoleplay => 'Rol Yapmayı Bitir';

  @override
  String get energyEnablePushTitle => 'Bildirimleri Aç';

  @override
  String get energyEnablePushSubtitle =>
      'Bildirimleri aç ve enerjini tamamen doldur.';

  @override
  String get energyEnablePushPrice => 'Ücretsiz';

  @override
  String get energyEnablePushOfferBadge => 'TEK SEFERLİK TEKLİF';

  @override
  String get energyEnablePushCompleted => 'Enerjin doldu!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Sınırsız Oyun Bileti';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Satın alır almaz başlar. 10 dakika geçerlidir.';

  @override
  String get energyPurchaseCapacityTitle => 'Maksimum Enerji Artışı';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Yenilenebilen maksimum enerji kapasiteni kalıcı olarak 1 artır.';

  @override
  String get energyGoPremiumTitle => 'Premium\'a Geç';

  @override
  String get energyGoPremiumExplore => 'İncele';

  @override
  String get profileGoPremiumTitle => 'SUDA Premium\'a Geç';

  @override
  String get profileGoPremiumExplore => 'İncele';

  @override
  String get energyPurchasePendingApproval => 'Ödemen onay bekliyor';

  @override
  String get energyPurchaseNotCompleted => 'Satın alım tamamlanmadı.';

  @override
  String get welcomeGiftTitle => 'Hoş Geldin Hediyen Hazır!';

  @override
  String get welcomeGiftBenefitLead =>
      '10 dakika sınırsız oynamanın keyfini çıkar!';

  @override
  String get welcomeGiftLine2 => 'Premium özellikler açıldı';

  @override
  String get welcomeGiftLine3 => 'Sınırsız oyun modu açıldı';

  @override
  String get welcomeGiftStartNow => 'Şimdi Başla';

  @override
  String get paywallHeroTitle1 => 'Daha Fazla Pratik Yap';

  @override
  String get paywallHeroTitle2 => 'Daha Hızlı Geliş';

  @override
  String get paywallHeroBody =>
      'Premium ile daha uzun pratik yap ve yapay zekâ geri bildirimiyle İngilizce konuşma öz güvenini artır.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Daha Fazla Günlük Pratik';

  @override
  String get paywallBenefitMaxEnergy => 'Maksimum 30 Enerji';

  @override
  String get paywallBenefitAiFeedback => 'Yapay Zekâdan Cümle Geri Bildirimi';

  @override
  String get paywallChoosePlan => 'Planını Seç';

  @override
  String get paywallAnnualPlanTitle => 'Yıllık Plan';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Aylık plana göre %33\'ten fazla tasarruf et.';

  @override
  String get paywallMonthlyPlanTitle => 'Aylık Plan';

  @override
  String get paywallMonthlyPlanSubtitle => 'Esnek aylık erişim.';

  @override
  String get paywallBestBadge => 'EN İYİ';

  @override
  String get paywallCta => 'Şimdi Abone Ol';

  @override
  String get paywallAutoRenewNotice =>
      'Abonelik, mevcut faturalandırma dönemi sona ermeden en az 24 saat önce iptal edilmezse otomatik olarak yenilenir.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/ay';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/yıl';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Tebrikler!';

  @override
  String get paywallCompletedBody => 'Premium avantajların artık aktif.';

  @override
  String get paywallCompletedContinue => 'Devam Et';
}
