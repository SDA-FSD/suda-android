// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get agreementHeading =>
      'Revisa y acepta los siguientes términos para continuar.';

  @override
  String get agreementTermsLabel => 'Acepto los Términos de uso.';

  @override
  String get agreementPrivacyLabel => 'Acepto la Política de privacidad.';

  @override
  String get agreementTermsTitle => 'Términos de uso';

  @override
  String get agreementPrivacyTitle => 'Política de privacidad';

  @override
  String get agreementDetailsLink => 'Ver detalles';

  @override
  String get agreementButtonConfirm => 'Aceptar y continuar';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get restorePurchasesNothing => 'No hay compras para restaurar.';

  @override
  String get restorePurchasesCompleted => 'Se restauraron las compras.';

  @override
  String get settingsNotification => 'Notificaciones';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Nivel de inglés';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get pushNotificationsDesc =>
      'Recibe recordatorios y actualizaciones importantes.';

  @override
  String get settingsFeedback => 'Comentarios';

  @override
  String get settingsAnnouncements => 'Anuncios';

  @override
  String get announcementsEmpty => 'Aún no hay anuncios';

  @override
  String get noticesEmpty => 'Aún no hay publicaciones';

  @override
  String get deletedPost => 'Esta publicación fue eliminada.';

  @override
  String get postNoLongerAvailable => 'Esta publicación ya no está disponible.';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsFsdLaboratory => 'Laboratorio FSD';

  @override
  String get settingsPrivacy => 'Política de privacidad';

  @override
  String get settingsTerms => 'Términos del servicio';

  @override
  String get settingsOpenSource => 'Licencias de código abierto';

  @override
  String loginWelcome(String name) {
    return '¡Te damos la bienvenida, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Al continuar, aceptas los $terms y la $privacy.';
  }

  @override
  String get loginTermsTitle => 'Términos de uso';

  @override
  String get loginPrivacyTitle => 'Política de privacidad';

  @override
  String get loginCatchphrase => 'Empieza a hablar. Así es como se aprende.';

  @override
  String get loginWelcomeTitle => '¡Te damos la bienvenida a SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      '¡Entra en una historia y empieza a hablar inglés!';

  @override
  String get loginErrorIdToken =>
      'No se pudo obtener el token de ID de Google. Inténtalo de nuevo.';

  @override
  String loginErrorFailed(String error) {
    return 'Error de inicio de sesión: $error';
  }

  @override
  String get accountName => 'Nombre';

  @override
  String get accountInfo => 'Cuenta';

  @override
  String get accountDelete => 'Eliminar cuenta';

  @override
  String get accountDeleteTitle => '¿Eliminar la cuenta?';

  @override
  String get accountDeleteConfirmText =>
      'Todo tu progreso y tus datos se perderán permanentemente. ¿Confirmas que deseas continuar?';

  @override
  String get accountDeleteProfileImageTitle => '¿Eliminar la foto de perfil?';

  @override
  String get accountDeleteProfileImageContent =>
      'Una vez eliminada, tu foto de perfil no se podrá recuperar.';

  @override
  String get accountGoBack => 'Volver';

  @override
  String get accountDeleteAction => 'Eliminar';

  @override
  String get accountSubscription => 'Suscripción';

  @override
  String get accountFreePlanTitle => 'Plan gratuito';

  @override
  String get accountFreePlanSubtitle =>
      'Obtén Premium para desbloquear más funciones';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Disfrutas de los beneficios Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get accountChangePlan => 'Cambiar plan';

  @override
  String get changePlanTitle => 'Cambiar plan';

  @override
  String get changePlanCurrentPlan => 'Plan actual';

  @override
  String get changePlanAvailablePlans => 'Planes disponibles';

  @override
  String changePlanRenewsOn(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get changePlanLoadFailed =>
      'No se pudo cargar la información. Inténtalo de nuevo.';

  @override
  String get changePlanRetry => 'Volver a intentar';

  @override
  String get changePlanConfirmTitle => '¿Cambiar de plan?';

  @override
  String get changePlanConfirmBody =>
      'El cambio de plan entrará en vigor en tu próxima fecha de facturación.';

  @override
  String get changePlanConfirmOk => 'Confirmar';

  @override
  String get changePlanConfirmCancel => 'Conservar el plan actual';

  @override
  String get changePlanOldPurchaseMissing =>
      'No encontramos una suscripción activa que puedas cambiar. Inténtalo de nuevo cuando tu suscripción esté activa.';

  @override
  String get changePlanChangeRequested =>
      'Se solicitó el cambio de plan. Es posible que se aplique en tu próxima fecha de facturación.';

  @override
  String get cefrLevelTitle => 'Elige tu nivel de inglés';

  @override
  String get cefrLevelAbsoluteBeginner => 'Principiante absoluto';

  @override
  String get cefrLevelBeginner => 'Principiante';

  @override
  String get cefrLevelBasic => 'Básico';

  @override
  String get cefrLevelIntermediate => 'Intermedio';

  @override
  String get firstCefrLevelTitle => '¿Cuál es tu nivel de inglés?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Sé leer en inglés';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Conozco saludos básicos y expresiones sencillas';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Puedo usar y entender oraciones cortas y sencillas';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Puedo expresar mi opinión y participar en conversaciones cotidianas';

  @override
  String get firstCefrLevelSettingsHint =>
      'Puedes cambiarlo en cualquier momento';

  @override
  String get firstCefrLevelConfirm => 'Confirmar';

  @override
  String get feedbackPlaceholder =>
      'Comparte tus opiniones, sugerencias o cualquier problema que hayas encontrado...';

  @override
  String get feedbackSend => 'Enviar';

  @override
  String get feedbackSuccess => 'Gracias por tus comentarios.';

  @override
  String get microphonePermissionDenied =>
      'No se puede empezar sin permiso para usar el micrófono.';

  @override
  String get holdMicrophoneToSpeak =>
      'Mantén presionado el micrófono para hablar';

  @override
  String get roleplayTypeMessagePlaceholder => 'Escribe tu mensaje...';

  @override
  String get yourTurnFirst => '¡Tú empiezas!';

  @override
  String get sayLineBelowToStart => 'Di la frase de abajo para empezar.';

  @override
  String get roleplayExitWait => '¡Espera!';

  @override
  String get roleplayExitMessage =>
      'Si sales ahora, perderás tu recompensa. ¿Confirmas que deseas salir?';

  @override
  String get roleplayExitKeepPlaying => 'Seguir jugando';

  @override
  String get roleplayExitExit => 'Salir';

  @override
  String get roleplayAutoHint => 'Pista automática';

  @override
  String get roleplayHintLabel => 'Pista';

  @override
  String get roleplayHintShowAnswer =>
      'Toca para ver una respuesta sugerida en inglés';

  @override
  String get roleplayVoiceSpeed => 'Velocidad de voz';

  @override
  String get roleplayEndedFailed => 'Misión fallida...';

  @override
  String get roleplayEndedComplete => 'Juego de rol completado';

  @override
  String get roleplayEndedEnding => 'Pasando al desenlace...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Progreso insuficiente';

  @override
  String get roleplayFinishCompleted => 'Juego de rol completado';

  @override
  String get roleplayFinishMovingToEnding => 'Pasando al desenlace...';

  @override
  String get roleplayAnalyzing => 'Analizando tu juego de rol...';

  @override
  String get roleplayOpeningAiCharacter => 'Personaje de IA';

  @override
  String get roleplayOpeningScenario => 'Escenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'La IA puede cometer errores.\nNo compartas información personal ni sensible.';

  @override
  String get endingFailTitle => '¡No completaste todas las misiones!';

  @override
  String get endingFailSubtitle =>
      'Inténtalo de nuevo y descubre la historia completa.';

  @override
  String get roleplayTryAgainMessage =>
      'Lamentablemente, tu puntuación no fue suficiente para obtener la recompensa.';

  @override
  String get endingReport => 'Reportar un problema';

  @override
  String get endingHowWas => '¿Qué te pareció el juego de rol?';

  @override
  String get endingNext => 'Siguiente';

  @override
  String get reportTitle => 'Reportar un problema';

  @override
  String get profileHistory => 'Historial';

  @override
  String get profileSaved => 'Guardadas';

  @override
  String get profileHistoryEmpty => 'Aún no hay historial';

  @override
  String get profileSavedEmpty => 'Aún no hay expresiones guardadas.';

  @override
  String get profileSavedRemoveTitle => '¿Dejar de guardar esta expresión?';

  @override
  String get profileSavedRemoveContent =>
      'Puedes volver a encontrarla más tarde en el historial.';

  @override
  String get profileSavedRemoveOk => 'Quitar';

  @override
  String get profileSavedRemoveCancel => 'Practicar más';

  @override
  String get seriesOverviewTabEpisodes => 'Episodios';

  @override
  String get seriesOverviewTabSimilarTopic => 'Temas similares';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episodio #$number';
  }

  @override
  String get seriesOverviewPlay => 'Jugar';

  @override
  String get seriesOverviewLocked => 'Bloqueado';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Completa el episodio anterior para desbloquearlo.';

  @override
  String get notificationPermissionBlockedTitle =>
      'Las notificaciones están desactivadas';

  @override
  String get notificationPermissionBlockedMessage =>
      'Activa las notificaciones en la configuración de tu dispositivo para recibir notificaciones push.';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Aún no hay notificaciones';

  @override
  String get notificationSendToday => 'Hoy';

  @override
  String get notificationSendOneDayAgo => 'Hace 1 día';

  @override
  String notificationSendDaysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Podrás volver a registrarte 2 días después de eliminar tu cuenta. Inténtalo de nuevo más tarde.';

  @override
  String get expressionSavedToProfile => 'Guardada en tu perfil';

  @override
  String get expressionUnsavedToProfile => 'Ya no está guardada';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Esta vez no pudimos darte comentarios. ¡Intenta responder con 7 palabras o más!';

  @override
  String get roleplayResultScoreMeaning => 'Significado';

  @override
  String get roleplayResultScoreRelevance => 'Relevancia';

  @override
  String get roleplayResultScoreVocabulary => 'Vocabulario';

  @override
  String get roleplayResultScoreGrammar => 'Gramática';

  @override
  String get closePopup => 'Cerrar';

  @override
  String get reviewChatTapHint =>
      'Toca la burbuja de chat para reproducir el audio.';

  @override
  String get reviewChatNoAudioToPlay => 'No hay audio para reproducir.';

  @override
  String get seriesInformationTopicDifficulty => 'Dificultad del tema';

  @override
  String get seriesInformationLearningGoals => 'Objetivos de aprendizaje';

  @override
  String get energyInfoTitle => 'Energía';

  @override
  String get energyOutOfEnergyTitle => 'Sin energía';

  @override
  String get energyInfoRechargeUntil => 'Próxima recarga en @@TIME@@';

  @override
  String get energyInfoFull => 'Tu energía está al máximo.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Modo ilimitado activo';

  @override
  String get energyInsufficient => 'No tienes suficiente energía.';

  @override
  String get endRoleplay => 'Finalizar el juego de rol';

  @override
  String get energyEnablePushTitle => 'Activar notificaciones';

  @override
  String get energyEnablePushSubtitle =>
      'Activa las notificaciones y recarga por completo tu energía.';

  @override
  String get energyEnablePushPrice => 'Gratis';

  @override
  String get energyEnablePushOfferBadge => 'OFERTA POR ÚNICA VEZ';

  @override
  String get energyEnablePushCompleted => '¡Energía recargada!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Pase ilimitado';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Comienza inmediatamente después de la compra. Válido durante 10 minutos.';

  @override
  String get energyPurchaseCapacityTitle => 'Aumento de energía máxima';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Aumenta en 1 tu energía máxima recargable de forma permanente.';

  @override
  String get energyGoPremiumTitle => 'Obtén Premium';

  @override
  String get energyGoPremiumExplore => 'Explorar';

  @override
  String get profileGoPremiumTitle => 'Obtén SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Explorar';

  @override
  String get energyPurchasePendingApproval =>
      'Tu pago está pendiente de aprobación.';

  @override
  String get energyPurchaseNotCompleted => 'La compra no se completó.';

  @override
  String get iapPurchaseProcessing => 'Tu compra se está procesando.';

  @override
  String get iapPurchaseCompleted => 'Compra completada.';

  @override
  String get welcomeGiftTitle => '¡Llegó tu regalo de bienvenida!';

  @override
  String get welcomeGiftBenefitLead => '¡Juega sin límites durante 10 minutos!';

  @override
  String get welcomeGiftLine2 => 'Funciones Premium desbloqueadas';

  @override
  String get welcomeGiftLine3 => 'Modo ilimitado desbloqueado';

  @override
  String get welcomeGiftStartNow => 'Empezar ahora';

  @override
  String get paywallHeroTitle1 => 'Practica más';

  @override
  String get paywallHeroTitle2 => 'Mejora más rápido';

  @override
  String get paywallHeroBody =>
      'Practica por más tiempo con Premium y recibe comentarios de la IA para ganar confianza al hablar inglés.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Más práctica diaria';

  @override
  String get paywallBenefitMaxEnergy => 'Hasta 30 puntos de energía';

  @override
  String get paywallBenefitAiFeedback =>
      'Comentarios de la IA sobre tus frases';

  @override
  String get paywallChoosePlan => 'Elige tu plan';

  @override
  String get paywallAnnualPlanTitle => 'Plan anual';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Ahorra más del 33% en comparación con el plan mensual.';

  @override
  String get paywallMonthlyPlanTitle => 'Plan mensual';

  @override
  String get paywallMonthlyPlanSubtitle => 'Acceso mensual flexible.';

  @override
  String get paywallBestBadge => 'MEJOR';

  @override
  String get paywallCta => 'Empezar ahora';

  @override
  String get paywallAutoRenewNotice =>
      'Las suscripciones se renuevan automáticamente, a menos que se cancelen al menos 24 horas antes de que finalice el período de facturación actual.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/mes';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/año';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => '¡Felicidades!';

  @override
  String get paywallCompletedBody => 'Tus beneficios Premium ya están activos.';

  @override
  String get paywallCompletedContinue => 'Continuar';

  @override
  String get roleplayChooseYourRole => 'Elige tu papel';

  @override
  String get roleplaySimilarRoleplays => 'Roleplays similares';

  @override
  String get roleplayBeingPrepared => 'Este roleplay se está preparando.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Completa todos los finales del papel anterior para desbloquear este papel.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% completado';
  }

  @override
  String get roleplayTurnGradeA => '¡guau!';

  @override
  String get roleplayTurnGradeB => 'ok!';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'oh…';

  @override
  String get tutorialPage1Title =>
      'Revisa tu **Misión**\ny empieza la conversación.';

  @override
  String get tutorialPage1Tip =>
      '*Consejo: ¡Cuanto más natural hables,\nmayor será tu recompensa!';

  @override
  String get tutorialPage2Title =>
      '¡Usa el **Traductor**\ncuando no entiendas!';

  @override
  String get tutorialPage3Title => 'Usa una **Pista**\ncuando te trabes.';

  @override
  String get tutorialPage3Subtitle =>
      'Puedes activar o desactivar\nlas pistas automáticas cuando quieras.';

  @override
  String get tutorialPage4Title =>
      'Si la pronunciación es difícil,\nescucha primero y luego repite.';

  @override
  String get tutorialPage4Tip =>
      '*Consejo: Intenta responder sin mirar la traducción\npara obtener una puntuación más alta.';

  @override
  String get tutorialPage5Title => '¿No puedes hablar\nen voz alta?';

  @override
  String get tutorialPage5Subtitle => 'Cambia al **Modo texto**.';

  @override
  String get tutorialPage6Title => 'Nadie te está juzgando.\n¡Tú puedes!';
}

/// The translations for Spanish Castilian, as used in Latin America and the Caribbean (`es_419`).
class AppLocalizationsEs419 extends AppLocalizationsEs {
  AppLocalizationsEs419() : super('es_419');

  @override
  String get agreementHeading =>
      'Revisa y acepta los siguientes términos para continuar.';

  @override
  String get agreementTermsLabel => 'Acepto los Términos de uso.';

  @override
  String get agreementPrivacyLabel => 'Acepto la Política de privacidad.';

  @override
  String get agreementTermsTitle => 'Términos de uso';

  @override
  String get agreementPrivacyTitle => 'Política de privacidad';

  @override
  String get agreementDetailsLink => 'Ver detalles';

  @override
  String get agreementButtonConfirm => 'Aceptar y continuar';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get restorePurchasesNothing => 'No hay compras para restaurar.';

  @override
  String get restorePurchasesCompleted => 'Se restauraron las compras.';

  @override
  String get settingsNotification => 'Notificaciones';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Nivel de inglés';

  @override
  String get pushNotifications => 'Notificaciones push';

  @override
  String get pushNotificationsDesc =>
      'Recibe recordatorios y actualizaciones importantes.';

  @override
  String get settingsFeedback => 'Comentarios';

  @override
  String get settingsAnnouncements => 'Anuncios';

  @override
  String get announcementsEmpty => 'Aún no hay anuncios';

  @override
  String get noticesEmpty => 'Aún no hay publicaciones';

  @override
  String get deletedPost => 'Esta publicación fue eliminada.';

  @override
  String get postNoLongerAvailable => 'Esta publicación ya no está disponible.';

  @override
  String get backToHome => 'Volver al inicio';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsFsdLaboratory => 'Laboratorio FSD';

  @override
  String get settingsPrivacy => 'Política de privacidad';

  @override
  String get settingsTerms => 'Términos del servicio';

  @override
  String get settingsOpenSource => 'Licencias de código abierto';

  @override
  String loginWelcome(String name) {
    return '¡Te damos la bienvenida, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Al continuar, aceptas los $terms y la $privacy.';
  }

  @override
  String get loginTermsTitle => 'Términos de uso';

  @override
  String get loginPrivacyTitle => 'Política de privacidad';

  @override
  String get loginCatchphrase => 'Empieza a hablar. Así es como se aprende.';

  @override
  String get loginWelcomeTitle => '¡Te damos la bienvenida a SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      '¡Entra en una historia y empieza a hablar inglés!';

  @override
  String get loginErrorIdToken =>
      'No se pudo obtener el token de ID de Google. Inténtalo de nuevo.';

  @override
  String loginErrorFailed(String error) {
    return 'Error de inicio de sesión: $error';
  }

  @override
  String get accountName => 'Nombre';

  @override
  String get accountInfo => 'Cuenta';

  @override
  String get accountDelete => 'Eliminar cuenta';

  @override
  String get accountDeleteTitle => '¿Eliminar la cuenta?';

  @override
  String get accountDeleteConfirmText =>
      'Todo tu progreso y tus datos se perderán permanentemente. ¿Confirmas que deseas continuar?';

  @override
  String get accountDeleteProfileImageTitle => '¿Eliminar la foto de perfil?';

  @override
  String get accountDeleteProfileImageContent =>
      'Una vez eliminada, tu foto de perfil no se podrá recuperar.';

  @override
  String get accountGoBack => 'Volver';

  @override
  String get accountDeleteAction => 'Eliminar';

  @override
  String get accountSubscription => 'Suscripción';

  @override
  String get accountFreePlanTitle => 'Plan gratuito';

  @override
  String get accountFreePlanSubtitle =>
      'Obtén Premium para desbloquear más funciones';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'Disfrutas de los beneficios Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get accountChangePlan => 'Cambiar plan';

  @override
  String get changePlanTitle => 'Cambiar plan';

  @override
  String get changePlanCurrentPlan => 'Plan actual';

  @override
  String get changePlanAvailablePlans => 'Planes disponibles';

  @override
  String changePlanRenewsOn(String date) {
    return 'Se renueva el $date';
  }

  @override
  String get changePlanLoadFailed =>
      'No se pudo cargar la información. Inténtalo de nuevo.';

  @override
  String get changePlanRetry => 'Volver a intentar';

  @override
  String get changePlanConfirmTitle => '¿Cambiar de plan?';

  @override
  String get changePlanConfirmBody =>
      'El cambio de plan entrará en vigor en tu próxima fecha de facturación.';

  @override
  String get changePlanConfirmOk => 'Confirmar';

  @override
  String get changePlanConfirmCancel => 'Conservar el plan actual';

  @override
  String get changePlanOldPurchaseMissing =>
      'No encontramos una suscripción activa que puedas cambiar. Inténtalo de nuevo cuando tu suscripción esté activa.';

  @override
  String get changePlanChangeRequested =>
      'Se solicitó el cambio de plan. Es posible que se aplique en tu próxima fecha de facturación.';

  @override
  String get cefrLevelTitle => 'Elige tu nivel de inglés';

  @override
  String get cefrLevelAbsoluteBeginner => 'Principiante absoluto';

  @override
  String get cefrLevelBeginner => 'Principiante';

  @override
  String get cefrLevelBasic => 'Básico';

  @override
  String get cefrLevelIntermediate => 'Intermedio';

  @override
  String get firstCefrLevelTitle => '¿Cuál es tu nivel de inglés?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Sé leer en inglés';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Conozco saludos básicos y expresiones sencillas';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Puedo usar y entender oraciones cortas y sencillas';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Puedo expresar mi opinión y participar en conversaciones cotidianas';

  @override
  String get firstCefrLevelSettingsHint =>
      'Puedes cambiarlo en cualquier momento';

  @override
  String get firstCefrLevelConfirm => 'Confirmar';

  @override
  String get feedbackPlaceholder =>
      'Comparte tus opiniones, sugerencias o cualquier problema que hayas encontrado...';

  @override
  String get feedbackSend => 'Enviar';

  @override
  String get feedbackSuccess => 'Gracias por tus comentarios.';

  @override
  String get microphonePermissionDenied =>
      'No se puede empezar sin permiso para usar el micrófono.';

  @override
  String get holdMicrophoneToSpeak =>
      'Mantén presionado el micrófono para hablar';

  @override
  String get roleplayTypeMessagePlaceholder => 'Escribe tu mensaje...';

  @override
  String get yourTurnFirst => '¡Tú empiezas!';

  @override
  String get sayLineBelowToStart => 'Di la frase de abajo para empezar.';

  @override
  String get roleplayExitWait => '¡Espera!';

  @override
  String get roleplayExitMessage =>
      'Si sales ahora, perderás tu recompensa. ¿Confirmas que deseas salir?';

  @override
  String get roleplayExitKeepPlaying => 'Seguir jugando';

  @override
  String get roleplayExitExit => 'Salir';

  @override
  String get roleplayAutoHint => 'Pista automática';

  @override
  String get roleplayHintLabel => 'Pista';

  @override
  String get roleplayHintShowAnswer =>
      'Toca para ver una respuesta sugerida en inglés';

  @override
  String get roleplayVoiceSpeed => 'Velocidad de voz';

  @override
  String get roleplayEndedFailed => 'Misión fallida...';

  @override
  String get roleplayEndedComplete => 'Juego de rol completado';

  @override
  String get roleplayEndedEnding => 'Pasando al desenlace...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Progreso insuficiente';

  @override
  String get roleplayFinishCompleted => 'Juego de rol completado';

  @override
  String get roleplayFinishMovingToEnding => 'Pasando al desenlace...';

  @override
  String get roleplayAnalyzing => 'Analizando tu juego de rol...';

  @override
  String get roleplayOpeningAiCharacter => 'Personaje de IA';

  @override
  String get roleplayOpeningScenario => 'Escenario';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'La IA puede cometer errores.\nNo compartas información personal ni sensible.';

  @override
  String get endingFailTitle => '¡No completaste todas las misiones!';

  @override
  String get endingFailSubtitle =>
      'Inténtalo de nuevo y descubre la historia completa.';

  @override
  String get roleplayTryAgainMessage =>
      'Lamentablemente, tu puntuación no fue suficiente para obtener la recompensa.';

  @override
  String get endingReport => 'Reportar un problema';

  @override
  String get endingHowWas => '¿Qué te pareció el juego de rol?';

  @override
  String get endingNext => 'Siguiente';

  @override
  String get reportTitle => 'Reportar un problema';

  @override
  String get profileHistory => 'Historial';

  @override
  String get profileSaved => 'Guardadas';

  @override
  String get profileHistoryEmpty => 'Aún no hay historial';

  @override
  String get profileSavedEmpty => 'Aún no hay expresiones guardadas.';

  @override
  String get profileSavedRemoveTitle => '¿Dejar de guardar esta expresión?';

  @override
  String get profileSavedRemoveContent =>
      'Puedes volver a encontrarla más tarde en el historial.';

  @override
  String get profileSavedRemoveOk => 'Quitar';

  @override
  String get profileSavedRemoveCancel => 'Practicar más';

  @override
  String get seriesOverviewTabEpisodes => 'Episodios';

  @override
  String get seriesOverviewTabSimilarTopic => 'Temas similares';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episodio #$number';
  }

  @override
  String get seriesOverviewPlay => 'Jugar';

  @override
  String get seriesOverviewLocked => 'Bloqueado';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Completa el episodio anterior para desbloquearlo.';

  @override
  String get notificationPermissionBlockedTitle =>
      'Las notificaciones están desactivadas';

  @override
  String get notificationPermissionBlockedMessage =>
      'Activa las notificaciones en la configuración de tu dispositivo para recibir notificaciones push.';

  @override
  String get openSettings => 'Abrir configuración';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Aún no hay notificaciones';

  @override
  String get notificationSendToday => 'Hoy';

  @override
  String get notificationSendOneDayAgo => 'Hace 1 día';

  @override
  String notificationSendDaysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Podrás volver a registrarte 2 días después de eliminar tu cuenta. Inténtalo de nuevo más tarde.';

  @override
  String get expressionSavedToProfile => 'Guardada en tu perfil';

  @override
  String get expressionUnsavedToProfile => 'Ya no está guardada';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Esta vez no pudimos darte comentarios. ¡Intenta responder con 7 palabras o más!';

  @override
  String get roleplayResultScoreMeaning => 'Significado';

  @override
  String get roleplayResultScoreRelevance => 'Relevancia';

  @override
  String get roleplayResultScoreVocabulary => 'Vocabulario';

  @override
  String get roleplayResultScoreGrammar => 'Gramática';

  @override
  String get closePopup => 'Cerrar';

  @override
  String get reviewChatTapHint =>
      'Toca la burbuja de chat para reproducir el audio.';

  @override
  String get reviewChatNoAudioToPlay => 'No hay audio para reproducir.';

  @override
  String get seriesInformationTopicDifficulty => 'Dificultad del tema';

  @override
  String get seriesInformationLearningGoals => 'Objetivos de aprendizaje';

  @override
  String get energyInfoTitle => 'Energía';

  @override
  String get energyOutOfEnergyTitle => 'Sin energía';

  @override
  String get energyInfoRechargeUntil => 'Próxima recarga en @@TIME@@';

  @override
  String get energyInfoFull => 'Tu energía está al máximo.';

  @override
  String get energyInfoUnlimitedEndsIn => 'Modo ilimitado activo';

  @override
  String get energyInsufficient => 'No tienes suficiente energía.';

  @override
  String get endRoleplay => 'Finalizar el juego de rol';

  @override
  String get energyEnablePushTitle => 'Activar notificaciones';

  @override
  String get energyEnablePushSubtitle =>
      'Activa las notificaciones y recarga por completo tu energía.';

  @override
  String get energyEnablePushPrice => 'Gratis';

  @override
  String get energyEnablePushOfferBadge => 'OFERTA POR ÚNICA VEZ';

  @override
  String get energyEnablePushCompleted => '¡Energía recargada!';

  @override
  String get energyPurchaseUnlimitedTitle => 'Pase ilimitado';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Comienza inmediatamente después de la compra. Válido durante 10 minutos.';

  @override
  String get energyPurchaseCapacityTitle => 'Aumento de energía máxima';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'Aumenta en 1 tu energía máxima recargable de forma permanente.';

  @override
  String get energyGoPremiumTitle => 'Obtén Premium';

  @override
  String get energyGoPremiumExplore => 'Explorar';

  @override
  String get profileGoPremiumTitle => 'Obtén SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Explorar';

  @override
  String get energyPurchasePendingApproval =>
      'Tu pago está pendiente de aprobación.';

  @override
  String get energyPurchaseNotCompleted => 'La compra no se completó.';

  @override
  String get iapPurchaseProcessing => 'Tu compra se está procesando.';

  @override
  String get iapPurchaseCompleted => 'Compra completada.';

  @override
  String get welcomeGiftTitle => '¡Llegó tu regalo de bienvenida!';

  @override
  String get welcomeGiftBenefitLead => '¡Juega sin límites durante 10 minutos!';

  @override
  String get welcomeGiftLine2 => 'Funciones Premium desbloqueadas';

  @override
  String get welcomeGiftLine3 => 'Modo ilimitado desbloqueado';

  @override
  String get welcomeGiftStartNow => 'Empezar ahora';

  @override
  String get paywallHeroTitle1 => 'Practica más';

  @override
  String get paywallHeroTitle2 => 'Mejora más rápido';

  @override
  String get paywallHeroBody =>
      'Practica por más tiempo con Premium y recibe comentarios de la IA para ganar confianza al hablar inglés.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Más práctica diaria';

  @override
  String get paywallBenefitMaxEnergy => 'Hasta 30 puntos de energía';

  @override
  String get paywallBenefitAiFeedback =>
      'Comentarios de la IA sobre tus frases';

  @override
  String get paywallChoosePlan => 'Elige tu plan';

  @override
  String get paywallAnnualPlanTitle => 'Plan anual';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Ahorra más del 33% en comparación con el plan mensual.';

  @override
  String get paywallMonthlyPlanTitle => 'Plan mensual';

  @override
  String get paywallMonthlyPlanSubtitle => 'Acceso mensual flexible.';

  @override
  String get paywallBestBadge => 'MEJOR';

  @override
  String get paywallCta => 'Empezar ahora';

  @override
  String get paywallAutoRenewNotice =>
      'Las suscripciones se renuevan automáticamente, a menos que se cancelen al menos 24 horas antes de que finalice el período de facturación actual.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/mes';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/año';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => '¡Felicidades!';

  @override
  String get paywallCompletedBody => 'Tus beneficios Premium ya están activos.';

  @override
  String get paywallCompletedContinue => 'Continuar';

  @override
  String get roleplayChooseYourRole => 'Elige tu papel';

  @override
  String get roleplaySimilarRoleplays => 'Roleplays similares';

  @override
  String get roleplayBeingPrepared => 'Este roleplay se está preparando.';

  @override
  String get roleplayUnlockPreviousRole =>
      'Completa todos los finales del papel anterior para desbloquear este papel.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% completado';
  }

  @override
  String get roleplayTurnGradeA => '¡guau!';

  @override
  String get roleplayTurnGradeB => 'ok!';

  @override
  String get roleplayTurnGradeC => 'hmm…';

  @override
  String get roleplayTurnGradeD => 'oh…';

  @override
  String get tutorialPage1Title =>
      'Revisa tu **Misión**\ny empieza la conversación.';

  @override
  String get tutorialPage1Tip =>
      '*Consejo: ¡Cuanto más natural hables,\nmayor será tu recompensa!';

  @override
  String get tutorialPage2Title =>
      '¡Usa el **Traductor**\ncuando no entiendas!';

  @override
  String get tutorialPage3Title => 'Usa una **Pista**\ncuando te trabes.';

  @override
  String get tutorialPage3Subtitle =>
      'Puedes activar o desactivar\nlas pistas automáticas cuando quieras.';

  @override
  String get tutorialPage4Title =>
      'Si la pronunciación es difícil,\nescucha primero y luego repite.';

  @override
  String get tutorialPage4Tip =>
      '*Consejo: Intenta responder sin mirar la traducción\npara obtener una puntuación más alta.';

  @override
  String get tutorialPage5Title => '¿No puedes hablar\nen voz alta?';

  @override
  String get tutorialPage5Subtitle => 'Cambia al **Modo texto**.';

  @override
  String get tutorialPage6Title => 'Nadie te está juzgando.\n¡Tú puedes!';
}
