// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get agreementHeading =>
      'Bitte lies die folgenden Bedingungen und stimme ihnen zu, um fortzufahren.';

  @override
  String get agreementTermsLabel => 'Ich stimme den Nutzungsbedingungen zu.';

  @override
  String get agreementPrivacyLabel => 'Ich stimme der Datenschutzerklärung zu.';

  @override
  String get agreementTermsTitle => 'Nutzungsbedingungen';

  @override
  String get agreementPrivacyTitle => 'Datenschutzerklärung';

  @override
  String get agreementDetailsLink => 'Details anzeigen';

  @override
  String get agreementButtonConfirm => 'Zustimmen und weiter';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get restorePurchasesNothing =>
      'Keine wiederherstellbaren Käufe gefunden.';

  @override
  String get restorePurchasesCompleted => 'Käufe wiederhergestellt.';

  @override
  String get settingsNotification => 'Benachrichtigungen';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Englischniveau';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get pushNotificationsDesc =>
      'Erhalte Erinnerungen und wichtige Updates.';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsAnnouncements => 'Ankündigungen';

  @override
  String get announcementsEmpty => 'Noch keine Ankündigungen';

  @override
  String get noticesEmpty => 'Noch keine Beiträge';

  @override
  String get deletedPost => 'Dieser Beitrag wurde gelöscht.';

  @override
  String get postNoLongerAvailable =>
      'Dieser Beitrag ist nicht mehr verfügbar.';

  @override
  String get backToHome => 'Zur Startseite';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsFsdLaboratory => 'FSD-Labor';

  @override
  String get settingsPrivacy => 'Datenschutzerklärung';

  @override
  String get settingsTerms => 'Nutzungsbedingungen';

  @override
  String get settingsOpenSource => 'Open-Source-Lizenzen';

  @override
  String loginWelcome(String name) {
    return 'Willkommen, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Wenn du fortfährst, stimmst du unseren $terms und unserer $privacy zu.';
  }

  @override
  String get loginTermsTitle => 'Nutzungsbedingungen';

  @override
  String get loginPrivacyTitle => 'Datenschutzerklärung';

  @override
  String get loginCatchphrase => 'Sprich einfach. So lernst du.';

  @override
  String get loginWelcomeTitle => 'Willkommen bei SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Tauche in eine Geschichte ein und sprich Englisch!';

  @override
  String get loginErrorIdToken =>
      'Google-ID-Token konnte nicht abgerufen werden. Bitte versuche es erneut.';

  @override
  String loginErrorFailed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get accountName => 'Name';

  @override
  String get accountInfo => 'Konto';

  @override
  String get accountDelete => 'Konto löschen';

  @override
  String get accountDeleteTitle => 'Konto löschen?';

  @override
  String get accountDeleteConfirmText =>
      'Dein gesamter Fortschritt und alle Daten gehen dauerhaft verloren. Bist du sicher?';

  @override
  String get accountDeleteProfileImageTitle => 'Profilbild löschen?';

  @override
  String get accountDeleteProfileImageContent =>
      'Nach dem Löschen kann dein Profilbild nicht wiederhergestellt werden.';

  @override
  String get accountGoBack => 'Zurück';

  @override
  String get accountDeleteAction => 'Löschen';

  @override
  String get accountSubscription => 'Abonnement';

  @override
  String get accountFreePlanTitle => 'Kostenloser Tarif';

  @override
  String get accountFreePlanSubtitle =>
      'Mit Premium schaltest du weitere Funktionen frei';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Deine Premium-Vorteile sind aktiv';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Verlängert sich am $date';
  }

  @override
  String get accountChangePlan => 'Tarif ändern';

  @override
  String get changePlanTitle => 'Tarif ändern';

  @override
  String get changePlanCurrentPlan => 'Aktueller Tarif';

  @override
  String get changePlanAvailablePlans => 'Verfügbare Tarife';

  @override
  String changePlanRenewsOn(String date) {
    return 'Verlängert sich am $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Informationen konnten nicht geladen werden. Bitte versuche es erneut.';

  @override
  String get changePlanRetry => 'Erneut versuchen';

  @override
  String get changePlanConfirmTitle => 'Tarif ändern?';

  @override
  String get changePlanConfirmBody =>
      'Die Tarifänderung gilt ab deinem nächsten Abrechnungstermin.';

  @override
  String get changePlanConfirmOk => 'Bestätigen';

  @override
  String get changePlanConfirmCancel => 'Aktuellen Tarif behalten';

  @override
  String get changePlanOldPurchaseMissing =>
      'Kein aktives Abonnement zum Ändern gefunden. Versuche es erneut, sobald dein Abonnement aktiv ist.';

  @override
  String get changePlanChangeRequested =>
      'Tarifwechsel angefordert. Er wird möglicherweise am nächsten Abrechnungstermin wirksam.';

  @override
  String get cefrLevelTitle => 'Wähle dein Englischniveau';

  @override
  String get cefrLevelAbsoluteBeginner => 'Keine Vorkenntnisse';

  @override
  String get cefrLevelBeginner => 'Anfänger';

  @override
  String get cefrLevelBasic => 'Grundkenntnisse';

  @override
  String get cefrLevelIntermediate => 'Mittelstufe';

  @override
  String get firstCefrLevelTitle => 'Wie gut ist dein Englisch?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Ich kann Englisch lesen';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Ich kenne einfache Begrüßungen und Wendungen';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Ich kann kurze, einfache Sätze verstehen und verwenden';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Ich kann meine Meinung äußern und mich an Alltagsgesprächen beteiligen';

  @override
  String get firstCefrLevelSettingsHint => 'Du kannst es jederzeit ändern';

  @override
  String get firstCefrLevelConfirm => 'Bestätigen';

  @override
  String get feedbackPlaceholder =>
      'Teile uns deine Meinung, Vorschläge oder Probleme mit ...';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackSuccess => 'Danke für dein Feedback.';

  @override
  String get microphonePermissionDenied =>
      'Zum Starten ist der Mikrofonzugriff erforderlich.';

  @override
  String get holdMicrophoneToSpeak => 'Mikrofon gedrückt halten und sprechen';

  @override
  String get roleplayTypeMessagePlaceholder => 'Nachricht eingeben ...';

  @override
  String get yourTurnFirst => 'Du fängst an!';

  @override
  String get sayLineBelowToStart => 'Sprich den Satz unten, um zu starten.';

  @override
  String get roleplayExitWait => 'Warte!';

  @override
  String get roleplayExitMessage =>
      'Wenn du jetzt gehst, verpasst du deine Belohnung. Möchtest du wirklich aufhören?';

  @override
  String get roleplayExitKeepPlaying => 'Weiterspielen';

  @override
  String get roleplayExitExit => 'Beenden';

  @override
  String get roleplayAutoHint => 'Auto-Tipp';

  @override
  String get roleplayHintLabel => 'Tipp';

  @override
  String get roleplayHintShowAnswer => 'Englischen Antwortvorschlag ansehen';

  @override
  String get roleplayVoiceSpeed => 'Sprechtempo';

  @override
  String get roleplayEndedFailed => 'Mission fehlgeschlagen ...';

  @override
  String get roleplayEndedComplete => 'Rollenspiel abgeschlossen';

  @override
  String get roleplayEndedEnding => 'Weiter zum Ende ...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Nicht genug Fortschritt';

  @override
  String get roleplayFinishCompleted => 'Rollenspiel abgeschlossen';

  @override
  String get roleplayFinishMovingToEnding => 'Weiter zum Ende ...';

  @override
  String get roleplayAnalyzing => 'Dein Rollenspiel wird analysiert ...';

  @override
  String get roleplayOpeningAiCharacter => 'KI-Charakter';

  @override
  String get roleplayOpeningScenario => 'Szenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'KI kann Fehler machen.\nTeile keine persönlichen oder sensiblen Informationen.';

  @override
  String get endingFailTitle => 'Du hast nicht alle Missionen abgeschlossen!';

  @override
  String get endingFailSubtitle =>
      'Versuche es erneut und entdecke die ganze Geschichte.';

  @override
  String get roleplayTryAgainMessage =>
      'Leider war deine Punktzahl nicht hoch genug für die Belohnung.';

  @override
  String get endingReport => 'Problem melden';

  @override
  String get endingHowWas => 'Wie war das Rollenspiel?';

  @override
  String get endingNext => 'Weiter';

  @override
  String get reportTitle => 'Problem melden';

  @override
  String get profileHistory => 'Verlauf';

  @override
  String get profileSaved => 'Gespeichert';

  @override
  String get profileHistoryEmpty => 'Noch kein Verlauf';

  @override
  String get profileSavedEmpty => 'Noch keine Ausdrücke gespeichert.';

  @override
  String get profileSavedRemoveTitle => 'Gespeicherten Ausdruck entfernen?';

  @override
  String get profileSavedRemoveContent =>
      'Du findest ihn später wieder im Verlauf.';

  @override
  String get profileSavedRemoveOk => 'Entfernen';

  @override
  String get profileSavedRemoveCancel => 'Weiter üben';

  @override
  String get seriesOverviewTabEpisodes => 'Folgen';

  @override
  String get seriesOverviewTabSimilarTopic => 'Ähnliches Thema';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Folge #$number';
  }

  @override
  String get seriesOverviewPlay => 'Starten';

  @override
  String get seriesOverviewLocked => 'Gesperrt';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Schließe zum Freischalten zuerst die vorherige Folge ab.';

  @override
  String get notificationPermissionBlockedTitle =>
      'Benachrichtigungen sind aus';

  @override
  String get notificationPermissionBlockedMessage =>
      'Aktiviere Benachrichtigungen in den Geräteeinstellungen, um Push-Benachrichtigungen zu erhalten.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Noch keine Benachrichtigungen';

  @override
  String get notificationSendToday => 'Heute';

  @override
  String get notificationSendOneDayAgo => 'Vor 1 Tag';

  @override
  String notificationSendDaysAgo(int count) {
    return 'Vor $count Tagen';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Du kannst dich erst 2 Tage nach dem Löschen deines Kontos erneut registrieren. Bitte versuche es später noch einmal.';

  @override
  String get expressionSavedToProfile => 'Im Profil gespeichert';

  @override
  String get expressionUnsavedToProfile => 'Nicht mehr gespeichert';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Diesmal konnten wir kein Feedback geben. Antworte mit mindestens 7 Wörtern!';

  @override
  String get roleplayResultScoreMeaning => 'Bedeutung';

  @override
  String get roleplayResultScoreRelevance => 'Relevanz';

  @override
  String get roleplayResultScoreVocabulary => 'Wortschatz';

  @override
  String get roleplayResultScoreGrammar => 'Grammatik';

  @override
  String get closePopup => 'Schließen';

  @override
  String get reviewChatTapHint =>
      'Tippe auf die Sprechblase, um das Audio abzuspielen.';

  @override
  String get reviewChatNoAudioToPlay => 'Kein Audio zum Abspielen.';

  @override
  String get seriesInformationTopicDifficulty => 'Schwierigkeitsgrad';

  @override
  String get seriesInformationLearningGoals => 'Lernziele';

  @override
  String get energyInfoTitle => 'Energie';

  @override
  String get energyOutOfEnergyTitle => 'Keine Energie mehr';

  @override
  String get energyInfoRechargeUntil => 'Nächste Aufladung in @@TIME@@';

  @override
  String get energyInfoFull => 'Deine Energie ist voll.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Unbegrenzter Modus aktiv';

  @override
  String get energyInsufficient => 'Du hast nicht genug Energie.';

  @override
  String get endRoleplay => 'Rollenspiel beenden';

  @override
  String get energyEnablePushTitle => 'Benachrichtigungen aktivieren';

  @override
  String get energyEnablePushSubtitle =>
      'Aktiviere Benachrichtigungen und fülle deine Energie vollständig auf.';

  @override
  String get energyEnablePushPrice => 'Kostenlos';

  @override
  String get energyEnablePushOfferBadge => 'EINMALIGES ANGEBOT';

  @override
  String get energyEnablePushCompleted => 'Energie vollständig aufgeladen!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Unbegrenzter Pass';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Startet direkt nach dem Kauf und gilt 10 Minuten.';

  @override
  String get energyPurchaseCapacityTitle => 'Maximale Energie erhöhen';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Erhöhe deine maximal aufladbare Energie dauerhaft um 1.';

  @override
  String get energyGoPremiumTitle => 'Premium sichern';

  @override
  String get energyGoPremiumExplore => 'Entdecken';

  @override
  String get profileGoPremiumTitle => 'SUDA Premium abonnieren';

  @override
  String get profileGoPremiumExplore => 'Entdecken';

  @override
  String get energyPurchasePendingApproval =>
      'Deine Zahlung muss noch genehmigt werden.';

  @override
  String get energyPurchaseNotCompleted =>
      'Der Kauf wurde nicht abgeschlossen.';

  @override
  String get welcomeGiftTitle => 'Dein Willkommensgeschenk ist da!';

  @override
  String get welcomeGiftBenefitLead => 'Spiele 10 Minuten unbegrenzt!';

  @override
  String get welcomeGiftLine2 => 'Premium-Funktionen freigeschaltet';

  @override
  String get welcomeGiftLine3 => 'Unbegrenztes Spielen freigeschaltet';

  @override
  String get welcomeGiftStartNow => 'Jetzt starten';

  @override
  String get paywallHeroTitle1 => 'Mehr üben';

  @override
  String get paywallHeroTitle2 => 'Schneller besser werden';

  @override
  String get paywallHeroBody =>
      'Übe länger mit Premium und sprich dank KI-Feedback sicherer Englisch.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Täglich mehr üben';

  @override
  String get paywallBenefitMaxEnergy => 'Maximale Energie: 30';

  @override
  String get paywallBenefitAiFeedback => 'KI-Satzfeedback';

  @override
  String get paywallChoosePlan => 'Wähle deinen Tarif';

  @override
  String get paywallAnnualPlanTitle => 'Jahresabo';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Spare über 33 % gegenüber dem Monatsabo.';

  @override
  String get paywallMonthlyPlanTitle => 'Monatsabo';

  @override
  String get paywallMonthlyPlanSubtitle => 'Flexibel Monat für Monat.';

  @override
  String get paywallBestBadge => 'TOP';

  @override
  String get paywallCta => 'Jetzt abonnieren';

  @override
  String get paywallAutoRenewNotice =>
      'Abonnements verlängern sich automatisch, sofern sie nicht mindestens 24 Stunden vor Ende des aktuellen Abrechnungszeitraums gekündigt werden.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/Monat';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/Jahr';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Glückwunsch!';

  @override
  String get paywallCompletedBody => 'Deine Premium-Vorteile sind jetzt aktiv.';

  @override
  String get paywallCompletedContinue => 'Weiter';

  @override
  String get roleplayChooseYourRole => 'Wähle deine Rolle';

  @override
  String get roleplaySimilarRoleplays => 'Ähnliche Rollenspiele';

  @override
  String get roleplayBeingPrepared =>
      'Dieses Rollenspiel wird gerade vorbereitet.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Schließe alle Enden der vorherigen Rolle ab, um diese Rolle freizuschalten.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% abgeschlossen';
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
