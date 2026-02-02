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
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsLanguageLevel => 'Nível de Idioma';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsSignOut => 'Sair';

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
  String get roleplayEndedTimesup => 'O tempo acabou...';

  @override
  String get roleplayEndedComplete => 'Roleplay concluído';

  @override
  String get roleplayEndedEnding => 'Indo para o final em breve...';

  @override
  String get endingFailTitle => 'Você não completou todas as missões!';

  @override
  String get endingFailSubtitle =>
      'Tente novamente para descobrir a história completa.';

  @override
  String get endingReport => 'Relatório';

  @override
  String get endingHowWas => 'Como foi o Roleplay?';

  @override
  String get endingNext => 'Próximo';

  @override
  String get reportTitle => 'Relatar Problema';
}
