// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get agreementHeading =>
      'Aby kontynuować, zapoznaj się z poniższymi dokumentami i zaakceptuj je.';

  @override
  String get agreementTermsLabel => 'Akceptuję Warunki korzystania.';

  @override
  String get agreementPrivacyLabel => 'Akceptuję Politykę prywatności.';

  @override
  String get agreementTermsTitle => 'Warunki korzystania';

  @override
  String get agreementPrivacyTitle => 'Polityka prywatności';

  @override
  String get agreementDetailsLink => 'Zobacz szczegóły';

  @override
  String get agreementButtonConfirm => 'Akceptuj i kontynuuj';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsRestorePurchases => 'Przywróć zakupy';

  @override
  String get restorePurchasesNothing => 'Brak zakupów do przywrócenia.';

  @override
  String get restorePurchasesCompleted => 'Zakupy przywrócone.';

  @override
  String get settingsNotification => 'Powiadomienia';

  @override
  String get settingsTutorial => 'Samouczek';

  @override
  String get settingsCefrLevel => 'Poziom angielskiego';

  @override
  String get pushNotifications => 'Powiadomienia push';

  @override
  String get pushNotificationsDesc =>
      'Otrzymuj przypomnienia i ważne aktualizacje.';

  @override
  String get settingsFeedback => 'Prześlij opinię';

  @override
  String get settingsAnnouncements => 'Ogłoszenia';

  @override
  String get announcementsEmpty => 'Nie ma jeszcze ogłoszeń';

  @override
  String get noticesEmpty => 'Nie ma jeszcze wpisów';

  @override
  String get deletedPost => 'Ten wpis został usunięty.';

  @override
  String get postNoLongerAvailable => 'Ten wpis nie jest już dostępny.';

  @override
  String get backToHome => 'Wróć do ekranu głównego';

  @override
  String get settingsSignOut => 'Wyloguj się';

  @override
  String get settingsFsdLaboratory => 'Laboratorium FSD';

  @override
  String get settingsPrivacy => 'Polityka prywatności';

  @override
  String get settingsTerms => 'Warunki świadczenia usług';

  @override
  String get settingsOpenSource => 'Licencje open source';

  @override
  String loginWelcome(String name) {
    return 'Witaj, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Kontynuując, akceptujesz dokumenty: $terms i $privacy.';
  }

  @override
  String get loginTermsTitle => 'Warunki korzystania';

  @override
  String get loginPrivacyTitle => 'Polityka prywatności';

  @override
  String get loginCatchphrase => 'Zacznij mówić. Tak uczysz się najlepiej.';

  @override
  String get loginWelcomeTitle => 'Witaj w SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Przenieś się do opowieści i zacznij mówić po angielsku!';

  @override
  String get loginErrorIdToken =>
      'Nie udało się pobrać tokenu identyfikacyjnego Google. Spróbuj ponownie.';

  @override
  String loginErrorFailed(String error) {
    return 'Logowanie nie powiodło się: $error';
  }

  @override
  String get accountName => 'Imię';

  @override
  String get accountInfo => 'Konto';

  @override
  String get accountDelete => 'Usuń konto';

  @override
  String get accountDeleteTitle => 'Usunąć konto?';

  @override
  String get accountDeleteConfirmText =>
      'Cały twój postęp i wszystkie dane zostaną trwale usunięte. Czy na pewno?';

  @override
  String get accountDeleteProfileImageTitle => 'Usunąć zdjęcie profilowe?';

  @override
  String get accountDeleteProfileImageContent =>
      'Usuniętego zdjęcia profilowego nie można odzyskać.';

  @override
  String get accountGoBack => 'Wróć';

  @override
  String get accountDeleteAction => 'Usuń';

  @override
  String get accountSubscription => 'Subskrypcja';

  @override
  String get accountFreePlanTitle => 'Plan bezpłatny';

  @override
  String get accountFreePlanSubtitle =>
      'Przejdź na Premium, aby odblokować więcej funkcji';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Korzystasz z funkcji Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Odnowienie: $date';
  }

  @override
  String get accountChangePlan => 'Zmień plan';

  @override
  String get changePlanTitle => 'Zmień plan';

  @override
  String get changePlanCurrentPlan => 'Obecny plan';

  @override
  String get changePlanAvailablePlans => 'Dostępne plany';

  @override
  String changePlanRenewsOn(String date) {
    return 'Odnowienie: $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Nie udało się wczytać informacji. Spróbuj ponownie.';

  @override
  String get changePlanRetry => 'Spróbuj ponownie';

  @override
  String get changePlanConfirmTitle => 'Zmienić plan?';

  @override
  String get changePlanConfirmBody =>
      'Zmiana planu zacznie obowiązywać w dniu następnego rozliczenia.';

  @override
  String get changePlanConfirmOk => 'Potwierdź';

  @override
  String get changePlanConfirmCancel => 'Zachowaj obecny plan';

  @override
  String get changePlanOldPurchaseMissing =>
      'Nie znaleziono aktywnej subskrypcji do zmiany. Spróbuj ponownie, gdy subskrypcja będzie aktywna.';

  @override
  String get changePlanChangeRequested =>
      'Zlecono zmianę planu. Może wejść w życie w dniu następnego rozliczenia.';

  @override
  String get cefrLevelTitle => 'Wybierz swój poziom angielskiego';

  @override
  String get cefrLevelAbsoluteBeginner => 'Od podstaw';

  @override
  String get cefrLevelBeginner => 'Początkujący';

  @override
  String get cefrLevelBasic => 'Podstawowy';

  @override
  String get cefrLevelIntermediate => 'Średnio zaawansowany';

  @override
  String get firstCefrLevelTitle => 'Jaki jest twój poziom angielskiego?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Potrafię czytać po angielsku';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Znam podstawowe powitania i proste zwroty';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Rozumiem i potrafię używać krótkich, prostych zdań';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Potrafię wyrazić swoją opinię i uczestniczyć w codziennych rozmowach';

  @override
  String get firstCefrLevelSettingsHint => 'Możesz go zmienić w każdej chwili';

  @override
  String get firstCefrLevelConfirm => 'Potwierdź';

  @override
  String get feedbackPlaceholder =>
      'Podziel się swoją opinią, sugestiami lub napotkanymi problemami...';

  @override
  String get feedbackSend => 'Wyślij';

  @override
  String get feedbackSuccess => 'Dziękujemy za opinię.';

  @override
  String get microphonePermissionDenied =>
      'Bez dostępu do mikrofonu nie można rozpocząć.';

  @override
  String get holdMicrophoneToSpeak =>
      'Przytrzymaj przycisk mikrofonu, aby mówić';

  @override
  String get roleplayTypeMessagePlaceholder => 'Wpisz wiadomość...';

  @override
  String get yourTurnFirst => 'Teraz twoja kolej!';

  @override
  String get sayLineBelowToStart => 'Powiedz poniższą kwestię, aby rozpocząć.';

  @override
  String get roleplayExitWait => 'Poczekaj!';

  @override
  String get roleplayExitMessage =>
      'Jeśli teraz wyjdziesz, stracisz nagrodę. Na pewno chcesz wyjść?';

  @override
  String get roleplayExitKeepPlaying => 'Graj dalej';

  @override
  String get roleplayExitExit => 'Wyjdź';

  @override
  String get roleplayAutoHint => 'Automatyczna podpowiedź';

  @override
  String get roleplayHintLabel => 'Podpowiedź';

  @override
  String get roleplayHintShowAnswer =>
      'Pokaż sugerowaną odpowiedź po angielsku';

  @override
  String get roleplayVoiceSpeed => 'Szybkość mowy';

  @override
  String get roleplayEndedFailed => 'Misja nieudana...';

  @override
  String get roleplayEndedComplete => 'Scenka ukończona';

  @override
  String get roleplayEndedEnding => 'Przechodzimy do zakończenia...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Za mały postęp';

  @override
  String get roleplayFinishCompleted => 'Scenka ukończona';

  @override
  String get roleplayFinishMovingToEnding => 'Przechodzimy do zakończenia...';

  @override
  String get roleplayAnalyzing => 'Analizujemy twoją rozmowę...';

  @override
  String get roleplayOpeningAiCharacter => 'Postać AI';

  @override
  String get roleplayOpeningScenario => 'Scenariusz';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AI może się mylić.\nNie udostępniaj danych osobowych ani poufnych informacji.';

  @override
  String get endingFailTitle => 'Nie udało ci się ukończyć wszystkich misji!';

  @override
  String get endingFailSubtitle => 'Spróbuj ponownie i odkryj całą historię.';

  @override
  String get roleplayTryAgainMessage =>
      'Niestety twój wynik był zbyt niski, aby zdobyć nagrodę.';

  @override
  String get endingReport => 'Zgłoś problem';

  @override
  String get endingHowWas => 'Jak oceniasz tę scenkę?';

  @override
  String get endingNext => 'Dalej';

  @override
  String get reportTitle => 'Zgłoś problem';

  @override
  String get profileHistory => 'Historia';

  @override
  String get profileSaved => 'Zapisane';

  @override
  String get profileHistoryEmpty => 'Brak historii';

  @override
  String get profileSavedEmpty => 'Nie masz jeszcze zapisanych zwrotów.';

  @override
  String get profileSavedRemoveTitle => 'Usunąć z zapisanych?';

  @override
  String get profileSavedRemoveContent =>
      'Ten zwrot znajdziesz później w historii.';

  @override
  String get profileSavedRemoveOk => 'Usuń';

  @override
  String get profileSavedRemoveCancel => 'Ćwicz dalej';

  @override
  String get seriesOverviewTabEpisodes => 'Odcinki';

  @override
  String get seriesOverviewTabSimilarTopic => 'Podobne tematy';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Odcinek #$number';
  }

  @override
  String get seriesOverviewPlay => 'Graj';

  @override
  String get seriesOverviewLocked => 'Zablokowany';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Ukończ poprzedni odcinek, aby odblokować kolejny.';

  @override
  String get notificationPermissionBlockedTitle => 'Powiadomienia są wyłączone';

  @override
  String get notificationPermissionBlockedMessage =>
      'Włącz powiadomienia w ustawieniach urządzenia, aby otrzymywać powiadomienia push.';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get notificationsTitle => 'Powiadomienia';

  @override
  String get notificationsEmpty => 'Brak powiadomień';

  @override
  String get notificationSendToday => 'Dzisiaj';

  @override
  String get notificationSendOneDayAgo => '1 dzień temu';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count dni temu';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Możesz zarejestrować się ponownie 2 dni po usunięciu konta. Spróbuj ponownie później.';

  @override
  String get expressionSavedToProfile => 'Zapisano w profilu';

  @override
  String get expressionUnsavedToProfile => 'Usunięto z zapisanych';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Tym razem nie udało się przygotować informacji zwrotnej. Użyj co najmniej 7 słów!';

  @override
  String get roleplayResultScoreMeaning => 'Znaczenie';

  @override
  String get roleplayResultScoreRelevance => 'Trafność';

  @override
  String get roleplayResultScoreVocabulary => 'Słownictwo';

  @override
  String get roleplayResultScoreGrammar => 'Gramatyka';

  @override
  String get closePopup => 'Zamknij';

  @override
  String get reviewChatTapHint => 'Dotknij dymku czatu, aby odtworzyć dźwięk.';

  @override
  String get reviewChatNoAudioToPlay => 'Brak dźwięku do odtworzenia.';

  @override
  String get seriesInformationTopicDifficulty => 'Trudność tematu';

  @override
  String get seriesInformationLearningGoals => 'Cele nauki';

  @override
  String get energyInfoTitle => 'Energia';

  @override
  String get energyOutOfEnergyTitle => 'Brak energii';

  @override
  String get energyInfoRechargeUntil => 'Do następnego doładowania: @@TIME@@';

  @override
  String get energyInfoFull => 'Masz pełną energię.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Aktywny tryb bez limitu';

  @override
  String get energyInsufficient => 'Masz za mało energii.';

  @override
  String get endRoleplay => 'Zakończ scenkę';

  @override
  String get energyEnablePushTitle => 'Włącz powiadomienia';

  @override
  String get energyEnablePushSubtitle =>
      'Włącz powiadomienia i uzupełnij energię do pełna.';

  @override
  String get energyEnablePushPrice => 'Bezpłatnie';

  @override
  String get energyEnablePushOfferBadge => 'OFERTA JEDNORAZOWA';

  @override
  String get energyEnablePushCompleted => 'Energia uzupełniona!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Karnet bez limitu';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Włącza się natychmiast po zakupie. Działa przez 10 minut.';

  @override
  String get energyPurchaseCapacityTitle => 'Większy limit energii';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Na stałe zwiększa limit energii o 1.';

  @override
  String get energyGoPremiumTitle => 'Przejdź na Premium';

  @override
  String get energyGoPremiumExplore => 'Sprawdź';

  @override
  String get profileGoPremiumTitle => 'Przejdź na SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Sprawdź';

  @override
  String get energyPurchasePendingApproval =>
      'Twoja płatność oczekuje na zatwierdzenie.';

  @override
  String get energyPurchaseNotCompleted => 'Zakup nie został sfinalizowany.';

  @override
  String get welcomeGiftTitle => 'Twój prezent powitalny już tu jest!';

  @override
  String get welcomeGiftBenefitLead => 'Graj bez limitu przez 10 minut!';

  @override
  String get welcomeGiftLine2 => 'Odblokowano funkcje Premium';

  @override
  String get welcomeGiftLine3 => 'Odblokowano grę bez limitu';

  @override
  String get welcomeGiftStartNow => 'Zacznij teraz';

  @override
  String get paywallHeroTitle1 => 'Ćwicz więcej';

  @override
  String get paywallHeroTitle2 => 'Ucz się szybciej';

  @override
  String get paywallHeroBody =>
      'Ćwicz dłużej z Premium i otrzymuj informacje zwrotne od AI, aby mówić po angielsku z większą pewnością.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Więcej ćwiczeń każdego dnia';

  @override
  String get paywallBenefitMaxEnergy => 'Do 30 punktów energii';

  @override
  String get paywallBenefitAiFeedback => 'Informacje zwrotne od AI';

  @override
  String get paywallChoosePlan => 'Wybierz plan';

  @override
  String get paywallAnnualPlanTitle => 'Plan roczny';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Oszczędź ponad 33% w porównaniu z planem miesięcznym.';

  @override
  String get paywallMonthlyPlanTitle => 'Plan miesięczny';

  @override
  String get paywallMonthlyPlanSubtitle => 'Elastyczny dostęp co miesiąc.';

  @override
  String get paywallBestBadge => 'NAJLEPSZY';

  @override
  String get paywallCta => 'Subskrybuj';

  @override
  String get paywallAutoRenewNotice =>
      'Subskrypcja odnawia się automatycznie, chyba że anulujesz ją co najmniej 24 godziny przed końcem bieżącego okresu rozliczeniowego.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/miesiąc';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/rok';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Gratulacje!';

  @override
  String get paywallCompletedBody => 'Twoje korzyści Premium są już aktywne.';

  @override
  String get paywallCompletedContinue => 'Kontynuuj';

  @override
  String get roleplayChooseYourRole => 'Wybierz swoją rolę';

  @override
  String get roleplaySimilarRoleplays => 'Podobne odgrywanie ról';

  @override
  String get roleplayBeingPrepared => 'Ten roleplay jest w przygotowaniu.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Ukończ wszystkie zakończenia poprzedniej roli, aby odblokować tę rolę.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return 'Ukończono $percent%';
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
