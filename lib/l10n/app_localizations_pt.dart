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
  String get settingsLanguageLevel => 'Nível de Idioma';

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
  String get languageLevelTitle => 'Escolha seu nível de inglês';

  @override
  String get languageLevelDescription =>
      'Em SUDA, todos falarão com você no seu nível de inglês.';

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
  String get roleplayEndedFailed => 'Missão falhou...';

  @override
  String get roleplayEndedComplete => 'Roleplay concluído';

  @override
  String get roleplayEndedEnding => 'Indo para o final em breve...';

  @override
  String get roleplayAnalyzing => 'Analisando seu roleplay...';

  @override
  String get endingFailTitle => 'Você não completou todas as missões!';

  @override
  String get endingFailSubtitle =>
      'Tente novamente para descobrir a história completa.';

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
  String get noTicketsTitle => 'Acabou seus Tickets…';

  @override
  String get noTicketsBody => 'Você atingiu seu limite do dia.\nVolte Amanhã!';

  @override
  String get surveyPromptLine1 => 'Você atingiu seu limite do dia.';

  @override
  String get surveyPromptLine2 =>
      'Responda uma pergunta rapidamente para ganhar um Ticket!';

  @override
  String get pushTicketPromptLine2 =>
      'Ative as notificações e ganhe 1 ticket extra!';

  @override
  String get surveyAnswerNowButton => 'Responder agora!✅';

  @override
  String get pushTicketTurnOnButton => 'Ativar 🔔';

  @override
  String get shareTicketPromptLine2 =>
      'Compartilhe o Aplicativo com um amigo e receba 1 Ticket extra!';

  @override
  String get shareTicketButton => 'Compartilhar link';

  @override
  String get reviewTicketPromptLine2 =>
      'Deixe sua avaliação e receba 1 Ticket extra!';

  @override
  String get reviewTicketButton => 'Avaliar';

  @override
  String get surveyMaybeLater => 'Talvez depois';

  @override
  String get surveyStep1Title => 'Selecione sua faixa etária.';

  @override
  String get surveyStep2Title => 'Qual é o seu gênero?';

  @override
  String get surveyStep3Title => 'Como você conheceu a SUDA?';

  @override
  String get surveyGenderFemale => 'Feminino';

  @override
  String get surveyGenderMale => 'Masculino';

  @override
  String get surveyGenderPreferNotToSay => 'Prefiro não informar';

  @override
  String get surveySuccessToast => 'Ganhou um Ticket! 🎉';

  @override
  String get dailyTicketTitle => 'Obrigado por fazer check-in!';

  @override
  String get dailyTicketContent =>
      'Resgate seu ingresso grátis diário!\nEle desaparecerá se você não usar hoje.';

  @override
  String get dailyTicketButton => 'Resgatar ingresso';

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
      'Não foi possível fornecer feedback desta vez. Tente falar um pouco mais — procure usar mais de 30 palavras.';
}
