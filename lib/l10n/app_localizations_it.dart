// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get agreementHeading =>
      'Per continuare, leggi e accetta i termini qui sotto.';

  @override
  String get agreementTermsLabel => 'Accetto i Termini di utilizzo.';

  @override
  String get agreementPrivacyLabel => 'Accetto l\'Informativa sulla privacy.';

  @override
  String get agreementTermsTitle => 'Termini di utilizzo';

  @override
  String get agreementPrivacyTitle => 'Informativa sulla privacy';

  @override
  String get agreementDetailsLink => 'Vedi dettagli';

  @override
  String get agreementButtonConfirm => 'Accetta e continua';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsRestorePurchases => 'Ripristina acquisti';

  @override
  String get restorePurchasesNothing => 'Nessun acquisto da ripristinare.';

  @override
  String get restorePurchasesCompleted => 'Acquisti ripristinati.';

  @override
  String get settingsNotification => 'Notifiche';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Livello di inglese';

  @override
  String get pushNotifications => 'Notifiche push';

  @override
  String get pushNotificationsDesc =>
      'Ricevi promemoria e aggiornamenti importanti.';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsAnnouncements => 'Avvisi';

  @override
  String get announcementsEmpty => 'Nessun avviso per ora';

  @override
  String get noticesEmpty => 'Nessun post per ora';

  @override
  String get deletedPost => 'Questo post è stato eliminato.';

  @override
  String get postNoLongerAvailable => 'Questo post non è più disponibile.';

  @override
  String get backToHome => 'Torna alla home';

  @override
  String get settingsSignOut => 'Esci';

  @override
  String get settingsFsdLaboratory => 'Laboratorio FSD';

  @override
  String get settingsPrivacy => 'Informativa sulla privacy';

  @override
  String get settingsTerms => 'Termini di servizio';

  @override
  String get settingsOpenSource => 'Licenze open source';

  @override
  String loginWelcome(String name) {
    return 'Ciao, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Continuando, accetti i $terms e l\'$privacy.';
  }

  @override
  String get loginTermsTitle => 'Termini di utilizzo';

  @override
  String get loginPrivacyTitle => 'Informativa sulla privacy';

  @override
  String get loginCatchphrase => 'Inizia a parlare. È così che impari.';

  @override
  String get loginWelcomeTitle => 'Ti diamo il benvenuto su SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Entra nella storia e inizia a parlare inglese!';

  @override
  String get loginErrorIdToken =>
      'Impossibile ottenere il token ID di Google. Riprova.';

  @override
  String loginErrorFailed(String error) {
    return 'Accesso non riuscito: $error';
  }

  @override
  String get accountName => 'Nome';

  @override
  String get accountInfo => 'Account';

  @override
  String get accountDelete => 'Elimina account';

  @override
  String get accountDeleteTitle => 'Eliminare l\'account?';

  @override
  String get accountDeleteConfirmText =>
      'Tutti i progressi e i dati andranno persi definitivamente. Vuoi continuare?';

  @override
  String get accountDeleteProfileImageTitle =>
      'Eliminare l\'immagine del profilo?';

  @override
  String get accountDeleteProfileImageContent =>
      'Una volta eliminata, l\'immagine del profilo non potrà essere recuperata.';

  @override
  String get accountGoBack => 'Indietro';

  @override
  String get accountDeleteAction => 'Elimina';

  @override
  String get accountSubscription => 'Abbonamento';

  @override
  String get accountFreePlanTitle => 'Piano gratuito';

  @override
  String get accountFreePlanSubtitle =>
      'Passa a Premium per sbloccare più funzioni';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Vantaggi Premium attivi';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Rinnovo il $date';
  }

  @override
  String get accountChangePlan => 'Cambia piano';

  @override
  String get changePlanTitle => 'Cambia piano';

  @override
  String get changePlanCurrentPlan => 'Piano attuale';

  @override
  String get changePlanAvailablePlans => 'Piani disponibili';

  @override
  String changePlanRenewsOn(String date) {
    return 'Rinnovo il $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Impossibile caricare le informazioni. Riprova.';

  @override
  String get changePlanRetry => 'Riprova';

  @override
  String get changePlanConfirmTitle => 'Cambiare piano?';

  @override
  String get changePlanConfirmBody =>
      'Il cambio di piano avrà effetto alla prossima data di fatturazione.';

  @override
  String get changePlanConfirmOk => 'Conferma';

  @override
  String get changePlanConfirmCancel => 'Mantieni piano attuale';

  @override
  String get changePlanOldPurchaseMissing =>
      'Non è stato trovato un abbonamento attivo da modificare. Riprova quando l\'abbonamento sarà attivo.';

  @override
  String get changePlanChangeRequested =>
      'Cambio di piano richiesto. Potrebbe essere applicato alla prossima data di fatturazione.';

  @override
  String get cefrLevelTitle => 'Scegli il tuo livello di inglese';

  @override
  String get cefrLevelAbsoluteBeginner => 'Principiante assoluto';

  @override
  String get cefrLevelBeginner => 'Principiante';

  @override
  String get cefrLevelBasic => 'Base';

  @override
  String get cefrLevelIntermediate => 'Intermedio';

  @override
  String get firstCefrLevelTitle => 'Qual è il tuo livello di inglese?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'So leggere in inglese';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Conosco i saluti di base e alcune frasi semplici';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'So usare e capire frasi brevi e semplici';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'So esprimere la mia opinione e partecipare alle conversazioni quotidiane';

  @override
  String get firstCefrLevelSettingsHint => 'Puoi cambiarlo quando vuoi';

  @override
  String get firstCefrLevelConfirm => 'Conferma';

  @override
  String get feedbackPlaceholder =>
      'Condividi pensieri, suggerimenti o problemi riscontrati...';

  @override
  String get feedbackSend => 'Invia';

  @override
  String get feedbackSuccess => 'Grazie per il feedback.';

  @override
  String get microphonePermissionDenied =>
      'Non puoi iniziare senza autorizzare l\'accesso al microfono.';

  @override
  String get holdMicrophoneToSpeak =>
      'Tieni premuto il pulsante del microfono per parlare';

  @override
  String get roleplayTypeMessagePlaceholder => 'Scrivi il tuo messaggio...';

  @override
  String get yourTurnFirst => 'Comincia tu!';

  @override
  String get sayLineBelowToStart =>
      'Pronuncia la frase qui sotto per iniziare.';

  @override
  String get roleplayExitWait => 'Un attimo!';

  @override
  String get roleplayExitMessage =>
      'Se esci ora, perderai la ricompensa. Vuoi davvero uscire?';

  @override
  String get roleplayExitKeepPlaying => 'Continua';

  @override
  String get roleplayExitExit => 'Esci';

  @override
  String get roleplayAutoHint => 'Suggerimento automatico';

  @override
  String get roleplayHintLabel => 'Suggerimento';

  @override
  String get roleplayHintShowAnswer =>
      'Tocca per vedere la risposta suggerita in inglese';

  @override
  String get roleplayVoiceSpeed => 'Velocità della voce';

  @override
  String get roleplayEndedFailed => 'Missione fallita...';

  @override
  String get roleplayEndedComplete => 'Roleplay completato';

  @override
  String get roleplayEndedEnding => 'Passaggio al finale...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Progressi insufficienti';

  @override
  String get roleplayFinishCompleted => 'Roleplay completato';

  @override
  String get roleplayFinishMovingToEnding => 'Passaggio al finale...';

  @override
  String get roleplayAnalyzing => 'Analisi del roleplay...';

  @override
  String get roleplayOpeningAiCharacter => 'Personaggio IA';

  @override
  String get roleplayOpeningScenario => 'Scenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'L\'IA può commettere errori.\nNon condividere informazioni personali o sensibili.';

  @override
  String get endingFailTitle => 'Non hai completato tutte le missioni!';

  @override
  String get endingFailSubtitle => 'Riprova e scopri la storia completa.';

  @override
  String get roleplayTryAgainMessage =>
      'Purtroppo, il punteggio non è sufficiente per ottenere la ricompensa.';

  @override
  String get endingReport => 'Segnala un problema';

  @override
  String get endingHowWas => 'Com\'è andato il roleplay?';

  @override
  String get endingNext => 'Avanti';

  @override
  String get reportTitle => 'Segnala un problema';

  @override
  String get profileHistory => 'Cronologia';

  @override
  String get profileSaved => 'Salvate';

  @override
  String get profileHistoryEmpty => 'Cronologia ancora vuota';

  @override
  String get profileSavedEmpty => 'Nessuna espressione salvata.';

  @override
  String get profileSavedRemoveTitle => 'Non salvare più questa espressione?';

  @override
  String get profileSavedRemoveContent => 'Potrai ritrovarla nella cronologia.';

  @override
  String get profileSavedRemoveOk => 'Rimuovi';

  @override
  String get profileSavedRemoveCancel => 'Esercitati ancora';

  @override
  String get seriesOverviewTabEpisodes => 'Episodi';

  @override
  String get seriesOverviewTabSimilarTopic => 'Argomenti simili';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episodio #$number';
  }

  @override
  String get seriesOverviewPlay => 'Gioca';

  @override
  String get seriesOverviewLocked => 'Bloccato';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Completa l\'episodio precedente per sbloccarlo.';

  @override
  String get notificationPermissionBlockedTitle =>
      'Le notifiche sono disattivate';

  @override
  String get notificationPermissionBlockedMessage =>
      'Attiva le notifiche nelle impostazioni del dispositivo per ricevere notifiche push.';

  @override
  String get openSettings => 'Apri le impostazioni';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsEmpty => 'Nessuna notifica per ora';

  @override
  String get notificationSendToday => 'Oggi';

  @override
  String get notificationSendOneDayAgo => '1 giorno fa';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count giorni fa';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Puoi registrarti di nuovo 2 giorni dopo aver eliminato l\'account. Riprova più tardi.';

  @override
  String get expressionSavedToProfile => 'Salvata nel profilo';

  @override
  String get expressionUnsavedToProfile => 'Non è più salvata';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Questa volta non siamo riusciti a darti un feedback. Prova a rispondere con almeno 7 parole!';

  @override
  String get roleplayResultScoreMeaning => 'Significato';

  @override
  String get roleplayResultScoreRelevance => 'Pertinenza';

  @override
  String get roleplayResultScoreVocabulary => 'Vocabolario';

  @override
  String get roleplayResultScoreGrammar => 'Grammatica';

  @override
  String get closePopup => 'Chiudi';

  @override
  String get reviewChatTapHint =>
      'Tocca il fumetto della chat per riprodurre l\'audio.';

  @override
  String get reviewChatNoAudioToPlay => 'Nessun audio da riprodurre.';

  @override
  String get seriesInformationTopicDifficulty => 'Difficoltà dell\'argomento';

  @override
  String get seriesInformationLearningGoals => 'Obiettivi di apprendimento';

  @override
  String get energyInfoTitle => 'Energia';

  @override
  String get energyOutOfEnergyTitle => 'Energia esaurita';

  @override
  String get energyInfoRechargeUntil => 'Prossima ricarica tra @@TIME@@';

  @override
  String get energyInfoFull => 'La tua energia è al massimo.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Modalità illimitata attiva';

  @override
  String get energyInsufficient => 'Non hai abbastanza energia.';

  @override
  String get endRoleplay => 'Termina il roleplay';

  @override
  String get energyEnablePushTitle => 'Attiva le notifiche';

  @override
  String get energyEnablePushSubtitle =>
      'Attiva le notifiche e ricarica tutta l\'energia.';

  @override
  String get energyEnablePushPrice => 'Gratis';

  @override
  String get energyEnablePushOfferBadge => 'OFFERTA UNA TANTUM';

  @override
  String get energyEnablePushCompleted => 'Energia ricaricata!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Pass illimitato';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Si attiva subito dopo l\'acquisto ed è valido per 10 minuti.';

  @override
  String get energyPurchaseCapacityTitle => 'Potenzia l\'energia massima';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Aumenta per sempre di 1 la tua energia massima ricaricabile.';

  @override
  String get energyGoPremiumTitle => 'Passa a Premium';

  @override
  String get energyGoPremiumExplore => 'Scopri';

  @override
  String get profileGoPremiumTitle => 'Passa a SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Scopri';

  @override
  String get energyPurchasePendingApproval =>
      'Pagamento in attesa di approvazione';

  @override
  String get energyPurchaseNotCompleted =>
      'L\'acquisto non è stato completato.';

  @override
  String get iapPurchaseProcessing => 'Il tuo acquisto è in elaborazione.';

  @override
  String get iapPurchaseCompleted => 'Acquisto completato.';

  @override
  String get welcomeGiftTitle => 'Il tuo regalo di benvenuto è arrivato!';

  @override
  String get welcomeGiftBenefitLead => 'Gioca senza limiti per 10 minuti!';

  @override
  String get welcomeGiftLine2 => 'Funzioni Premium sbloccate';

  @override
  String get welcomeGiftLine3 => 'Modalità illimitata sbloccata';

  @override
  String get welcomeGiftStartNow => 'Inizia ora';

  @override
  String get paywallHeroTitle1 => 'Esercitati di più';

  @override
  String get paywallHeroTitle2 => 'Migliora più in fretta';

  @override
  String get paywallHeroBody =>
      'Esercitati più a lungo con Premium e ricevi feedback dall\'IA per parlare inglese con più sicurezza.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Più pratica ogni giorno';

  @override
  String get paywallBenefitMaxEnergy => 'Fino a 30 punti di energia';

  @override
  String get paywallBenefitAiFeedback => 'Feedback dell\'IA sulle tue frasi';

  @override
  String get paywallChoosePlan => 'Scegli il piano';

  @override
  String get paywallAnnualPlanTitle => 'Piano annuale';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Risparmia oltre il 33% rispetto al piano mensile.';

  @override
  String get paywallMonthlyPlanTitle => 'Piano mensile';

  @override
  String get paywallMonthlyPlanSubtitle => 'Accesso mensile flessibile.';

  @override
  String get paywallBestBadge => 'MIGLIORE';

  @override
  String get paywallCta => 'Inizia ora';

  @override
  String get paywallAutoRenewNotice =>
      'L\'abbonamento si rinnova automaticamente, a meno che non venga annullato almeno 24 ore prima della fine del periodo di fatturazione in corso.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/mese';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/anno';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '8,75 €';

  @override
  String get paywallFallbackAnnual => '104,99 €';

  @override
  String get paywallFallbackMonthly => '14,99 €';

  @override
  String get paywallFallbackMonthlyTimes12 => '179,88 €';

  @override
  String get paywallCompletedTitle => 'Congratulazioni!';

  @override
  String get paywallCompletedBody => 'I vantaggi Premium sono ora attivi.';

  @override
  String get paywallCompletedContinue => 'Continua';

  @override
  String get roleplayChooseYourRole => 'Scegli il tuo ruolo';

  @override
  String get roleplaySimilarRoleplays => 'Roleplay simili';

  @override
  String get roleplayBeingPrepared => 'Questo roleplay è in preparazione.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Completa tutti i finali del ruolo precedente per sbloccare questo ruolo.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% completato';
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
      'Controlla la tua **Missione**\ne inizia la conversazione.';

  @override
  String get tutorialPage1Tip =>
      '*Suggerimento: Più parli in modo naturale,\npiù grande sarà la ricompensa!';

  @override
  String get tutorialPage2Title => 'Usa il **Traduttore**\nquando non capisci.';

  @override
  String get tutorialPage3Title =>
      'Usa un **Suggerimento**\nquando ti blocchi.';

  @override
  String get tutorialPage3Subtitle =>
      'Puoi attivare o disattivare\ni suggerimenti automatici quando vuoi.';

  @override
  String get tutorialPage4Title =>
      'Se la pronuncia è difficile,\nascolta prima e poi ripeti.';

  @override
  String get tutorialPage4Tip =>
      '*Suggerimento: Prova a rispondere senza guardare\nla traduzione per ottenere un punteggio più alto.';

  @override
  String get tutorialPage5Title => 'Non puoi parlare\nad alta voce?';

  @override
  String get tutorialPage5Subtitle => 'Passa alla **Modalità testo**.';

  @override
  String get tutorialPage6Title =>
      'Nessuno ti sta giudicando.\nCe la puoi fare!';
}
