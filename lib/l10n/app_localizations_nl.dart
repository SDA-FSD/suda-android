// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get agreementHeading =>
      'Lees en accepteer de onderstaande voorwaarden om door te gaan.';

  @override
  String get agreementTermsLabel => 'Ik ga akkoord met de gebruiksvoorwaarden.';

  @override
  String get agreementPrivacyLabel => 'Ik ga akkoord met het privacybeleid.';

  @override
  String get agreementTermsTitle => 'Gebruiksvoorwaarden';

  @override
  String get agreementPrivacyTitle => 'Privacybeleid';

  @override
  String get agreementDetailsLink => 'Details bekijken';

  @override
  String get agreementButtonConfirm => 'Akkoord en doorgaan';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsRestorePurchases => 'Aankopen herstellen';

  @override
  String get restorePurchasesNothing =>
      'Er zijn geen aankopen om te herstellen.';

  @override
  String get restorePurchasesCompleted => 'Aankopen hersteld.';

  @override
  String get settingsNotification => 'Meldingen';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Engelsniveau';

  @override
  String get pushNotifications => 'Pushmeldingen';

  @override
  String get pushNotificationsDesc =>
      'Ontvang herinneringen en belangrijke updates.';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsAnnouncements => 'Mededelingen';

  @override
  String get announcementsEmpty => 'Nog geen mededelingen';

  @override
  String get noticesEmpty => 'Nog geen berichten';

  @override
  String get deletedPost => 'Dit bericht is verwijderd.';

  @override
  String get postNoLongerAvailable => 'Dit bericht is niet meer beschikbaar.';

  @override
  String get backToHome => 'Terug naar home';

  @override
  String get settingsSignOut => 'Uitloggen';

  @override
  String get settingsFsdLaboratory => 'FSD-laboratorium';

  @override
  String get settingsPrivacy => 'Privacybeleid';

  @override
  String get settingsTerms => 'Gebruiksvoorwaarden';

  @override
  String get settingsOpenSource => 'Opensourcelicenties';

  @override
  String loginWelcome(String name) {
    return 'Welkom, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Door verder te gaan, ga je akkoord met onze $terms en ons $privacy.';
  }

  @override
  String get loginTermsTitle => 'Gebruiksvoorwaarden';

  @override
  String get loginPrivacyTitle => 'Privacybeleid';

  @override
  String get loginCatchphrase => 'Begin te praten. Zo leer je.';

  @override
  String get loginWelcomeTitle => 'Welkom bij SUDA!';

  @override
  String get loginWelcomeSubtitle => 'Stap in een verhaal en spreek Engels!';

  @override
  String get loginErrorIdToken =>
      'Google-ID-token ophalen mislukt. Probeer het opnieuw.';

  @override
  String loginErrorFailed(String error) {
    return 'Inloggen mislukt: $error';
  }

  @override
  String get accountName => 'Naam';

  @override
  String get accountInfo => 'Account';

  @override
  String get accountDelete => 'Account verwijderen';

  @override
  String get accountDeleteTitle => 'Account verwijderen?';

  @override
  String get accountDeleteConfirmText =>
      'Al je voortgang en gegevens gaan permanent verloren. Weet je het zeker?';

  @override
  String get accountDeleteProfileImageTitle => 'Profielfoto verwijderen?';

  @override
  String get accountDeleteProfileImageContent =>
      'Na verwijdering kan je profielfoto niet worden hersteld.';

  @override
  String get accountGoBack => 'Terug';

  @override
  String get accountDeleteAction => 'Verwijderen';

  @override
  String get accountSubscription => 'Abonnement';

  @override
  String get accountFreePlanTitle => 'Gratis abonnement';

  @override
  String get accountFreePlanSubtitle => 'Neem Premium voor meer functies';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Je Premium-voordelen zijn actief';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Wordt verlengd op $date';
  }

  @override
  String get accountChangePlan => 'Abonnement wijzigen';

  @override
  String get changePlanTitle => 'Abonnement wijzigen';

  @override
  String get changePlanCurrentPlan => 'Huidig abonnement';

  @override
  String get changePlanAvailablePlans => 'Beschikbare abonnementen';

  @override
  String changePlanRenewsOn(String date) {
    return 'Wordt verlengd op $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Kan de informatie niet laden. Probeer het opnieuw.';

  @override
  String get changePlanRetry => 'Opnieuw proberen';

  @override
  String get changePlanConfirmTitle => 'Abonnement wijzigen?';

  @override
  String get changePlanConfirmBody =>
      'De wijziging gaat in op je volgende betaaldatum.';

  @override
  String get changePlanConfirmOk => 'Bevestigen';

  @override
  String get changePlanConfirmCancel => 'Huidig abonnement houden';

  @override
  String get changePlanOldPurchaseMissing =>
      'Geen actief abonnement gevonden om te wijzigen. Probeer het opnieuw zodra je abonnement actief is.';

  @override
  String get changePlanChangeRequested =>
      'Wijziging aangevraagd. Deze kan ingaan op je volgende betaaldatum.';

  @override
  String get cefrLevelTitle => 'Kies je Engelsniveau';

  @override
  String get cefrLevelAbsoluteBeginner => 'Absolute beginner';

  @override
  String get cefrLevelBeginner => 'Beginner';

  @override
  String get cefrLevelBasic => 'Basis';

  @override
  String get cefrLevelIntermediate => 'Halfgevorderd';

  @override
  String get firstCefrLevelTitle => 'Wat is je Engelsniveau?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Ik kan Engels lezen';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Ik ken basisbegroetingen en eenvoudige uitdrukkingen';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Ik kan korte, eenvoudige zinnen gebruiken en begrijpen';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Ik kan mijn mening geven en alledaagse gesprekken voeren';

  @override
  String get firstCefrLevelSettingsHint => 'Je kunt dit altijd wijzigen';

  @override
  String get firstCefrLevelConfirm => 'Bevestigen';

  @override
  String get feedbackPlaceholder =>
      'Deel je mening, suggesties of problemen...';

  @override
  String get feedbackSend => 'Versturen';

  @override
  String get feedbackSuccess => 'Bedankt voor je feedback.';

  @override
  String get microphonePermissionDenied =>
      'Je kunt niet starten zonder toegang tot de microfoon.';

  @override
  String get holdMicrophoneToSpeak =>
      'Houd de microfoon ingedrukt om te praten';

  @override
  String get roleplayTypeMessagePlaceholder => 'Typ je bericht...';

  @override
  String get yourTurnFirst => 'Jij mag beginnen!';

  @override
  String get sayLineBelowToStart => 'Zeg de zin hieronder om te beginnen.';

  @override
  String get roleplayExitWait => 'Wacht!';

  @override
  String get roleplayExitMessage =>
      'Als je nu stopt, loop je je beloning mis. Weet je zeker dat je wilt stoppen?';

  @override
  String get roleplayExitKeepPlaying => 'Doorgaan';

  @override
  String get roleplayExitExit => 'Stoppen';

  @override
  String get roleplayAutoHint => 'Automatische hint';

  @override
  String get roleplayHintLabel => 'Hint';

  @override
  String get roleplayHintShowAnswer => 'Engels voorbeeldantwoord bekijken';

  @override
  String get roleplayVoiceSpeed => 'Spreeksnelheid';

  @override
  String get roleplayEndedFailed => 'Missie mislukt...';

  @override
  String get roleplayEndedComplete => 'Rollenspel voltooid';

  @override
  String get roleplayEndedEnding => 'Naar het einde...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Onvoldoende voortgang';

  @override
  String get roleplayFinishCompleted => 'Rollenspel voltooid';

  @override
  String get roleplayFinishMovingToEnding => 'Naar het einde...';

  @override
  String get roleplayAnalyzing => 'Je rollenspel wordt geanalyseerd...';

  @override
  String get roleplayOpeningAiCharacter => 'AI-personage';

  @override
  String get roleplayOpeningScenario => 'Scenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI kan fouten maken.\nDeel geen persoonlijke of gevoelige informatie.';

  @override
  String get endingFailTitle => 'Je hebt niet alle missies voltooid!';

  @override
  String get endingFailSubtitle =>
      'Probeer het opnieuw en ontdek het hele verhaal.';

  @override
  String get roleplayTryAgainMessage =>
      'Helaas was je score niet hoog genoeg voor de beloning.';

  @override
  String get endingReport => 'Probleem melden';

  @override
  String get endingHowWas => 'Hoe vond je het rollenspel?';

  @override
  String get endingNext => 'Volgende';

  @override
  String get reportTitle => 'Probleem melden';

  @override
  String get profileHistory => 'Geschiedenis';

  @override
  String get profileSaved => 'Opgeslagen';

  @override
  String get profileHistoryEmpty => 'Nog geen geschiedenis';

  @override
  String get profileSavedEmpty => 'Nog geen opgeslagen uitdrukkingen.';

  @override
  String get profileSavedRemoveTitle => 'Niet meer opslaan?';

  @override
  String get profileSavedRemoveContent =>
      'Je vindt dit later terug in Geschiedenis.';

  @override
  String get profileSavedRemoveOk => 'Verwijderen';

  @override
  String get profileSavedRemoveCancel => 'Verder oefenen';

  @override
  String get seriesOverviewTabEpisodes => 'Aflevering';

  @override
  String get seriesOverviewTabSimilarTopic => 'Soortgelijk onderwerp';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Aflevering #$number';
  }

  @override
  String get seriesOverviewPlay => 'Spelen';

  @override
  String get seriesOverviewLocked => 'Vergrendeld';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Voltooi eerst de vorige aflevering.';

  @override
  String get notificationPermissionBlockedTitle => 'Meldingen staan uit';

  @override
  String get notificationPermissionBlockedMessage =>
      'Schakel meldingen in via de apparaatinstellingen om pushmeldingen te ontvangen.';

  @override
  String get openSettings => 'Instellingen openen';

  @override
  String get notificationsTitle => 'Meldingen';

  @override
  String get notificationsEmpty => 'Nog geen meldingen';

  @override
  String get notificationSendToday => 'Vandaag';

  @override
  String get notificationSendOneDayAgo => '1 dag geleden';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count dagen geleden';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Je kunt je pas 2 dagen na het verwijderen van je account opnieuw registreren. Probeer het later opnieuw.';

  @override
  String get expressionSavedToProfile => 'Opgeslagen in je profiel';

  @override
  String get expressionUnsavedToProfile => 'Niet meer opgeslagen';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Deze keer konden we geen feedback geven. Breid je antwoord uit tot minimaal 7 woorden!';

  @override
  String get roleplayResultScoreMeaning => 'Betekenis';

  @override
  String get roleplayResultScoreRelevance => 'Relevantie';

  @override
  String get roleplayResultScoreVocabulary => 'Woordenschat';

  @override
  String get roleplayResultScoreGrammar => 'Grammatica';

  @override
  String get closePopup => 'Sluiten';

  @override
  String get reviewChatTapHint =>
      'Tik op de chatballon om de audio af te spelen.';

  @override
  String get reviewChatNoAudioToPlay => 'Er is geen audio om af te spelen.';

  @override
  String get seriesInformationTopicDifficulty => 'Moeilijkheidsgraad';

  @override
  String get seriesInformationLearningGoals => 'Leerdoelen';

  @override
  String get energyInfoTitle => 'Energie';

  @override
  String get energyOutOfEnergyTitle => 'Energie op';

  @override
  String get energyInfoRechargeUntil => 'Volgende aanvulling over @@TIME@@';

  @override
  String get energyInfoFull => 'Je energie is vol.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Onbeperkte modus actief';

  @override
  String get energyInsufficient => 'Je hebt niet genoeg energie.';

  @override
  String get endRoleplay => 'Rollenspel beëindigen';

  @override
  String get energyEnablePushTitle => 'Meldingen inschakelen';

  @override
  String get energyEnablePushSubtitle =>
      'Zet meldingen aan en vul je energie helemaal aan.';

  @override
  String get energyEnablePushPrice => 'Gratis';

  @override
  String get energyEnablePushOfferBadge => 'EENMALIGE AANBIEDING';

  @override
  String get energyEnablePushCompleted => 'Energie aangevuld!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Onbeperkte speelpas';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Start direct na aankoop. 10 minuten geldig.';

  @override
  String get energyPurchaseCapacityTitle => 'Energielimiet verhogen';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Verhoog je maximale energie permanent met 1.';

  @override
  String get energyGoPremiumTitle => 'Neem Premium';

  @override
  String get energyGoPremiumExplore => 'Ontdekken';

  @override
  String get profileGoPremiumTitle => 'Neem SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Ontdekken';

  @override
  String get energyPurchasePendingApproval =>
      'Je betaling moet nog worden goedgekeurd';

  @override
  String get energyPurchaseNotCompleted => 'De aankoop is niet voltooid.';

  @override
  String get welcomeGiftTitle => 'Je welkomstcadeau is er!';

  @override
  String get welcomeGiftBenefitLead => 'Speel 10 minuten onbeperkt!';

  @override
  String get welcomeGiftLine2 => 'Premium-functies ontgrendeld';

  @override
  String get welcomeGiftLine3 => 'Onbeperkt spelen ontgrendeld';

  @override
  String get welcomeGiftStartNow => 'Nu starten';

  @override
  String get paywallHeroTitle1 => 'Oefen meer';

  @override
  String get paywallHeroTitle2 => 'Ga sneller vooruit';

  @override
  String get paywallHeroBody =>
      'Oefen langer met Premium en krijg AI-feedback om zelfverzekerder Engels te spreken.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Elke dag meer oefenen';

  @override
  String get paywallBenefitMaxEnergy => 'Maximale energie: 30';

  @override
  String get paywallBenefitAiFeedback => 'AI-feedback op zinnen';

  @override
  String get paywallChoosePlan => 'Kies je abonnement';

  @override
  String get paywallAnnualPlanTitle => 'Jaarabonnement';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Bespaar meer dan 33% ten opzichte van het maandabonnement.';

  @override
  String get paywallMonthlyPlanTitle => 'Maandabonnement';

  @override
  String get paywallMonthlyPlanSubtitle => 'Flexibele toegang per maand.';

  @override
  String get paywallBestBadge => 'BESTE';

  @override
  String get paywallCta => 'Nu abonneren';

  @override
  String get paywallAutoRenewNotice =>
      'Je abonnement wordt automatisch verlengd, tenzij je het minimaal 24 uur vóór het einde van de huidige factureringsperiode opzegt.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/maand';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/jaar';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Gefeliciteerd!';

  @override
  String get paywallCompletedBody => 'Je Premium-voordelen zijn nu actief.';

  @override
  String get paywallCompletedContinue => 'Doorgaan';

  @override
  String get roleplayChooseYourRole => 'Kies je rol';

  @override
  String get roleplaySimilarRoleplays => 'Vergelijkbare rollenspellen';

  @override
  String get roleplayBeingPrepared => 'Dit rollenspel wordt nog voorbereid.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Rond alle eindes van de vorige rol af om deze rol te ontgrendelen.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% voltooid';
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
