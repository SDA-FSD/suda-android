// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get agreementHeading =>
      'Para utilizar o serviço, concorde com os itens abaixo.';

  @override
  String get agreementTermsLabel => 'Concordo com os Termos de Uso.';

  @override
  String get agreementPrivacyLabel => 'Concordo com a Política de Privacidade.';

  @override
  String get agreementTermsTitle => 'Termos de Uso';

  @override
  String get agreementPrivacyTitle => 'Política de Privacidade';

  @override
  String get agreementDetailsLink => 'Ver detalhes';

  @override
  String get agreementButtonConfirm => 'Concordar e continuar';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsNotification => 'Notificações';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsCefrLevel => 'Nível de Idioma';

  @override
  String get pushNotifications => 'Notificações push';

  @override
  String get pushNotificationsDesc =>
      'Receba lembretes e atualizações importantes.';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsAnnouncements => 'Avisos';

  @override
  String get announcementsEmpty => 'Nenhum aviso ainda';

  @override
  String get noticesEmpty => 'Ainda não há publicações.';

  @override
  String get deletedPost => 'Esta publicação foi excluída.';

  @override
  String get postNoLongerAvailable =>
      'Esta publicação não está mais disponível.';

  @override
  String get backToHome => 'Ir para o Início';

  @override
  String get settingsSignOut => 'Sair';

  @override
  String get settingsFsdLaboratory => 'Laboratório FSD';

  @override
  String get settingsPrivacy => 'Política de Privacidade';

  @override
  String get settingsTerms => 'Termos de Serviço';

  @override
  String get settingsOpenSource => 'Licenças de Código Aberto';

  @override
  String loginWelcome(String name) {
    return 'Bem-vindo, $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'Ao continuar, você concorda com nossos $terms e $privacy.';
  }

  @override
  String get loginTermsTitle => 'Termos de Uso';

  @override
  String get loginPrivacyTitle => 'Política de Privacidade';

  @override
  String get loginCatchphrase => 'É conversando que se aprende.';

  @override
  String get loginWelcomeTitle => 'Bem-vindo ao SUDA!';

  @override
  String get loginWelcomeSubtitle =>
      'Entre numa história e saia falando inglês!';

  @override
  String get loginErrorIdToken =>
      'Falha ao obter o Token de ID do Google. Por favor, tente novamente.';

  @override
  String loginErrorFailed(String error) {
    return 'Falha no login: $error';
  }

  @override
  String get accountName => 'Nome';

  @override
  String get accountInfo => 'Conta';

  @override
  String get accountDelete => 'Excluir Conta';

  @override
  String get accountDeleteTitle => 'Excluir conta?';

  @override
  String get accountDeleteConfirmText =>
      'Todos os seus progressos e dados serão perdidos permanentemente. Tem certeza?';

  @override
  String get accountDeleteProfileImageTitle => 'Excluir imagem de perfil?';

  @override
  String get accountDeleteProfileImageContent =>
      'Depois de excluída, sua imagem de perfil não poderá ser recuperada.';

  @override
  String get accountGoBack => 'Voltar';

  @override
  String get accountDeleteAction => 'Excluir';

  @override
  String get accountSubscription => 'Assinatura';

  @override
  String get accountFreePlanTitle => 'Plano Gratuito';

  @override
  String get accountFreePlanSubtitle =>
      'Assine o Premium para desbloquear mais recursos';

  @override
  String get cefrLevelTitle => 'Escolha seu nível de inglês';

  @override
  String get cefrLevelAbsoluteBeginner => 'Iniciante Absoluto';

  @override
  String get cefrLevelBeginner => 'Iniciante';

  @override
  String get cefrLevelBasic => 'Básico';

  @override
  String get cefrLevelIntermediate => 'Intermediário';

  @override
  String get firstCefrLevelTitle => 'Qual é o seu nível de Inglês?';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'Sei ler em inglês';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'Sei cumprimentos básicos e frases simples';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'Consigo entender e usar frases curtas e simples';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'Consigo expressar minha opinião e participar de conversas do dia a dia';

  @override
  String get firstCefrLevelSettingsHint => 'Você pode mudar a qualquer momento';

  @override
  String get firstCefrLevelConfirm => 'Confirmar';

  @override
  String get feedbackPlaceholder =>
      'Compartilhe seus pensamentos, sugestões ou problemas que você encontrou...';

  @override
  String get feedbackSend => 'Enviar';

  @override
  String get feedbackSuccess => 'Obrigado pelo seu feedback.';

  @override
  String get microphonePermissionDenied =>
      'Não é possível iniciar sem permissão do microfone.';

  @override
  String get holdMicrophoneToSpeak => 'Segure o microfone para falar';

  @override
  String get roleplayTypeMessagePlaceholder => 'Digite sua resposta…';

  @override
  String get yourTurnFirst => 'É sua vez primeiro!';

  @override
  String get sayLineBelowToStart => 'Diga a frase abaixo para começar.';

  @override
  String get roleplayExitWait => 'Segura aí!';

  @override
  String get roleplayExitMessage =>
      'Se sair agora, perderá sua recompensa. Tem certeza de que deseja sair?';

  @override
  String get roleplayExitKeepPlaying => 'Continuar Jogando';

  @override
  String get roleplayExitExit => 'Sair';

  @override
  String get roleplayAutoHint => 'Auto Dica';

  @override
  String get roleplayHintLabel => 'Dica';

  @override
  String get roleplayHintShowAnswer => 'Ver resposta';

  @override
  String get roleplayVoiceSpeed => 'Velocidade da Voz';

  @override
  String get roleplayEndedFailed => 'Missão falhou...';

  @override
  String get roleplayEndedComplete => 'Roleplay concluído';

  @override
  String get roleplayEndedEnding => 'Indo para o final em breve...';

  @override
  String get roleplayFinishNotEnoughProgress => 'Progresso insuficiente';

  @override
  String get roleplayFinishCompleted => 'Roleplay concluído';

  @override
  String get roleplayFinishMovingToEnding => 'Finalizando...';

  @override
  String get roleplayAnalyzing => 'Analisando seu roleplay...';

  @override
  String get roleplayOpeningAiCharacter => 'Personagem IA';

  @override
  String get roleplayOpeningScenario => 'Cenário';

  @override
  String get endingFailTitle => 'Você não completou todas as missões!';

  @override
  String get endingFailSubtitle =>
      'Tente novamente para descobrir a história completa.';

  @override
  String get roleplayTryAgainMessage =>
      'Que pena! Sua pontuação foi baixa demais para ganhar a recompensa.';

  @override
  String get endingReport => 'Reportar problema';

  @override
  String get endingHowWas => 'Como foi o Roleplay?';

  @override
  String get endingNext => 'Próximo';

  @override
  String get reportTitle => 'Relatar Problema';

  @override
  String get profileHistory => 'Histórico';

  @override
  String get profileSaved => 'Salvos';

  @override
  String get profileHistoryEmpty => 'Ainda sem histórico';

  @override
  String get profileSavedEmpty => 'Nenhuma expressão salva ainda.';

  @override
  String get profileSavedRemoveTitle => 'Remover dos Salvos?';

  @override
  String get profileSavedRemoveContent =>
      'Você pode encontrá-la novamente no Histórico e salvá-la.';

  @override
  String get profileSavedRemoveOk => 'Remover';

  @override
  String get profileSavedRemoveCancel => 'Manter salvo';

  @override
  String get seriesOverviewTabEpisodes => 'Episódio';

  @override
  String get seriesOverviewTabSimilarTopic => 'Tópico Semelhante';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'Episódio #$number';
  }

  @override
  String get seriesOverviewPlay => 'Play';

  @override
  String get seriesOverviewLocked => 'Locked';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'Complete o episódio anterior para desbloquear.';

  @override
  String get notificationPermissionBlockedTitle => 'Notificações desativadas';

  @override
  String get notificationPermissionBlockedMessage =>
      'Ative as notificações nas configurações do dispositivo para receber notificações push.';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String get notificationsEmpty => 'Ainda não há notificações';

  @override
  String get notificationSendToday => 'Hoje';

  @override
  String get notificationSendOneDayAgo => 'há 1 dia';

  @override
  String notificationSendDaysAgo(int count) {
    return 'há $count dias';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'Você poderá se cadastrar novamente 2 dias após excluir sua conta. Tente novamente mais tarde.';

  @override
  String get expressionSavedToProfile => 'Salvo no seu Perfil';

  @override
  String get expressionUnsavedToProfile => 'Desmarcado';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'Não foi possível fornecer feedback desta vez. Tente falar um pouco mais — procure usar mais de 7 palavras.';

  @override
  String get roleplayResultScoreMeaning => 'Significado';

  @override
  String get roleplayResultScoreRelevance => 'Relevância';

  @override
  String get roleplayResultScoreVocabulary => 'Vocabulário';

  @override
  String get roleplayResultScoreGrammar => 'Gramática';

  @override
  String get closePopup => 'Fechar';

  @override
  String get reviewChatTapHint =>
      'Toque no balão de chat para reproduzir o áudio.';

  @override
  String get reviewChatNoAudioToPlay => 'Não há áudio para reproduzir.';

  @override
  String get seriesInformationTopicDifficulty => 'Dificuldade do Tópico';

  @override
  String get seriesInformationLearningGoals => 'Metas de aprendizado';

  @override
  String get energyInfoTitle => 'Energia';

  @override
  String get energyOutOfEnergyTitle => 'Sem energia';

  @override
  String get energyInfoRechargeUntil =>
      'Faltam @@TIME@@ para a próxima recarga!';

  @override
  String get energyInfoFull => 'Sua energia está cheia.';

  @override
  String get energyInfoUnlimitedEndsIn =>
      'Modo Temporariamente Ilimitado Ativo';

  @override
  String get energyInsufficient => 'Você não tem energia suficiente.';

  @override
  String get endRoleplay => 'Encerrar roleplay';

  @override
  String get energyPurchaseUnlimitedTitle => 'Passe Temporariamente Ilimitado';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'Ativado imediatamente após a compra. Válido por 10 minutos.';

  @override
  String get energyPurchaseCapacityTitle => 'Upgrade de Energia Máxima';

  @override
  String get energyPurchaseCapacitySubtitle =>
      '+1 de Energia Máxima recarregável para sempre.';

  @override
  String get energyGoPremiumTitle => 'Seja Premium';

  @override
  String get energyGoPremiumExplore => 'Explorar';

  @override
  String get profileGoPremiumTitle => 'Assine o SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'Explorar';

  @override
  String get energyPurchasePendingApproval => 'Seu pagamento está pendente.';

  @override
  String get energyPurchaseNotCompleted => 'A compra não foi concluída.';

  @override
  String get welcomeGiftTitle => 'Tem um presente de boas-vindas para você!';

  @override
  String get welcomeGiftBenefitLead => 'Aproveite grátis por 10 minutos!';

  @override
  String get welcomeGiftLine2 => 'Recursos Premium liberados';

  @override
  String get welcomeGiftLine3 => 'Jogo Ilimitado liberado';

  @override
  String get welcomeGiftStartNow => 'Começar Agora';

  @override
  String get paywallHeroTitle1 => 'Pratique Mais';

  @override
  String get paywallHeroTitle2 => 'Aprenda Conversando';

  @override
  String get paywallHeroBody =>
      'Pratique por mais tempo com o Premium e receba feedback da IA para evoluir no inglês.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'Mais prática todos os dias';

  @override
  String get paywallBenefitMaxEnergy => 'Energia máxima de 30';

  @override
  String get paywallBenefitAiFeedback => 'Feedback da IA sobre frases';

  @override
  String get paywallChoosePlan => 'Escolha seu plano';

  @override
  String get paywallAnnualPlanTitle => 'Plano Anual';

  @override
  String get paywallAnnualPlanSubtitle =>
      'Economize 33% em relação ao plano mensal.';

  @override
  String get paywallMonthlyPlanTitle => 'Plano Mensal';

  @override
  String get paywallMonthlyPlanSubtitle => 'Acesso mensal com flexibilidade.';

  @override
  String get paywallBestBadge => 'MELHOR';

  @override
  String get paywallCta => 'Assinar agora';

  @override
  String get paywallAutoRenewNotice =>
      'A assinatura é renovada automaticamente, a menos que seja cancelada com pelo menos 24 horas de antecedência do fim do período de cobrança atual.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/mês';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/ano';
  }

  @override
  String get paywallFallbackAnnualPerMonth => 'R\$16,66';

  @override
  String get paywallFallbackAnnual => 'R\$199,99';

  @override
  String get paywallFallbackMonthly => 'R\$24,99';

  @override
  String get paywallCompletedTitle => 'Parabéns!';

  @override
  String get paywallCompletedBody => 'Seus benefícios Premium já estão ativos.';

  @override
  String get paywallCompletedContinue => 'Continuar';
}
