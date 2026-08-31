// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get agreementHeading =>
      'Sila semak dan setujui perkara di bawah untuk meneruskan.';

  @override
  String get agreementTermsLabel => 'Saya bersetuju dengan Terma Penggunaan.';

  @override
  String get agreementPrivacyLabel => 'Saya bersetuju dengan Dasar Privasi.';

  @override
  String get agreementTermsTitle => 'Terma Penggunaan';

  @override
  String get agreementPrivacyTitle => 'Dasar Privasi';

  @override
  String get agreementDetailsLink => 'Lihat butiran';

  @override
  String get agreementButtonConfirm => 'Setuju dan teruskan';

  @override
  String get settingsTitle => 'Tetapan';

  @override
  String get settingsAccount => 'Akaun';

  @override
  String get settingsRestorePurchases => 'Pulihkan Pembelian';

  @override
  String get restorePurchasesNothing => 'Tiada pembelian untuk dipulihkan.';

  @override
  String get restorePurchasesCompleted => 'Pembelian dipulihkan.';

  @override
  String get settingsNotification => 'Pemberitahuan';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Tahap Bahasa Inggeris';

  @override
  String get pushNotifications => 'Pemberitahuan Push';

  @override
  String get pushNotificationsDesc =>
      'Terima peringatan dan kemas kini penting.';

  @override
  String get settingsFeedback => 'Maklum Balas';

  @override
  String get settingsAnnouncements => 'Pengumuman';

  @override
  String get announcementsEmpty => 'Belum ada pengumuman';

  @override
  String get noticesEmpty => 'Belum ada siaran';

  @override
  String get deletedPost => 'Siaran ini telah dipadamkan.';

  @override
  String get postNoLongerAvailable => 'Siaran ini tidak lagi tersedia.';

  @override
  String get backToHome => 'Kembali ke Laman Utama';

  @override
  String get settingsSignOut => 'Log Keluar';

  @override
  String get settingsFsdLaboratory => 'Makmal FSD';

  @override
  String get settingsPrivacy => 'Dasar Privasi';

  @override
  String get settingsTerms => 'Terma Perkhidmatan';

  @override
  String get settingsOpenSource => 'Lesen Sumber Terbuka';

  @override
  String loginWelcome(String name) {
    return 'Selamat datang, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Dengan meneruskan, anda bersetuju dengan $terms dan $privacy kami.';
  }

  @override
  String get loginTermsTitle => 'Terma Penggunaan';

  @override
  String get loginPrivacyTitle => 'Dasar Privasi';

  @override
  String get loginCatchphrase => 'Mula bercakap. Begitulah cara anda belajar.';

  @override
  String get loginWelcomeTitle => 'Selamat datang ke SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Masuk ke dalam cerita dan mula bercakap dalam bahasa Inggeris!';

  @override
  String get loginErrorIdToken =>
      'Gagal mendapatkan Token ID Google. Sila cuba lagi.';

  @override
  String loginErrorFailed(String error) {
    return 'Log masuk gagal: $error';
  }

  @override
  String get accountName => 'Nama';

  @override
  String get accountInfo => 'Akaun';

  @override
  String get accountDelete => 'Padam Akaun';

  @override
  String get accountDeleteTitle => 'Padam Akaun?';

  @override
  String get accountDeleteConfirmText =>
      'Semua kemajuan dan data anda akan hilang secara kekal. Adakah anda pasti?';

  @override
  String get accountDeleteProfileImageTitle => 'Padam gambar profil?';

  @override
  String get accountDeleteProfileImageContent =>
      'Selepas dipadamkan, gambar profil anda tidak boleh dipulihkan.';

  @override
  String get accountGoBack => 'Kembali';

  @override
  String get accountDeleteAction => 'Padam';

  @override
  String get accountSubscription => 'Langganan';

  @override
  String get accountFreePlanTitle => 'Pelan Percuma';

  @override
  String get accountFreePlanSubtitle =>
      'Dapatkan Premium untuk membuka lebih banyak ciri';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Anda sedang menikmati manfaat Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Akan diperbaharui pada $date';
  }

  @override
  String get accountChangePlan => 'Tukar Pelan';

  @override
  String get changePlanTitle => 'Tukar Pelan';

  @override
  String get changePlanCurrentPlan => 'Pelan Semasa';

  @override
  String get changePlanAvailablePlans => 'Pelan Tersedia';

  @override
  String changePlanRenewsOn(String date) {
    return 'Akan diperbaharui pada $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Maklumat tidak dapat dimuatkan. Sila cuba lagi.';

  @override
  String get changePlanRetry => 'Cuba lagi';

  @override
  String get changePlanConfirmTitle => 'Tukar Pelan?';

  @override
  String get changePlanConfirmBody =>
      'Perubahan pelan berkuat kuasa pada tarikh pengebilan anda yang seterusnya.';

  @override
  String get changePlanConfirmOk => 'Sahkan';

  @override
  String get changePlanConfirmCancel => 'Kekalkan Pelan Semasa';

  @override
  String get changePlanOldPurchaseMissing =>
      'Langganan aktif untuk ditukar tidak ditemui. Cuba lagi selepas langganan anda aktif.';

  @override
  String get changePlanChangeRequested =>
      'Permintaan pertukaran pelan dihantar. Perubahan mungkin berkuat kuasa pada tarikh pengebilan seterusnya.';

  @override
  String get cefrLevelTitle => 'Pilih tahap bahasa Inggeris anda';

  @override
  String get cefrLevelAbsoluteBeginner => 'Baru Bermula';

  @override
  String get cefrLevelBeginner => 'Pemula';

  @override
  String get cefrLevelBasic => 'Asas';

  @override
  String get cefrLevelIntermediate => 'Pertengahan';

  @override
  String get firstCefrLevelTitle => 'Apakah tahap bahasa Inggeris anda?';

  @override
  String get firstCefrLevelDescriptionPreA1 =>
      'Saya boleh membaca bahasa Inggeris';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Saya tahu sapaan asas dan frasa mudah';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Saya boleh menggunakan dan memahami ayat pendek dan mudah';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Saya boleh berkongsi pendapat dan menyertai perbualan harian';

  @override
  String get firstCefrLevelSettingsHint => 'Boleh ditukar pada bila-bila masa';

  @override
  String get firstCefrLevelConfirm => 'Sahkan';

  @override
  String get feedbackPlaceholder =>
      'Kongsi pendapat, cadangan atau sebarang masalah yang anda hadapi...';

  @override
  String get feedbackSend => 'Hantar';

  @override
  String get feedbackSuccess => 'Terima kasih atas maklum balas anda.';

  @override
  String get microphonePermissionDenied =>
      'Tidak dapat bermula tanpa kebenaran mikrofon.';

  @override
  String get holdMicrophoneToSpeak => 'Tekan dan tahan mikrofon untuk bercakap';

  @override
  String get roleplayTypeMessagePlaceholder => 'Taip mesej anda...';

  @override
  String get yourTurnFirst => 'Giliran anda dulu!';

  @override
  String get sayLineBelowToStart => 'Sebut ayat di bawah untuk bermula.';

  @override
  String get roleplayExitWait => 'Tunggu!';

  @override
  String get roleplayExitMessage =>
      'Jika keluar sekarang, anda akan terlepas ganjaran. Adakah anda pasti mahu keluar?';

  @override
  String get roleplayExitKeepPlaying => 'Teruskan Bermain';

  @override
  String get roleplayExitExit => 'Keluar';

  @override
  String get roleplayAutoHint => 'Petunjuk Automatik';

  @override
  String get roleplayHintLabel => 'Petunjuk';

  @override
  String get roleplayHintShowAnswer =>
      'Ketik untuk melihat cadangan jawapan dalam bahasa Inggeris';

  @override
  String get roleplayVoiceSpeed => 'Kelajuan Pertuturan';

  @override
  String get roleplayEndedFailed => 'Misi Gagal...';

  @override
  String get roleplayEndedComplete => 'Lakon peranan selesai';

  @override
  String get roleplayEndedEnding => 'Menuju ke penamat...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Kemajuan tidak mencukupi';

  @override
  String get roleplayFinishCompleted => 'Lakon peranan selesai';

  @override
  String get roleplayFinishMovingToEnding => 'Menuju ke penamat...';

  @override
  String get roleplayAnalyzing => 'Menganalisis sesi lakon peranan anda...';

  @override
  String get roleplayOpeningAiCharacter => 'Watak AI';

  @override
  String get roleplayOpeningScenario => 'Senario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI boleh melakukan kesilapan.\nJangan kongsi maklumat peribadi atau sensitif.';

  @override
  String get endingFailTitle => 'Anda belum menyelesaikan semua misi!';

  @override
  String get endingFailSubtitle => 'Cuba lagi dan temui keseluruhan cerita.';

  @override
  String get roleplayTryAgainMessage =>
      'Malangnya, markah anda tidak cukup tinggi untuk memperoleh ganjaran.';

  @override
  String get endingReport => 'Laporkan Masalah';

  @override
  String get endingHowWas => 'Bagaimanakah sesi lakon peranan tadi?';

  @override
  String get endingNext => 'Seterusnya';

  @override
  String get reportTitle => 'Laporkan Masalah';

  @override
  String get profileHistory => 'Sejarah';

  @override
  String get profileSaved => 'Disimpan';

  @override
  String get profileHistoryEmpty => 'Belum ada sejarah';

  @override
  String get profileSavedEmpty => 'Belum ada ungkapan disimpan.';

  @override
  String get profileSavedRemoveTitle => 'Alih keluar daripada simpanan?';

  @override
  String get profileSavedRemoveContent =>
      'Anda boleh menemuinya semula dalam Sejarah nanti.';

  @override
  String get profileSavedRemoveOk => 'Alih keluar';

  @override
  String get profileSavedRemoveCancel => 'Berlatih lagi';

  @override
  String get seriesOverviewTabEpisodes => 'Episod';

  @override
  String get seriesOverviewTabSimilarTopic => 'Topik Serupa';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episod #$number';
  }

  @override
  String get seriesOverviewPlay => 'Main';

  @override
  String get seriesOverviewLocked => 'Dikunci';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Selesaikan episod sebelumnya untuk membuka kunci.';

  @override
  String get notificationPermissionBlockedTitle => 'Pemberitahuan dimatikan';

  @override
  String get notificationPermissionBlockedMessage =>
      'Hidupkan pemberitahuan dalam tetapan peranti untuk menerima pemberitahuan push.';

  @override
  String get openSettings => 'Buka Tetapan';

  @override
  String get notificationsTitle => 'Pemberitahuan';

  @override
  String get notificationsEmpty => 'Belum ada pemberitahuan';

  @override
  String get notificationSendToday => 'Hari ini';

  @override
  String get notificationSendOneDayAgo => '1 hari lalu';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count hari lalu';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Anda boleh mendaftar semula 2 hari selepas memadamkan akaun. Sila cuba lagi kemudian.';

  @override
  String get expressionSavedToProfile => 'Disimpan dalam profil anda';

  @override
  String get expressionUnsavedToProfile => 'Dialih keluar daripada simpanan';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Kami tidak dapat memberikan maklum balas kali ini. Cuba panjangkan jawapan anda kepada 7 perkataan atau lebih!';

  @override
  String get roleplayResultScoreMeaning => 'Maksud';

  @override
  String get roleplayResultScoreRelevance => 'Kaitan';

  @override
  String get roleplayResultScoreVocabulary => 'Kosa Kata';

  @override
  String get roleplayResultScoreGrammar => 'Tatabahasa';

  @override
  String get closePopup => 'Tutup';

  @override
  String get reviewChatTapHint =>
      'Ketik gelembung sembang untuk memainkan audio.';

  @override
  String get reviewChatNoAudioToPlay => 'Tiada audio untuk dimainkan.';

  @override
  String get seriesInformationTopicDifficulty => 'Tahap Kesukaran Topik';

  @override
  String get seriesInformationLearningGoals => 'Matlamat Pembelajaran';

  @override
  String get energyInfoTitle => 'Tenaga';

  @override
  String get energyOutOfEnergyTitle => 'Kehabisan Tenaga';

  @override
  String get energyInfoRechargeUntil => 'Cas semula seterusnya dalam @@TIME@@';

  @override
  String get energyInfoFull => 'Tenaga anda penuh.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Mod Tanpa Had Aktif';

  @override
  String get energyInsufficient => 'Tenaga anda tidak mencukupi.';

  @override
  String get endRoleplay => 'Tamatkan lakon peranan';

  @override
  String get energyEnablePushTitle => 'Hidupkan Pemberitahuan';

  @override
  String get energyEnablePushSubtitle =>
      'Hidupkan pemberitahuan dan isi semula tenaga hingga penuh.';

  @override
  String get energyEnablePushPrice => 'Percuma';

  @override
  String get energyEnablePushOfferBadge => 'TAWARAN SEKALI SAHAJA';

  @override
  String get energyEnablePushCompleted => 'Tenaga diisi semula!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Pas Tanpa Had';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Bermula serta-merta selepas pembelian. Sah selama 10 minit.';

  @override
  String get energyPurchaseCapacityTitle => 'Naik Taraf Tenaga Maksimum';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Tingkatkan had tenaga yang boleh dicas semula sebanyak 1 secara kekal.';

  @override
  String get energyGoPremiumTitle => 'Langgan Premium';

  @override
  String get energyGoPremiumExplore => 'Terokai';

  @override
  String get profileGoPremiumTitle => 'Dapatkan SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Terokai';

  @override
  String get energyPurchasePendingApproval =>
      'Pembayaran anda sedang menunggu kelulusan';

  @override
  String get energyPurchaseNotCompleted =>
      'Pembelian tidak dapat diselesaikan.';

  @override
  String get iapPurchaseProcessing => 'Pembelian anda sedang diproses.';

  @override
  String get iapPurchaseCompleted => 'Pembelian selesai.';

  @override
  String get welcomeGiftTitle => 'Hadiah Alu-aluan Anda Sudah Tiba!';

  @override
  String get welcomeGiftBenefitLead =>
      'Nikmati akses bermain tanpa had selama 10 minit!';

  @override
  String get welcomeGiftLine2 => 'Ciri Premium diaktifkan';

  @override
  String get welcomeGiftLine3 => 'Akses bermain tanpa had diaktifkan';

  @override
  String get welcomeGiftStartNow => 'Mula Sekarang';

  @override
  String get paywallHeroTitle1 => 'Berlatih Lebih Banyak';

  @override
  String get paywallHeroTitle2 => 'Maju\nLebih pantas';

  @override
  String get paywallHeroBody =>
      'Berlatih lebih lama dengan Premium dan dapatkan maklum balas AI untuk membina keyakinan berbahasa Inggeris.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitMaxEnergy => 'Had Tenaga hingga 30';

  @override
  String get paywallBenefitAiFeedback => 'Maklum Balas AI untuk Ayat';

  @override
  String get paywallBenefitProfileBadge => 'Lencana Premium pada Profil';

  @override
  String get paywallChoosePlan => 'Pilih Pelan Anda';

  @override
  String get paywallAnnualPlanTitle => 'Pelan Tahunan';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Jimat lebih 33% berbanding pelan bulanan.';

  @override
  String get paywallMonthlyPlanTitle => 'Pelan Bulanan';

  @override
  String get paywallMonthlyPlanSubtitle => 'Akses bulanan yang fleksibel.';

  @override
  String get paywallBestBadge => 'TERBAIK';

  @override
  String get paywallCta => 'Langgan Sekarang';

  @override
  String get paywallAutoRenewNotice =>
      'Langganan diperbaharui secara automatik kecuali dibatalkan sekurang-kurangnya 24 jam sebelum tempoh pengebilan semasa berakhir.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/bulan';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/tahun';
  }

  @override
  String get paywallFallbackAnnualPerMonth => 'RM36.67';

  @override
  String get paywallFallbackAnnual => 'RM439.99';

  @override
  String get paywallFallbackMonthly => 'RM61.99';

  @override
  String get paywallFallbackMonthlyTimes12 => 'RM743.88';

  @override
  String get paywallCompletedTitle => 'Tahniah!';

  @override
  String get paywallCompletedBody => 'Manfaat Premium anda kini aktif.';

  @override
  String get paywallCompletedContinue => 'Teruskan';

  @override
  String get roleplayChooseYourRole => 'Pilih peranan anda';

  @override
  String get roleplaySimilarRoleplays => 'Roleplay serupa';

  @override
  String get roleplayBeingPrepared => 'Roleplay ini sedang disediakan.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Lengkapkan semua ending peranan sebelumnya untuk membuka peranan ini.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% selesai';
  }

  @override
  String get roleplayTurnGradeA => 'wow!';

  @override
  String get roleplayTurnGradeB => 'ok!';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'oh…';

  @override
  String get tutorialPage1Title =>
      'Semak **Misi** anda\ndan mulakan perbualan.';

  @override
  String get tutorialPage1Tip =>
      '*Tip: Semakin semula jadi anda bercakap,\nsemakin besar ganjaran anda!';

  @override
  String get tutorialPage2Title =>
      'Gunakan **Penterjemah**\napabila anda tidak faham.';

  @override
  String get tutorialPage3Title =>
      'Gunakan **Petunjuk**\napabila anda tersekat.';

  @override
  String get tutorialPage3Subtitle =>
      'Anda boleh menghidupkan atau mematikan\npetunjuk automatik pada bila-bila masa.';

  @override
  String get tutorialPage4Title =>
      'Jika sebutan sukar,\ndengar dahulu, kemudian ulang.';

  @override
  String get tutorialPage4Tip =>
      '*Tip: Cuba jawab tanpa melihat terjemahan\nuntuk mendapat markah lebih tinggi.';

  @override
  String get tutorialPage5Title => 'Tidak boleh bercakap kuat?';

  @override
  String get tutorialPage5Subtitle => 'Tukar kepada **Mod Teks**.';

  @override
  String get tutorialPage6Title => 'Tiada siapa yang menghakimi.\nAnda mampu!';
}
