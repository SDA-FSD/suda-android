// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get agreementHeading => '続行するには、以下の内容を確認して同意してください。';

  @override
  String get agreementTermsLabel => '利用規約に同意します。';

  @override
  String get agreementPrivacyLabel => 'プライバシーポリシーに同意します。';

  @override
  String get agreementTermsTitle => '利用規約';

  @override
  String get agreementPrivacyTitle => 'プライバシーポリシー';

  @override
  String get agreementDetailsLink => '詳細を見る';

  @override
  String get agreementButtonConfirm => '同意して続ける';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsRestorePurchases => '購入を復元';

  @override
  String get restorePurchasesNothing => '復元できる購入項目がありません。';

  @override
  String get restorePurchasesCompleted => '購入を復元しました。';

  @override
  String get settingsNotification => '通知';

  @override
  String get settingsTutorial => 'チュートリアル';

  @override
  String get settingsCefrLevel => '英語レベル';

  @override
  String get pushNotifications => 'プッシュ通知';

  @override
  String get pushNotificationsDesc => 'リマインダーや重要なお知らせを受け取ります。';

  @override
  String get settingsFeedback => 'ご意見・ご要望';

  @override
  String get settingsAnnouncements => 'お知らせ';

  @override
  String get announcementsEmpty => 'まだお知らせはありません';

  @override
  String get noticesEmpty => 'まだ投稿はありません';

  @override
  String get deletedPost => 'この投稿は削除されました。';

  @override
  String get postNoLongerAvailable => 'この投稿は現在ご覧いただけません。';

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String get settingsSignOut => 'ログアウト';

  @override
  String get settingsFsdLaboratory => 'FSDラボ';

  @override
  String get settingsPrivacy => 'プライバシーポリシー';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsOpenSource => 'オープンソースライセンス';

  @override
  String loginWelcome(String name) {
    return '$nameさん、ようこそ！';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return '続行すると、$termsおよび$privacyに同意したものとみなされます。';
  }

  @override
  String get loginTermsTitle => '利用規約';

  @override
  String get loginPrivacyTitle => 'プライバシーポリシー';

  @override
  String get loginCatchphrase => '話してみましょう。そこから学びが始まります。';

  @override
  String get loginWelcomeTitle => 'SUDAへようこそ！';

  @override
  String get loginWelcomeSubtitle => '物語の中に入り、英語を話してみましょう！';

  @override
  String get loginErrorIdToken => 'Google ID トークンを取得できませんでした。もう一度お試しください。';

  @override
  String loginErrorFailed(String error) {
    return 'ログインに失敗しました：$error';
  }

  @override
  String get accountName => '名前';

  @override
  String get accountInfo => 'アカウント';

  @override
  String get accountDelete => 'アカウントを削除';

  @override
  String get accountDeleteTitle => 'アカウントを削除しますか？';

  @override
  String get accountDeleteConfirmText =>
      'すべての進捗状況とデータが永久に削除され、復元できません。本当に削除しますか？';

  @override
  String get accountDeleteProfileImageTitle => 'プロフィール画像を削除しますか？';

  @override
  String get accountDeleteProfileImageContent => '一度削除すると、プロフィール画像は復元できません。';

  @override
  String get accountGoBack => '戻る';

  @override
  String get accountDeleteAction => '削除';

  @override
  String get accountSubscription => '定期購入';

  @override
  String get accountFreePlanTitle => '無料プラン';

  @override
  String get accountFreePlanSubtitle => 'プレミアムに登録して、さらに多くの機能を利用しましょう';

  @override
  String get accountPremiumTitle => 'プレミアム';

  @override
  String get accountPremiumSubtitle => 'プレミアム特典をご利用中です';

  @override
  String accountPremiumRenewsOn(String date) {
    return '次回更新日：$date';
  }

  @override
  String get accountChangePlan => 'プランを変更';

  @override
  String get changePlanTitle => 'プランを変更';

  @override
  String get changePlanCurrentPlan => '現在のプラン';

  @override
  String get changePlanAvailablePlans => '利用可能なプラン';

  @override
  String changePlanRenewsOn(String date) {
    return '次回更新日：$date';
  }

  @override
  String get changePlanLoadFailed => '情報を読み込めませんでした。もう一度お試しください。';

  @override
  String get changePlanRetry => '再試行';

  @override
  String get changePlanConfirmTitle => 'プランを変更しますか？';

  @override
  String get changePlanConfirmBody => 'プランの変更は次回の請求日に適用されます。';

  @override
  String get changePlanConfirmOk => '変更を確定';

  @override
  String get changePlanConfirmCancel => '現在のプランを継続';

  @override
  String get changePlanOldPurchaseMissing =>
      '変更対象の有効な定期購入が見つかりません。定期購入が有効になってから、もう一度お試しください。';

  @override
  String get changePlanChangeRequested => 'プラン変更を受け付けました。次回の請求日に適用される場合があります。';

  @override
  String get cefrLevelTitle => '英語レベルを選択してください';

  @override
  String get cefrLevelAbsoluteBeginner => '超入門';

  @override
  String get cefrLevelBeginner => '入門';

  @override
  String get cefrLevelBasic => '初級';

  @override
  String get cefrLevelIntermediate => '中級';

  @override
  String get firstCefrLevelTitle => 'あなたの英語レベルは？';

  @override
  String get firstCefrLevelDescriptionPreA1 => '英語の文字が読めます';

  @override
  String get firstCefrLevelDescriptionA1 => '基本的なあいさつや簡単な表現がわかります';

  @override
  String get firstCefrLevelDescriptionA2 => '短く簡単な文を理解して使えます';

  @override
  String get firstCefrLevelDescriptionB1 => '自分の意見を伝え、日常会話に参加できます';

  @override
  String get firstCefrLevelSettingsHint => 'いつでも変更できます';

  @override
  String get firstCefrLevelConfirm => '決定';

  @override
  String get feedbackPlaceholder => 'ご意見、ご要望、お困りの点などをお聞かせください…';

  @override
  String get feedbackSend => '送信';

  @override
  String get feedbackSuccess => 'ご意見をお寄せいただきありがとうございます。';

  @override
  String get microphonePermissionDenied => 'マイクの使用を許可しないと開始できません。';

  @override
  String get holdMicrophoneToSpeak => 'マイクボタンを長押しして話す';

  @override
  String get roleplayTypeMessagePlaceholder => 'メッセージを入力…';

  @override
  String get yourTurnFirst => 'あなたから始めましょう！';

  @override
  String get sayLineBelowToStart => '下のフレーズを話して始めましょう。';

  @override
  String get roleplayExitWait => 'ちょっと待って！';

  @override
  String get roleplayExitMessage => '今終了すると、報酬を獲得できません。本当に終了しますか？';

  @override
  String get roleplayExitKeepPlaying => '続ける';

  @override
  String get roleplayExitExit => '終了';

  @override
  String get roleplayAutoHint => 'ヒントを自動表示';

  @override
  String get roleplayHintLabel => 'ヒント';

  @override
  String get roleplayHintShowAnswer => 'タップして英語の回答例を見る';

  @override
  String get roleplayVoiceSpeed => '音声速度';

  @override
  String get roleplayEndedFailed => 'ミッション失敗…';

  @override
  String get roleplayEndedComplete => 'ロールプレイ完了';

  @override
  String get roleplayEndedEnding => 'エンディングへ移動中…';

  @override
  String get roleplayFinishNotEnoughProgress => '進行度が足りません';

  @override
  String get roleplayFinishCompleted => 'ロールプレイ完了';

  @override
  String get roleplayFinishMovingToEnding => 'エンディングへ移動中…';

  @override
  String get roleplayAnalyzing => 'ロールプレイを分析しています…';

  @override
  String get roleplayOpeningAiCharacter => 'AIキャラクター';

  @override
  String get roleplayOpeningScenario => 'シナリオ';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'AIは間違えることがあります。\n個人情報や機密性の高い情報を共有しないでください。';

  @override
  String get endingFailTitle => 'すべてのミッションをクリアできませんでした！';

  @override
  String get endingFailSubtitle => 'もう一度挑戦して、物語の全貌を明らかにしましょう。';

  @override
  String get roleplayTryAgainMessage => '残念ながら、スコアが足りず報酬を獲得できませんでした。';

  @override
  String get endingReport => '問題を報告';

  @override
  String get endingHowWas => 'ロールプレイはいかがでしたか？';

  @override
  String get endingNext => '次へ';

  @override
  String get reportTitle => '問題を報告';

  @override
  String get profileHistory => '履歴';

  @override
  String get profileSaved => '保存済み';

  @override
  String get profileHistoryEmpty => 'まだ履歴はありません';

  @override
  String get profileSavedEmpty => 'まだ保存した表現はありません。';

  @override
  String get profileSavedRemoveTitle => '保存済みから削除しますか？';

  @override
  String get profileSavedRemoveContent => '後で履歴からもう一度見つけられます。';

  @override
  String get profileSavedRemoveOk => '削除';

  @override
  String get profileSavedRemoveCancel => 'もっと練習する';

  @override
  String get seriesOverviewTabEpisodes => 'エピソード';

  @override
  String get seriesOverviewTabSimilarTopic => '関連トピック';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'エピソード #$number';
  }

  @override
  String get seriesOverviewPlay => 'プレイ';

  @override
  String get seriesOverviewLocked => 'ロック中';

  @override
  String get seriesOverviewEpisodeLockedToast => '前のエピソードをクリアするとロックが解除されます。';

  @override
  String get notificationPermissionBlockedTitle => '通知がオフになっています';

  @override
  String get notificationPermissionBlockedMessage =>
      'プッシュ通知を受け取るには、端末の設定で通知を有効にしてください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmpty => 'まだ通知はありません';

  @override
  String get notificationSendToday => '今日';

  @override
  String get notificationSendOneDayAgo => '1日前';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'アカウント削除後2日間は再登録できません。しばらくしてからもう一度お試しください。';

  @override
  String get expressionSavedToProfile => 'プロフィールに保存しました';

  @override
  String get expressionUnsavedToProfile => '保存を解除しました';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      '今回はフィードバックを作成できませんでした。英語で7語以上になるよう、もう少し長く答えてみましょう！';

  @override
  String get roleplayResultScoreMeaning => '意味';

  @override
  String get roleplayResultScoreRelevance => '関連性';

  @override
  String get roleplayResultScoreVocabulary => '語彙';

  @override
  String get roleplayResultScoreGrammar => '文法';

  @override
  String get closePopup => '閉じる';

  @override
  String get reviewChatTapHint => '吹き出しをタップすると音声が再生されます。';

  @override
  String get reviewChatNoAudioToPlay => '再生できる音声がありません。';

  @override
  String get seriesInformationTopicDifficulty => 'トピックの難易度';

  @override
  String get seriesInformationLearningGoals => '学習目標';

  @override
  String get energyInfoTitle => 'エネルギー';

  @override
  String get energyOutOfEnergyTitle => 'エネルギーがありません';

  @override
  String get energyInfoRechargeUntil => '次の回復まで @@TIME@@';

  @override
  String get energyInfoFull => 'エネルギーは満タンです。';

  @override
  String get energyInfoUnlimitedEndsIn => '無制限モード利用中';

  @override
  String get energyInsufficient => 'エネルギーが足りません。';

  @override
  String get endRoleplay => 'ロールプレイを終了';

  @override
  String get energyEnablePushTitle => '通知をオンにする';

  @override
  String get energyEnablePushSubtitle => '通知をオンにして、エネルギーを全回復しましょう。';

  @override
  String get energyEnablePushPrice => '無料';

  @override
  String get energyEnablePushOfferBadge => '1回限りの特典';

  @override
  String get energyEnablePushCompleted => 'エネルギーが全回復しました！';

  @override
  String get energyPurchaseUnlimitedTitle => '無制限パス';

  @override
  String get energyPurchaseUnlimitedSubtitle => '購入後すぐに開始し、10分間有効です。';

  @override
  String get energyPurchaseCapacityTitle => '最大エネルギーを増やす';

  @override
  String get energyPurchaseCapacitySubtitle => '回復できるエネルギーの上限が恒久的に1増えます。';

  @override
  String get energyGoPremiumTitle => 'プレミアムに登録';

  @override
  String get energyGoPremiumExplore => '詳細を見る';

  @override
  String get profileGoPremiumTitle => 'SUDAプレミアムに登録';

  @override
  String get profileGoPremiumExplore => '詳細を見る';

  @override
  String get energyPurchasePendingApproval => 'お支払いは承認待ちです。';

  @override
  String get energyPurchaseNotCompleted => '購入は完了していません。';

  @override
  String get iapPurchaseProcessing => '購入を処理しています。';

  @override
  String get iapPurchaseCompleted => '購入が完了しました。';

  @override
  String get welcomeGiftTitle => 'ようこそ！プレゼントが届きました';

  @override
  String get welcomeGiftBenefitLead => '10分間、回数を気にせず楽しめます！';

  @override
  String get welcomeGiftLine2 => 'プレミアム機能を利用できます';

  @override
  String get welcomeGiftLine3 => '無制限プレイを利用できます';

  @override
  String get welcomeGiftStartNow => '今すぐ始める';

  @override
  String get paywallHeroTitle1 => 'もっと練習して';

  @override
  String get paywallHeroTitle2 => 'もっと早く\n上達';

  @override
  String get paywallHeroBody => 'プレミアムなら長く練習でき、AIのフィードバックで英語への自信を育てられます。';

  @override
  String get paywallPremiumLabel => 'プレミアム';

  @override
  String get paywallBenefitMaxEnergy => '最大エネルギー30';

  @override
  String get paywallBenefitAiFeedback => 'AIによる英文フィードバック';

  @override
  String get paywallBenefitProfileBadge => 'プレミアムプロフィールバッジ';

  @override
  String get paywallChoosePlan => 'プランを選択';

  @override
  String get paywallAnnualPlanTitle => '年間プラン';

  @override
  String get paywallAnnualPlanSubtitle => '月間プランより33%以上お得です。';

  @override
  String get paywallMonthlyPlanTitle => '月間プラン';

  @override
  String get paywallMonthlyPlanSubtitle => '月ごとに気軽に利用できます。';

  @override
  String get paywallBestBadge => 'おすすめ';

  @override
  String get paywallCta => '今すぐ始める';

  @override
  String get paywallAutoRenewNotice =>
      '定期購入は、現在の請求期間が終了する24時間以上前までに解約しない限り、自動的に更新されます。';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/月';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/年';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '¥1,492';

  @override
  String get paywallFallbackAnnual => '¥17,900';

  @override
  String get paywallFallbackMonthly => '¥2,500';

  @override
  String get paywallFallbackMonthlyTimes12 => '¥30,000';

  @override
  String get paywallCompletedTitle => 'おめでとうございます！';

  @override
  String get paywallCompletedBody => 'プレミアム特典が有効になりました。';

  @override
  String get paywallCompletedContinue => '続ける';

  @override
  String get roleplayChooseYourRole => '役割を選んでください';

  @override
  String get roleplaySimilarRoleplays => '似たロールプレイ';

  @override
  String get roleplayBeingPrepared => 'このロールプレイは準備中です。';

  @override
  String get roleplayUnlockPreviousRole =>
      'この役割のロックを解除するには、前の役割のエンディングをすべて完了してください。';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '$percent% 完了';
  }

  @override
  String get roleplayTurnGradeA => 'すごい!';

  @override
  String get roleplayTurnGradeB => 'OK!';

  @override
  String get roleplayTurnGradeC => 'うーん…';

  @override
  String get roleplayTurnGradeD => 'おっ…';

  @override
  String get tutorialPage1Title => '**ミッション**を確認して\n会話を始めましょう。';

  @override
  String get tutorialPage1Tip => '*Tip: 自然に話すほど、\n報酬が大きくなります！';

  @override
  String get tutorialPage2Title => 'わからないときは\n**翻訳**を使いましょう。';

  @override
  String get tutorialPage3Title => '行き詰まったら\n**ヒント**を見て話してみましょう。';

  @override
  String get tutorialPage3Subtitle => '自動ヒントはいつでも\nオン/オフできます。';

  @override
  String get tutorialPage4Title => '発音が難しいときは、\nまず聞いてから繰り返しましょう。';

  @override
  String get tutorialPage4Tip => '*Tip: 翻訳を見ずに答えると、\nより高いスコアを獲得できます。';

  @override
  String get tutorialPage5Title => '声に出して\n話せないときは？';

  @override
  String get tutorialPage5Subtitle => '**テキストモード**に\n切り替えてください。';

  @override
  String get tutorialPage6Title => '誰もジャッジしません。\n自信を持って！';
}
