// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get agreementHeading =>
      'Veuillez lire et accepter les conditions ci-dessous pour continuer.';

  @override
  String get agreementTermsLabel => 'J’accepte les conditions d’utilisation.';

  @override
  String get agreementPrivacyLabel =>
      'J’accepte la politique de confidentialité.';

  @override
  String get agreementTermsTitle => 'Conditions d’utilisation';

  @override
  String get agreementPrivacyTitle => 'Politique de confidentialité';

  @override
  String get agreementDetailsLink => 'Voir les détails';

  @override
  String get agreementButtonConfirm => 'Accepter et continuer';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsRestorePurchases => 'Restaurer les achats';

  @override
  String get restorePurchasesNothing => 'Aucun achat à restaurer.';

  @override
  String get restorePurchasesCompleted => 'Achats restaurés.';

  @override
  String get settingsNotification => 'Notifications';

  @override
  String get settingsTutorial => 'Tutoriel';

  @override
  String get settingsCefrLevel => 'Niveau d’anglais';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get pushNotificationsDesc =>
      'Recevez des rappels et des mises à jour importantes.';

  @override
  String get settingsFeedback => 'Votre avis';

  @override
  String get settingsAnnouncements => 'Annonces';

  @override
  String get announcementsEmpty => 'Aucune annonce pour le moment';

  @override
  String get noticesEmpty => 'Aucune publication pour le moment';

  @override
  String get deletedPost => 'Cette publication a été supprimée.';

  @override
  String get postNoLongerAvailable =>
      'Cette publication n’est plus disponible.';

  @override
  String get backToHome => 'Retour à l’accueil';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsFsdLaboratory => 'Laboratoire FSD';

  @override
  String get settingsPrivacy => 'Politique de confidentialité';

  @override
  String get settingsTerms => 'Conditions d’utilisation';

  @override
  String get settingsOpenSource => 'Licences open source';

  @override
  String loginWelcome(String name) {
    return 'Bienvenue, $name !';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'En continuant, vous acceptez nos $terms et notre $privacy.';
  }

  @override
  String get loginTermsTitle => 'Conditions d’utilisation';

  @override
  String get loginPrivacyTitle => 'Politique de confidentialité';

  @override
  String get loginCatchphrase => 'Parlez. C’est ainsi qu’on apprend.';

  @override
  String get loginWelcomeTitle => 'Bienvenue sur SUDA !';

  @override
  String get loginWelcomeSubtitle =>
      'Entrez dans une histoire et parlez anglais !';

  @override
  String get loginErrorIdToken =>
      'Impossible d’obtenir le jeton d’identification Google. Réessayez.';

  @override
  String loginErrorFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get accountName => 'Nom';

  @override
  String get accountInfo => 'Compte';

  @override
  String get accountDelete => 'Supprimer le compte';

  @override
  String get accountDeleteTitle => 'Supprimer le compte ?';

  @override
  String get accountDeleteConfirmText =>
      'Tous vos progrès et vos données seront définitivement perdus. Confirmez-vous la suppression ?';

  @override
  String get accountDeleteProfileImageTitle => 'Supprimer la photo de profil ?';

  @override
  String get accountDeleteProfileImageContent =>
      'Après sa suppression, votre photo de profil sera irrécupérable.';

  @override
  String get accountGoBack => 'Retour';

  @override
  String get accountDeleteAction => 'Supprimer';

  @override
  String get accountSubscription => 'Abonnement';

  @override
  String get accountFreePlanTitle => 'Formule gratuite';

  @override
  String get accountFreePlanSubtitle =>
      'Passez à Premium pour débloquer plus de fonctionnalités';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Vous profitez des avantages Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Renouvellement le $date';
  }

  @override
  String get accountChangePlan => 'Changer de formule';

  @override
  String get changePlanTitle => 'Changer de formule';

  @override
  String get changePlanCurrentPlan => 'Formule actuelle';

  @override
  String get changePlanAvailablePlans => 'Formules disponibles';

  @override
  String changePlanRenewsOn(String date) {
    return 'Renouvellement le $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Impossible de charger les informations. Réessayez.';

  @override
  String get changePlanRetry => 'Réessayer';

  @override
  String get changePlanConfirmTitle => 'Changer de formule ?';

  @override
  String get changePlanConfirmBody =>
      'Le changement de formule prendra effet à votre prochaine date de facturation.';

  @override
  String get changePlanConfirmOk => 'Confirmer';

  @override
  String get changePlanConfirmCancel => 'Conserver la formule actuelle';

  @override
  String get changePlanOldPurchaseMissing =>
      'Impossible de trouver un abonnement actif à modifier. Réessayez une fois votre abonnement activé.';

  @override
  String get changePlanChangeRequested =>
      'Changement de formule demandé. Il pourra prendre effet à votre prochaine date de facturation.';

  @override
  String get cefrLevelTitle => 'Choisissez votre niveau d’anglais';

  @override
  String get cefrLevelAbsoluteBeginner => 'Grand débutant';

  @override
  String get cefrLevelBeginner => 'Débutant';

  @override
  String get cefrLevelBasic => 'Élémentaire';

  @override
  String get cefrLevelIntermediate => 'Intermédiaire';

  @override
  String get firstCefrLevelTitle => 'Quel est votre niveau d’anglais ?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Je sais lire en anglais';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Je connais les salutations de base et des expressions simples';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Je peux utiliser et comprendre des phrases courtes et simples';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Je peux donner mon avis et participer à des conversations du quotidien';

  @override
  String get firstCefrLevelSettingsHint =>
      'Vous pouvez le modifier à tout moment';

  @override
  String get firstProfileImageTitle => 'Choisissez votre photo de profil';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get feedbackPlaceholder =>
      'Partagez vos remarques, suggestions ou problèmes rencontrés…';

  @override
  String get feedbackSend => 'Envoyer';

  @override
  String get feedbackSuccess => 'Merci pour votre retour.';

  @override
  String get microphonePermissionDenied =>
      'Impossible de commencer sans autoriser l’accès au micro.';

  @override
  String get holdMicrophoneToSpeak =>
      'Maintenez le bouton du micro enfoncé pour parler';

  @override
  String get roleplayTypeMessagePlaceholder => 'Saisissez votre message…';

  @override
  String get yourTurnFirst => 'À vous de commencer !';

  @override
  String get sayLineBelowToStart =>
      'Prononcez la phrase ci-dessous pour commencer.';

  @override
  String get roleplayExitWait => 'Un instant !';

  @override
  String get roleplayExitMessage =>
      'Si vous quittez maintenant, vous perdrez votre récompense. Voulez-vous vraiment quitter ?';

  @override
  String get roleplayExitKeepPlaying => 'Continuer à jouer';

  @override
  String get roleplayExitExit => 'Quitter';

  @override
  String get roleplayAutoHint => 'Indice automatique';

  @override
  String get roleplayHintLabel => 'Indice';

  @override
  String get roleplayHintShowAnswer =>
      'Touchez pour voir une réponse suggérée en anglais';

  @override
  String get roleplayVoiceSpeed => 'Vitesse de lecture';

  @override
  String get roleplayEndedFailed => 'Mission échouée…';

  @override
  String get roleplayEndedComplete => 'Jeu de rôle terminé';

  @override
  String get roleplayEndedEnding => 'Chargement de la fin…';

  @override
  String get roleplayFinishNotEnoughProgress => 'Progression insuffisante';

  @override
  String get roleplayFinishCompleted => 'Jeu de rôle terminé';

  @override
  String get roleplayFinishMovingToEnding => 'Chargement de la fin…';

  @override
  String get roleplayAnalyzing => 'Analyse de votre jeu de rôle…';

  @override
  String get roleplayOpeningAiCharacter => 'Personnage IA';

  @override
  String get roleplayOpeningScenario => 'Scénario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'L’IA peut faire des erreurs.\nNe partagez aucune information personnelle ou sensible.';

  @override
  String get endingFailTitle => 'Vous n’avez pas terminé toutes les missions !';

  @override
  String get endingFailSubtitle => 'Réessayez pour découvrir toute l’histoire.';

  @override
  String get roleplayTryAgainMessage =>
      'Votre score n’était malheureusement pas assez élevé pour obtenir la récompense.';

  @override
  String get endingReport => 'Signaler un problème';

  @override
  String get endingHowWas => 'Qu’avez-vous pensé du jeu de rôle ?';

  @override
  String get endingNext => 'Suivant';

  @override
  String get reportTitle => 'Signaler un problème';

  @override
  String get profileProgress => 'Progression';

  @override
  String get profileDayStreak => 'Jours d’affilée';

  @override
  String get profileWordsSpoken => 'Mots prononcés';

  @override
  String get profileSudaNeighbors => 'Voisins SUDA';

  @override
  String get profileSudaNeighborsEmpty =>
      'Ouvrez des Boîtes de Récompense pour collectionner de nouveaux personnages !';

  @override
  String profileLevelProgressReach(int level) {
    return 'Atteignez le Nv. $level pour débloquer !';
  }

  @override
  String get profileLevelProgressReachBody =>
      'Gagnez des Likes et montez de niveau pour récupérer votre Boîte de Récompense.';

  @override
  String get profileLevelProgressGotIt => 'Compris';

  @override
  String get profileAchievements => 'Succès';

  @override
  String get profileAchievementWeeklyChampion => 'Champion de la semaine';

  @override
  String get profileAchievementWeeklyRunnerUp => 'Vice-champion de la semaine';

  @override
  String get profileAchievementWeeklyThird => '3e place de la semaine';

  @override
  String get profileAchievementWeeklyChampionHint =>
      'Terminez 1er du classement hebdomadaire.';

  @override
  String get profileAchievementWeeklyRunnerUpHint =>
      'Terminez 2e du classement hebdomadaire.';

  @override
  String get profileAchievementWeeklyThirdHint =>
      'Terminez 3e du classement hebdomadaire.';

  @override
  String profileAchievementCount(int count) {
    return 'x $count';
  }

  @override
  String get profileHistory => 'Historique';

  @override
  String get profileSaved => 'Enregistrées';

  @override
  String get profileHistoryEmpty => 'Aucun historique pour le moment';

  @override
  String get profileSavedEmpty => 'Aucune expression enregistrée.';

  @override
  String get profileSavedRemoveTitle =>
      'Ne plus enregistrer cette expression ?';

  @override
  String get profileSavedRemoveContent =>
      'Vous pourrez la retrouver plus tard dans l’historique.';

  @override
  String get profileSavedRemoveOk => 'Retirer';

  @override
  String get profileSavedRemoveCancel => 'Continuer à s’entraîner';

  @override
  String get seriesOverviewTabEpisodes => 'Épisodes';

  @override
  String get seriesOverviewTabSimilarTopic => 'Sujets similaires';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Épisode $number';
  }

  @override
  String get seriesOverviewPlay => 'Jouer';

  @override
  String get seriesOverviewLocked => 'Verrouillé';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Terminez l’épisode précédent pour le débloquer.';

  @override
  String get notificationPermissionBlockedTitle => 'Notifications désactivées';

  @override
  String get notificationPermissionBlockedMessage =>
      'Activez les notifications dans les paramètres de votre appareil pour recevoir des notifications push.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Aucune notification pour le moment';

  @override
  String get notificationSendToday => 'Aujourd’hui';

  @override
  String get notificationSendOneDayAgo => 'Il y a 1 jour';

  @override
  String notificationSendDaysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Vous pourrez vous réinscrire 2 jours après la suppression de votre compte. Réessayez plus tard.';

  @override
  String get expressionSavedToProfile => 'Enregistrée dans votre profil';

  @override
  String get expressionUnsavedToProfile => 'N’est plus enregistrée';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Cette fois-ci, nous n’avons pas pu vous faire de retour. Essayez de répondre avec au moins 7 mots !';

  @override
  String get roleplayResultScoreMeaning => 'Sens';

  @override
  String get roleplayResultScoreRelevance => 'Pertinence';

  @override
  String get roleplayResultScoreVocabulary => 'Vocabulaire';

  @override
  String get roleplayResultScoreGrammar => 'Grammaire';

  @override
  String get closePopup => 'Fermer';

  @override
  String get reviewChatTapHint =>
      'Touchez la bulle de discussion pour écouter l’audio.';

  @override
  String get reviewChatNoAudioToPlay => 'Aucun audio à lire.';

  @override
  String get seriesInformationTopicDifficulty => 'Difficulté du sujet';

  @override
  String get seriesInformationLearningGoals => 'Objectifs d’apprentissage';

  @override
  String get energyInfoTitle => 'Énergie';

  @override
  String get energyOutOfEnergyTitle => 'Énergie épuisée';

  @override
  String get energyInfoRechargeUntil => 'Prochaine recharge dans @@TIME@@';

  @override
  String get energyInfoFull => 'Votre énergie est au maximum.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Mode illimité actif';

  @override
  String get energyInsufficient => 'Vous n’avez pas assez d’énergie.';

  @override
  String get endRoleplay => 'Terminer le jeu de rôle';

  @override
  String get energyEnablePushTitle => 'Activer les notifications';

  @override
  String get energyEnablePushSubtitle =>
      'Activez les notifications et rechargez entièrement votre énergie.';

  @override
  String get energyEnablePushPrice => 'Gratuit';

  @override
  String get energyEnablePushOfferBadge => 'OFFRE UNIQUE';

  @override
  String get energyEnablePushCompleted => 'Énergie rechargée !';

  @override
  String get energyPurchaseUnlimitedTitle => 'Pass illimité';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'S’active immédiatement après l’achat. Valable 10 minutes.';

  @override
  String get energyPurchaseCapacityTitle => 'Énergie maximale +1';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Augmente définitivement votre énergie maximale rechargeable de 1.';

  @override
  String get energyGoPremiumTitle => 'Passer à Premium';

  @override
  String get energyGoPremiumExplore => 'Explorer';

  @override
  String get profileGoPremiumTitle => 'Obtenir SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Explorer';

  @override
  String get energyPurchasePendingApproval =>
      'Votre paiement est en attente de validation.';

  @override
  String get energyPurchaseNotCompleted => 'L’achat n’a pas abouti.';

  @override
  String get iapPurchaseProcessing => 'Votre achat est en cours de traitement.';

  @override
  String get iapPurchaseCompleted => 'Achat effectué.';

  @override
  String get welcomeGiftTitle => 'Votre cadeau de bienvenue est arrivé !';

  @override
  String get welcomeGiftBenefitLead =>
      'Jouez sans limites pendant 10 minutes !';

  @override
  String get welcomeGiftLine2 => 'Fonctionnalités Premium débloquées';

  @override
  String get welcomeGiftLine3 => 'Mode illimité débloqué';

  @override
  String get welcomeGiftStartNow => 'Commencer';

  @override
  String get paywallHeroTitle1 => 'Entraînez-vous davantage';

  @override
  String get paywallHeroTitle2 => 'Progressez\nplus vite';

  @override
  String get paywallHeroBody =>
      'Entraînez-vous plus longtemps avec Premium et profitez des retours de l’IA pour parler anglais avec plus d’assurance.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitMaxEnergy => 'Jusqu’à 30 points d’énergie';

  @override
  String get paywallBenefitAiFeedback => 'Retours de l’IA sur vos phrases';

  @override
  String get paywallBenefitProfileBadge => 'Badge Premium sur le profil';

  @override
  String get paywallChoosePlan => 'Choisissez votre formule';

  @override
  String get paywallAnnualPlanTitle => 'Formule annuelle';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Économisez plus de 33 % par rapport à la formule mensuelle.';

  @override
  String get paywallMonthlyPlanTitle => 'Formule mensuelle';

  @override
  String get paywallMonthlyPlanSubtitle => 'Un accès mensuel flexible.';

  @override
  String get paywallBestBadge => 'MEILLEURE OFFRE';

  @override
  String get paywallCta => 'Commencer';

  @override
  String get paywallAutoRenewNotice =>
      'Les abonnements sont renouvelés automatiquement, sauf s’ils sont résiliés au moins 24 heures avant la fin de la période de facturation en cours.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/mois';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/an';
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
  String get paywallCompletedTitle => 'Félicitations !';

  @override
  String get paywallCompletedBody =>
      'Vos avantages Premium sont maintenant actifs.';

  @override
  String get paywallCompletedContinue => 'Continuer';

  @override
  String get roleplayChooseYourRole => 'Choisissez votre rôle';

  @override
  String get roleplaySimilarRoleplays => 'Jeux de rôle similaires';

  @override
  String get roleplayBeingPrepared =>
      'Ce jeu de rôle est en cours de préparation.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Terminez toutes les fins du rôle précédent pour déverrouiller ce rôle.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% terminé';
  }

  @override
  String get roleplayTurnGradeA => 'waouh !';

  @override
  String get roleplayTurnGradeB => 'ok !';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'oh…';

  @override
  String get tutorialPage1Title =>
      'Consultez votre **Mission**\net lancez la conversation.';

  @override
  String get tutorialPage1Tip =>
      '*Astuce : Plus vous parlez naturellement,\nplus la récompense est grande !';

  @override
  String get tutorialPage2Title =>
      'Utilisez le **Traducteur**\nquand vous ne comprenez pas.';

  @override
  String get tutorialPage3Title =>
      'Utilisez un **Indice**\nquand vous bloquez.';

  @override
  String get tutorialPage3Subtitle =>
      'Vous pouvez activer ou désactiver\nles indices auto à tout moment.';

  @override
  String get tutorialPage4Title =>
      'Si la prononciation est difficile,\nécoutez d\'abord, puis répétez.';

  @override
  String get tutorialPage4Tip =>
      '*Astuce : Essayez de répondre sans regarder\nla traduction pour obtenir un meilleur score.';

  @override
  String get tutorialPage5Title => 'Vous ne pouvez pas\nparler à voix haute ?';

  @override
  String get tutorialPage5Subtitle => 'Passez en **mode texte**.';

  @override
  String get tutorialPage6Title =>
      'Personne ne vous juge.\nVous allez y arriver !';

  @override
  String rankCountdownDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String rankCountdownHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String rankCountdownMinutes(int count) {
    return '$count min';
  }

  @override
  String get rankWeeklyTitle => 'Weekly Ranking';

  @override
  String get rankAnnounceTitle => 'Résultats de la semaine';

  @override
  String get rankTop3RewardsTitle => 'Top 3 Rewards';

  @override
  String get rankTop3RewardsDesc =>
      'Earn Likes each week and compete with other learners for the top spots!';

  @override
  String get rankTop3Place1 => '1st';

  @override
  String get rankTop3Place2 => '2nd';

  @override
  String get rankTop3Place3 => '3rd';

  @override
  String get rankTop3Badge1 => '1st Place Badge';

  @override
  String get rankTop3Badge2 => '2nd Place Badge';

  @override
  String get rankTop3Badge3 => '3rd Place Badge';

  @override
  String get rankTop3Likes100 => '+100 Likes';

  @override
  String get rankTop3Likes60 => '+60 Likes';

  @override
  String get rankTop3Likes50 => '+50 Likes';

  @override
  String get rankTop3Box3 => '×3 Reward Box';

  @override
  String get rankTop3Box2 => '×2 Reward Box';

  @override
  String get rankTop3Box1 => '×1 Reward Box';

  @override
  String get rankTop3Okay => 'Okay';

  @override
  String get rankNotRankedYetTitle => 'Vous n\'êtes pas encore classé';

  @override
  String get rankNotRankedYetBody =>
      'Gagnez des Likes pour rejoindre le classement de cette semaine.';

  @override
  String get rankAnnounceNextStartsIn => 'Prochain classement dans :';

  @override
  String get rankAnnounceYou => 'Vous :';

  @override
  String get rankAnnounceRank => 'Rang';

  @override
  String get rankAnnounceLike => 'Like';

  @override
  String get rankPlayNow => 'jouer maintenant';

  @override
  String get rankingRewardClaimCongratulations => 'Félicitations !';

  @override
  String rankingRewardClaimFinishedPlace(int place) {
    return 'Tu as terminé #$place au classement de cette semaine !';
  }

  @override
  String get rankingRewardClaimYourRewards => 'Tes récompenses';

  @override
  String get rankingRewardClaim => 'Récupérer';

  @override
  String get rankingRewardClaimError => 'Une erreur s’est produite. Réessaie.';

  @override
  String get rewardUnboxingTapToOpen => 'Appuie sur la boîte pour l’ouvrir';

  @override
  String get rewardUnboxingNewCharacter => 'Nouveau personnage !';

  @override
  String rewardUnboxingYouGot(String characterName) {
    return 'Tu as obtenu $characterName !';
  }

  @override
  String get rewardUnboxingSetAsProfile => 'Utiliser comme photo';

  @override
  String get rewardUnboxingViewCharacter => 'Voir le personnage';
}
