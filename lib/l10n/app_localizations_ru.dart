// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get agreementHeading =>
      'Чтобы продолжить, ознакомьтесь с условиями ниже и примите их.';

  @override
  String get agreementTermsLabel => 'Я принимаю Условия использования.';

  @override
  String get agreementPrivacyLabel => 'Я принимаю Политику конфиденциальности.';

  @override
  String get agreementTermsTitle => 'Условия использования';

  @override
  String get agreementPrivacyTitle => 'Политика конфиденциальности';

  @override
  String get agreementDetailsLink => 'Подробнее';

  @override
  String get agreementButtonConfirm => 'Принять и продолжить';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsRestorePurchases => 'Восстановить покупки';

  @override
  String get restorePurchasesNothing => 'Нет покупок для восстановления.';

  @override
  String get restorePurchasesCompleted => 'Покупки восстановлены.';

  @override
  String get settingsNotification => 'Уведомления';

  @override
  String get settingsTutorial => 'Обучение';

  @override
  String get settingsCefrLevel => 'Уровень английского';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get pushNotificationsDesc => 'Получайте напоминания и важные новости.';

  @override
  String get settingsFeedback => 'Обратная связь';

  @override
  String get settingsAnnouncements => 'Объявления';

  @override
  String get announcementsEmpty => 'Объявлений пока нет';

  @override
  String get noticesEmpty => 'Публикаций пока нет';

  @override
  String get deletedPost => 'Эта публикация удалена.';

  @override
  String get postNoLongerAvailable => 'Эта публикация больше недоступна.';

  @override
  String get backToHome => 'На главную';

  @override
  String get settingsSignOut => 'Выйти';

  @override
  String get settingsFsdLaboratory => 'Лаборатория FSD';

  @override
  String get settingsPrivacy => 'Политика конфиденциальности';

  @override
  String get settingsTerms => 'Условия использования';

  @override
  String get settingsOpenSource => 'Лицензии открытого ПО';

  @override
  String loginWelcome(String name) {
    return 'Добро пожаловать, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Продолжая, вы соглашаетесь со следующими документами: $terms и $privacy.';
  }

  @override
  String get loginTermsTitle => 'Условия использования';

  @override
  String get loginPrivacyTitle => 'Политика конфиденциальности';

  @override
  String get loginCatchphrase => 'Начните говорить — так и учатся.';

  @override
  String get loginWelcomeTitle => 'Добро пожаловать в SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Погрузитесь в историю и начните говорить по-английски!';

  @override
  String get loginErrorIdToken =>
      'Не удалось получить ID-токен Google. Повторите попытку.';

  @override
  String loginErrorFailed(String error) {
    return 'Не удалось войти: $error';
  }

  @override
  String get accountName => 'Имя';

  @override
  String get accountInfo => 'Аккаунт';

  @override
  String get accountDelete => 'Удалить аккаунт';

  @override
  String get accountDeleteTitle => 'Удалить аккаунт?';

  @override
  String get accountDeleteConfirmText =>
      'Весь прогресс и данные будут удалены без возможности восстановления. Вы уверены?';

  @override
  String get accountDeleteProfileImageTitle => 'Удалить фото профиля?';

  @override
  String get accountDeleteProfileImageContent =>
      'После удаления фото профиля нельзя будет восстановить.';

  @override
  String get accountGoBack => 'Назад';

  @override
  String get accountDeleteAction => 'Удалить';

  @override
  String get accountSubscription => 'Подписка';

  @override
  String get accountFreePlanTitle => 'Бесплатный тариф';

  @override
  String get accountFreePlanSubtitle =>
      'Оформите подписку Premium, чтобы открыть больше возможностей';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Вам доступны преимущества Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Продление: $date';
  }

  @override
  String get accountChangePlan => 'Изменить тариф';

  @override
  String get changePlanTitle => 'Изменить тариф';

  @override
  String get changePlanCurrentPlan => 'Текущий тариф';

  @override
  String get changePlanAvailablePlans => 'Доступные тарифы';

  @override
  String changePlanRenewsOn(String date) {
    return 'Продление: $date';
  }

  @override
  String get changePlanLoadFailed =>
      'Не удалось загрузить данные. Повторите попытку.';

  @override
  String get changePlanRetry => 'Повторить';

  @override
  String get changePlanConfirmTitle => 'Изменить тариф?';

  @override
  String get changePlanConfirmBody =>
      'Новый тариф начнёт действовать в день следующего списания.';

  @override
  String get changePlanConfirmOk => 'Подтвердить';

  @override
  String get changePlanConfirmCancel => 'Оставить текущий тариф';

  @override
  String get changePlanOldPurchaseMissing =>
      'Не найдена активная подписка для смены тарифа. Повторите попытку после её активации.';

  @override
  String get changePlanChangeRequested =>
      'Запрос на смену тарифа отправлен. Новый тариф может начать действовать в день следующего списания.';

  @override
  String get cefrLevelTitle => 'Выберите свой уровень английского';

  @override
  String get cefrLevelAbsoluteBeginner => 'С нуля';

  @override
  String get cefrLevelBeginner => 'Начальный';

  @override
  String get cefrLevelBasic => 'Базовый';

  @override
  String get cefrLevelIntermediate => 'Средний';

  @override
  String get firstCefrLevelTitle => 'Какой у вас уровень английского?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Я умею читать по-английски';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Я знаю основные приветствия и простые фразы';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Я понимаю и использую короткие простые предложения';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Я могу выражать своё мнение и общаться на повседневные темы';

  @override
  String get firstCefrLevelSettingsHint =>
      'Уровень можно изменить в любое время';

  @override
  String get firstCefrLevelConfirm => 'Подтвердить';

  @override
  String get feedbackPlaceholder =>
      'Расскажите, что вы думаете, предложите улучшение или сообщите о проблеме...';

  @override
  String get feedbackSend => 'Отправить';

  @override
  String get feedbackSuccess => 'Спасибо за обратную связь.';

  @override
  String get microphonePermissionDenied =>
      'Без доступа к микрофону начать нельзя.';

  @override
  String get holdMicrophoneToSpeak => 'Удерживайте кнопку микрофона и говорите';

  @override
  String get roleplayTypeMessagePlaceholder => 'Введите сообщение...';

  @override
  String get yourTurnFirst => 'Начните вы!';

  @override
  String get sayLineBelowToStart => 'Произнесите фразу ниже, чтобы начать.';

  @override
  String get roleplayExitWait => 'Подождите!';

  @override
  String get roleplayExitMessage =>
      'Если выйти сейчас, вы не получите награду. Всё равно выйти?';

  @override
  String get roleplayExitKeepPlaying => 'Продолжить';

  @override
  String get roleplayExitExit => 'Выйти';

  @override
  String get roleplayAutoHint => 'Автоподсказки';

  @override
  String get roleplayHintLabel => 'Подсказка';

  @override
  String get roleplayHintShowAnswer => 'Показать вариант ответа на английском';

  @override
  String get roleplayVoiceSpeed => 'Скорость речи';

  @override
  String get roleplayEndedFailed => 'Миссия провалена...';

  @override
  String get roleplayEndedComplete => 'Ролевая игра завершена';

  @override
  String get roleplayEndedEnding => 'Переход к финалу...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Недостаточно прогресса';

  @override
  String get roleplayFinishCompleted => 'Ролевая игра завершена';

  @override
  String get roleplayFinishMovingToEnding => 'Переход к финалу...';

  @override
  String get roleplayAnalyzing => 'Анализируем ролевую игру...';

  @override
  String get roleplayOpeningAiCharacter => 'Персонаж ИИ';

  @override
  String get roleplayOpeningScenario => 'Сценарий';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'ИИ может ошибаться.\nНе сообщайте личную или конфиденциальную информацию.';

  @override
  String get endingFailTitle => 'Вы выполнили не все миссии!';

  @override
  String get endingFailSubtitle => 'Попробуйте снова и узнайте всю историю.';

  @override
  String get roleplayTryAgainMessage =>
      'К сожалению, вы набрали недостаточно баллов, чтобы получить награду.';

  @override
  String get endingReport => 'Сообщить о проблеме';

  @override
  String get endingHowWas => 'Как вам ролевая игра?';

  @override
  String get endingNext => 'Далее';

  @override
  String get reportTitle => 'Сообщить о проблеме';

  @override
  String get profileHistory => 'История';

  @override
  String get profileSaved => 'Сохранённое';

  @override
  String get profileHistoryEmpty => 'Истории пока нет';

  @override
  String get profileSavedEmpty => 'Сохранённых выражений пока нет.';

  @override
  String get profileSavedRemoveTitle => 'Удалить из сохранённого?';

  @override
  String get profileSavedRemoveContent =>
      'Позже это выражение можно снова найти в истории.';

  @override
  String get profileSavedRemoveOk => 'Удалить';

  @override
  String get profileSavedRemoveCancel => 'Продолжить практику';

  @override
  String get seriesOverviewTabEpisodes => 'Эпизоды';

  @override
  String get seriesOverviewTabSimilarTopic => 'Похожие темы';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Эпизод #$number';
  }

  @override
  String get seriesOverviewPlay => 'Играть';

  @override
  String get seriesOverviewLocked => 'Заблокирован';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Чтобы открыть, завершите предыдущий эпизод.';

  @override
  String get notificationPermissionBlockedTitle => 'Уведомления отключены';

  @override
  String get notificationPermissionBlockedMessage =>
      'Чтобы получать push-уведомления, включите их в настройках устройства.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEmpty => 'Уведомлений пока нет';

  @override
  String get notificationSendToday => 'Сегодня';

  @override
  String get notificationSendOneDayAgo => '1 день назад';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count дн. назад';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Повторно зарегистрироваться можно через 2 дня после удаления аккаунта. Попробуйте позже.';

  @override
  String get expressionSavedToProfile => 'Сохранено в профиле';

  @override
  String get expressionUnsavedToProfile => 'Удалено из сохранённого';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'В этот раз не удалось дать обратную связь. Ответьте подробнее — используйте не менее 7 слов!';

  @override
  String get roleplayResultScoreMeaning => 'Смысл';

  @override
  String get roleplayResultScoreRelevance => 'Соответствие';

  @override
  String get roleplayResultScoreVocabulary => 'Лексика';

  @override
  String get roleplayResultScoreGrammar => 'Грамматика';

  @override
  String get closePopup => 'Закрыть';

  @override
  String get reviewChatTapHint =>
      'Нажмите на облачко сообщения, чтобы воспроизвести аудио.';

  @override
  String get reviewChatNoAudioToPlay => 'Нет аудио для воспроизведения.';

  @override
  String get seriesInformationTopicDifficulty => 'Сложность темы';

  @override
  String get seriesInformationLearningGoals => 'Цели обучения';

  @override
  String get energyInfoTitle => 'Энергия';

  @override
  String get energyOutOfEnergyTitle => 'Энергия закончилась';

  @override
  String get energyInfoRechargeUntil =>
      'До следующего восстановления: @@TIME@@';

  @override
  String get energyInfoFull => 'Энергия полностью восстановлена.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Безлимитный режим активен';

  @override
  String get energyInsufficient => 'Недостаточно энергии.';

  @override
  String get endRoleplay => 'Завершить ролевую игру';

  @override
  String get energyEnablePushTitle => 'Включить уведомления';

  @override
  String get energyEnablePushSubtitle =>
      'Включите уведомления и полностью восстановите энергию.';

  @override
  String get energyEnablePushPrice => 'Бесплатно';

  @override
  String get energyEnablePushOfferBadge => 'РАЗОВОЕ ПРЕДЛОЖЕНИЕ';

  @override
  String get energyEnablePushCompleted => 'Энергия восстановлена!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Безлимитный пропуск';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Активируется сразу после покупки и действует 10 минут.';

  @override
  String get energyPurchaseCapacityTitle => 'Увеличение запаса энергии';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Навсегда увеличивает максимальный запас энергии на 1.';

  @override
  String get energyGoPremiumTitle => 'Перейти на Premium';

  @override
  String get energyGoPremiumExplore => 'Подробнее';

  @override
  String get profileGoPremiumTitle => 'Оформить SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Подробнее';

  @override
  String get energyPurchasePendingApproval => 'Платёж ожидает подтверждения.';

  @override
  String get energyPurchaseNotCompleted => 'Покупка не завершена.';

  @override
  String get welcomeGiftTitle => 'Ваш приветственный подарок уже здесь!';

  @override
  String get welcomeGiftBenefitLead => 'Играйте без ограничений 10 минут!';

  @override
  String get welcomeGiftLine2 => 'Функции Premium открыты';

  @override
  String get welcomeGiftLine3 => 'Открыт безлимитный режим';

  @override
  String get welcomeGiftStartNow => 'Начать';

  @override
  String get paywallHeroTitle1 => 'Практикуйтесь больше';

  @override
  String get paywallHeroTitle2 => 'Учитесь быстрее';

  @override
  String get paywallHeroBody =>
      'Практикуйтесь дольше с Premium и получайте обратную связь от ИИ, чтобы увереннее говорить по-английски.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Больше практики каждый день';

  @override
  String get paywallBenefitMaxEnergy => 'До 30 единиц энергии';

  @override
  String get paywallBenefitAiFeedback => 'Обратная связь от ИИ по фразам';

  @override
  String get paywallChoosePlan => 'Выберите тариф';

  @override
  String get paywallAnnualPlanTitle => 'Годовой тариф';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Экономия более 33% по сравнению с месячным тарифом.';

  @override
  String get paywallMonthlyPlanTitle => 'Месячный тариф';

  @override
  String get paywallMonthlyPlanSubtitle => 'Гибкая помесячная подписка.';

  @override
  String get paywallBestBadge => 'ВЫГОДНО';

  @override
  String get paywallCta => 'Оформить подписку';

  @override
  String get paywallAutoRenewNotice =>
      'Подписка продлевается автоматически, если её не отменить минимум за 24 часа до окончания текущего расчётного периода.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/мес.';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/год';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'Поздравляем!';

  @override
  String get paywallCompletedBody => 'Преимущества Premium уже доступны.';

  @override
  String get paywallCompletedContinue => 'Продолжить';
}
