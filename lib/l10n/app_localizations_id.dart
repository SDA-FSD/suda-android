// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get agreementHeading =>
      'Tinjau dan setujui ketentuan berikut untuk melanjutkan.';

  @override
  String get agreementTermsLabel => 'Saya menyetujui Ketentuan Penggunaan.';

  @override
  String get agreementPrivacyLabel => 'Saya menyetujui Kebijakan Privasi.';

  @override
  String get agreementTermsTitle => 'Ketentuan Penggunaan';

  @override
  String get agreementPrivacyTitle => 'Kebijakan Privasi';

  @override
  String get agreementDetailsLink => 'Lihat detail';

  @override
  String get agreementButtonConfirm => 'Setuju dan lanjutkan';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsAccount => 'Akun';

  @override
  String get settingsRestorePurchases => 'Pulihkan pembelian';

  @override
  String get restorePurchasesNothing => 'Tidak ada pembelian untuk dipulihkan.';

  @override
  String get restorePurchasesCompleted => 'Pembelian berhasil dipulihkan.';

  @override
  String get settingsNotification => 'Notifikasi';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Tingkat bahasa Inggris';

  @override
  String get pushNotifications => 'Notifikasi push';

  @override
  String get pushNotificationsDesc =>
      'Dapatkan pengingat dan pembaruan penting.';

  @override
  String get settingsFeedback => 'Masukan';

  @override
  String get settingsAnnouncements => 'Pengumuman';

  @override
  String get announcementsEmpty => 'Belum ada pengumuman';

  @override
  String get noticesEmpty => 'Belum ada postingan';

  @override
  String get deletedPost => 'Postingan ini telah dihapus.';

  @override
  String get postNoLongerAvailable => 'Postingan ini sudah tidak tersedia.';

  @override
  String get backToHome => 'Kembali ke Beranda';

  @override
  String get settingsSignOut => 'Keluar';

  @override
  String get settingsFsdLaboratory => 'Laboratorium FSD';

  @override
  String get settingsPrivacy => 'Kebijakan Privasi';

  @override
  String get settingsTerms => 'Ketentuan Layanan';

  @override
  String get settingsOpenSource => 'Lisensi sumber terbuka';

  @override
  String loginWelcome(String name) {
    return 'Selamat datang, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Dengan melanjutkan, Anda menyetujui $terms dan $privacy kami.';
  }

  @override
  String get loginTermsTitle => 'Ketentuan Penggunaan';

  @override
  String get loginPrivacyTitle => 'Kebijakan Privasi';

  @override
  String get loginCatchphrase => 'Mulai bicara. Begitulah cara belajar.';

  @override
  String get loginWelcomeTitle => 'Selamat datang di SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Masuklah ke dalam cerita dan mulai berbicara dalam bahasa Inggris!';

  @override
  String get loginErrorIdToken =>
      'Gagal mendapatkan Token ID Google. Coba lagi.';

  @override
  String loginErrorFailed(String error) {
    return 'Login gagal: $error';
  }

  @override
  String get accountName => 'Nama';

  @override
  String get accountInfo => 'Akun';

  @override
  String get accountDelete => 'Hapus akun';

  @override
  String get accountDeleteTitle => 'Hapus akun?';

  @override
  String get accountDeleteConfirmText =>
      'Semua progres dan data Anda akan hilang secara permanen. Yakin ingin melanjutkan?';

  @override
  String get accountDeleteProfileImageTitle => 'Hapus foto profil?';

  @override
  String get accountDeleteProfileImageContent =>
      'Setelah dihapus, foto profil Anda tidak dapat dipulihkan.';

  @override
  String get accountGoBack => 'Kembali';

  @override
  String get accountDeleteAction => 'Hapus';

  @override
  String get accountSubscription => 'Langganan';

  @override
  String get accountFreePlanTitle => 'Paket Gratis';

  @override
  String get accountFreePlanSubtitle =>
      'Berlangganan Premium untuk membuka lebih banyak fitur';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Anda sedang menikmati manfaat Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Akan diperpanjang pada $date';
  }

  @override
  String get accountChangePlan => 'Ubah paket';

  @override
  String get changePlanTitle => 'Ubah paket';

  @override
  String get changePlanCurrentPlan => 'Paket saat ini';

  @override
  String get changePlanAvailablePlans => 'Paket yang tersedia';

  @override
  String changePlanRenewsOn(String date) {
    return 'Akan diperpanjang pada $date';
  }

  @override
  String get changePlanLoadFailed => 'Informasi tidak dapat dimuat. Coba lagi.';

  @override
  String get changePlanRetry => 'Coba lagi';

  @override
  String get changePlanConfirmTitle => 'Ubah paket?';

  @override
  String get changePlanConfirmBody =>
      'Perubahan paket akan berlaku pada tanggal penagihan berikutnya.';

  @override
  String get changePlanConfirmOk => 'Konfirmasi';

  @override
  String get changePlanConfirmCancel => 'Pertahankan paket saat ini';

  @override
  String get changePlanOldPurchaseMissing =>
      'Langganan aktif yang akan diubah tidak ditemukan. Coba lagi setelah langganan Anda aktif.';

  @override
  String get changePlanChangeRequested =>
      'Perubahan paket telah diminta. Perubahan mungkin berlaku pada tanggal penagihan berikutnya.';

  @override
  String get cefrLevelTitle => 'Pilih tingkat bahasa Inggris Anda';

  @override
  String get cefrLevelAbsoluteBeginner => 'Pemula total';

  @override
  String get cefrLevelBeginner => 'Pemula';

  @override
  String get cefrLevelBasic => 'Dasar';

  @override
  String get cefrLevelIntermediate => 'Menengah';

  @override
  String get firstCefrLevelTitle => 'Apa tingkat bahasa Inggris Anda?';

  @override
  String get firstCefrLevelDescriptionPreA1 =>
      'Saya bisa membaca bahasa Inggris';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Saya memahami salam dasar dan frasa sederhana';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Saya dapat menggunakan dan memahami kalimat pendek dan sederhana';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Saya dapat menyampaikan pendapat dan mengikuti percakapan sehari-hari';

  @override
  String get firstCefrLevelSettingsHint => 'Bisa diubah kapan saja';

  @override
  String get firstCefrLevelConfirm => 'Konfirmasi';

  @override
  String get feedbackPlaceholder =>
      'Bagikan pendapat, saran, atau masalah yang Anda temui...';

  @override
  String get feedbackSend => 'Kirim';

  @override
  String get feedbackSuccess => 'Terima kasih atas masukan Anda.';

  @override
  String get microphonePermissionDenied =>
      'Tidak dapat memulai tanpa izin mikrofon.';

  @override
  String get holdMicrophoneToSpeak =>
      'Tekan dan tahan mikrofon untuk berbicara';

  @override
  String get roleplayTypeMessagePlaceholder => 'Ketik pesan Anda...';

  @override
  String get yourTurnFirst => 'Anda dulu!';

  @override
  String get sayLineBelowToStart => 'Ucapkan kalimat di bawah untuk memulai.';

  @override
  String get roleplayExitWait => 'Tunggu!';

  @override
  String get roleplayExitMessage =>
      'Jika keluar sekarang, Anda akan kehilangan hadiah. Yakin ingin keluar?';

  @override
  String get roleplayExitKeepPlaying => 'Lanjut bermain';

  @override
  String get roleplayExitExit => 'Keluar';

  @override
  String get roleplayAutoHint => 'Petunjuk otomatis';

  @override
  String get roleplayHintLabel => 'Petunjuk';

  @override
  String get roleplayHintShowAnswer =>
      'Ketuk untuk melihat saran jawaban dalam bahasa Inggris';

  @override
  String get roleplayVoiceSpeed => 'Kecepatan bicara';

  @override
  String get roleplayEndedFailed => 'Misi gagal...';

  @override
  String get roleplayEndedComplete => 'Roleplay selesai';

  @override
  String get roleplayEndedEnding => 'Menuju akhir cerita...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Progres belum cukup';

  @override
  String get roleplayFinishCompleted => 'Roleplay selesai';

  @override
  String get roleplayFinishMovingToEnding => 'Menuju akhir cerita...';

  @override
  String get roleplayAnalyzing => 'Menganalisis roleplay Anda...';

  @override
  String get roleplayOpeningAiCharacter => 'Karakter AI';

  @override
  String get roleplayOpeningScenario => 'Skenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI dapat membuat kesalahan.\nJangan bagikan informasi pribadi atau sensitif.';

  @override
  String get endingFailTitle => 'Anda belum menyelesaikan semua misi!';

  @override
  String get endingFailSubtitle => 'Coba lagi untuk mengungkap seluruh cerita.';

  @override
  String get roleplayTryAgainMessage =>
      'Sayangnya, skor Anda belum cukup untuk mendapatkan hadiah.';

  @override
  String get endingReport => 'Laporkan masalah';

  @override
  String get endingHowWas => 'Bagaimana roleplay-nya?';

  @override
  String get endingNext => 'Berikutnya';

  @override
  String get reportTitle => 'Laporkan masalah';

  @override
  String get profileHistory => 'Riwayat';

  @override
  String get profileSaved => 'Tersimpan';

  @override
  String get profileHistoryEmpty => 'Belum ada riwayat';

  @override
  String get profileSavedEmpty => 'Belum ada ungkapan tersimpan.';

  @override
  String get profileSavedRemoveTitle => 'Hapus dari simpanan?';

  @override
  String get profileSavedRemoveContent =>
      'Anda dapat menemukannya lagi nanti di Riwayat.';

  @override
  String get profileSavedRemoveOk => 'Hapus';

  @override
  String get profileSavedRemoveCancel => 'Latihan lagi';

  @override
  String get seriesOverviewTabEpisodes => 'Episode';

  @override
  String get seriesOverviewTabSimilarTopic => 'Topik serupa';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episode #$number';
  }

  @override
  String get seriesOverviewPlay => 'Main';

  @override
  String get seriesOverviewLocked => 'Terkunci';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Selesaikan episode sebelumnya untuk membukanya.';

  @override
  String get notificationPermissionBlockedTitle => 'Notifikasi dinonaktifkan';

  @override
  String get notificationPermissionBlockedMessage =>
      'Aktifkan notifikasi di pengaturan perangkat untuk menerima notifikasi push.';

  @override
  String get openSettings => 'Buka Pengaturan';

  @override
  String get notificationsTitle => 'Notifikasi';

  @override
  String get notificationsEmpty => 'Belum ada notifikasi';

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
      'Anda dapat mendaftar lagi 2 hari setelah menghapus akun. Coba lagi nanti.';

  @override
  String get expressionSavedToProfile => 'Disimpan ke profil Anda';

  @override
  String get expressionUnsavedToProfile => 'Tidak lagi tersimpan';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Kali ini kami belum bisa memberikan masukan. Coba jawab dengan setidaknya 7 kata!';

  @override
  String get roleplayResultScoreMeaning => 'Makna';

  @override
  String get roleplayResultScoreRelevance => 'Relevansi';

  @override
  String get roleplayResultScoreVocabulary => 'Kosakata';

  @override
  String get roleplayResultScoreGrammar => 'Tata bahasa';

  @override
  String get closePopup => 'Tutup';

  @override
  String get reviewChatTapHint => 'Ketuk gelembung chat untuk memutar audio.';

  @override
  String get reviewChatNoAudioToPlay => 'Tidak ada audio untuk diputar.';

  @override
  String get seriesInformationTopicDifficulty => 'Tingkat kesulitan topik';

  @override
  String get seriesInformationLearningGoals => 'Tujuan belajar';

  @override
  String get energyInfoTitle => 'Energi';

  @override
  String get energyOutOfEnergyTitle => 'Energi habis';

  @override
  String get energyInfoRechargeUntil => 'Isi ulang berikutnya dalam @@TIME@@';

  @override
  String get energyInfoFull => 'Energi Anda sudah penuh.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Mode Tanpa Batas Aktif';

  @override
  String get energyInsufficient => 'Energi Anda tidak cukup.';

  @override
  String get endRoleplay => 'Akhiri roleplay';

  @override
  String get energyEnablePushTitle => 'Aktifkan notifikasi';

  @override
  String get energyEnablePushSubtitle =>
      'Aktifkan notifikasi dan isi ulang energi hingga penuh.';

  @override
  String get energyEnablePushPrice => 'Gratis';

  @override
  String get energyEnablePushOfferBadge => 'PENAWARAN SEKALI SAJA';

  @override
  String get energyEnablePushCompleted => 'Energi berhasil diisi ulang!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Paket Tanpa Batas';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Aktif segera setelah dibeli. Berlaku selama 10 menit.';

  @override
  String get energyPurchaseCapacityTitle => 'Upgrade Energi Maksimum';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Kapasitas maksimum energi yang dapat diisi ulang bertambah 1 secara permanen.';

  @override
  String get energyGoPremiumTitle => 'Beralih ke Premium';

  @override
  String get energyGoPremiumExplore => 'Jelajahi';

  @override
  String get profileGoPremiumTitle => 'Dapatkan SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Jelajahi';

  @override
  String get energyPurchasePendingApproval =>
      'Pembayaran Anda menunggu persetujuan';

  @override
  String get energyPurchaseNotCompleted =>
      'Pembelian tidak dapat diselesaikan.';

  @override
  String get welcomeGiftTitle => 'Hadiah selamat datang sudah tiba!';

  @override
  String get welcomeGiftBenefitLead =>
      'Nikmati akses bermain tanpa batas selama 10 menit!';

  @override
  String get welcomeGiftLine2 => 'Fitur Premium aktif';

  @override
  String get welcomeGiftLine3 => 'Mode Tanpa Batas aktif';

  @override
  String get welcomeGiftStartNow => 'Mulai sekarang';

  @override
  String get paywallHeroTitle1 => 'Berlatih lebih banyak';

  @override
  String get paywallHeroTitle2 => 'Berkembang lebih cepat';

  @override
  String get paywallHeroBody =>
      'Berlatih lebih lama dengan Premium dan dapatkan masukan dari AI agar makin percaya diri berbahasa Inggris.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Lebih banyak latihan harian';

  @override
  String get paywallBenefitMaxEnergy => 'Kapasitas Energi hingga 30';

  @override
  String get paywallBenefitAiFeedback => 'Masukan AI untuk kalimat';

  @override
  String get paywallChoosePlan => 'Pilih paket Anda';

  @override
  String get paywallAnnualPlanTitle => 'Paket tahunan';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Hemat lebih dari 33% dibanding paket bulanan.';

  @override
  String get paywallMonthlyPlanTitle => 'Paket bulanan';

  @override
  String get paywallMonthlyPlanSubtitle => 'Akses bulanan yang fleksibel.';

  @override
  String get paywallBestBadge => 'TERBAIK';

  @override
  String get paywallCta => 'Berlangganan sekarang';

  @override
  String get paywallAutoRenewNotice =>
      'Langganan diperpanjang secara otomatis kecuali dibatalkan setidaknya 24 jam sebelum periode penagihan saat ini berakhir.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/bulan';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/tahun';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Selamat!';

  @override
  String get paywallCompletedBody => 'Manfaat Premium Anda kini aktif.';

  @override
  String get paywallCompletedContinue => 'Lanjutkan';

  @override
  String get roleplayChooseYourRole => 'Pilih peranmu';

  @override
  String get roleplaySimilarRoleplays => 'Roleplay serupa';

  @override
  String get roleplayBeingPrepared => 'Roleplay ini sedang disiapkan.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Selesaikan semua ending peran sebelumnya untuk membuka peran ini.';

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
  String get tutorialPage1Title => 'Cek **Misi** kamu\ndan mulai percakapan.';

  @override
  String get tutorialPage1Tip =>
      '*Tip: Semakin alami kamu berbicara,\nsemakin besar hadiahnya!';

  @override
  String get tutorialPage2Title =>
      'Gunakan **Penerjemah**\nsaat kamu tidak mengerti.';

  @override
  String get tutorialPage3Title => 'Gunakan **Petunjuk**\nsaat kamu macet.';

  @override
  String get tutorialPage3Subtitle =>
      'Kamu bisa mengaktifkan atau menonaktifkan\npetunjuk otomatis kapan saja.';

  @override
  String get tutorialPage4Title =>
      'Kalau pengucapan sulit,\ndengar dulu, lalu ulangi.';

  @override
  String get tutorialPage4Tip =>
      '*Tip: Coba jawab tanpa melihat terjemahan\nuntuk skor yang lebih tinggi.';

  @override
  String get tutorialPage5Title => 'Tidak bisa berbicara keras?';

  @override
  String get tutorialPage5Subtitle => 'Beralih ke **Mode Teks**.';

  @override
  String get tutorialPage6Title =>
      'Tidak ada yang menghakimi.\nKamu pasti bisa!';
}
