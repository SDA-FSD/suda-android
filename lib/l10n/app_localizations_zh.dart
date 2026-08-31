// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get agreementHeading => '请查看并同意以下条款后继续。';

  @override
  String get agreementTermsLabel => '我同意《用户协议》。';

  @override
  String get agreementPrivacyLabel => '我同意《隐私政策》。';

  @override
  String get agreementTermsTitle => '用户协议';

  @override
  String get agreementPrivacyTitle => '隐私政策';

  @override
  String get agreementDetailsLink => '查看详情';

  @override
  String get agreementButtonConfirm => '同意并继续';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账号';

  @override
  String get settingsRestorePurchases => '恢复购买';

  @override
  String get restorePurchasesNothing => '没有可恢复的购买项目。';

  @override
  String get restorePurchasesCompleted => '购买项目已恢复。';

  @override
  String get settingsNotification => '通知';

  @override
  String get settingsTutorial => '教程';

  @override
  String get settingsCefrLevel => '英语水平';

  @override
  String get pushNotifications => '推送通知';

  @override
  String get pushNotificationsDesc => '接收提醒和重要更新。';

  @override
  String get settingsFeedback => '意见反馈';

  @override
  String get settingsAnnouncements => '公告';

  @override
  String get announcementsEmpty => '暂无公告';

  @override
  String get noticesEmpty => '暂无帖子';

  @override
  String get deletedPost => '该帖子已删除。';

  @override
  String get postNoLongerAvailable => '该帖子已无法查看。';

  @override
  String get backToHome => '返回首页';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsFsdLaboratory => 'FSD 实验室';

  @override
  String get settingsPrivacy => '隐私政策';

  @override
  String get settingsTerms => '用户协议';

  @override
  String get settingsOpenSource => '开源许可';

  @override
  String loginWelcome(String name) {
    return '欢迎你，$name！';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return '继续即表示你同意我们的$terms和$privacy。';
  }

  @override
  String get loginTermsTitle => '用户协议';

  @override
  String get loginPrivacyTitle => '隐私政策';

  @override
  String get loginCatchphrase => '开口说，才能学得会。';

  @override
  String get loginWelcomeTitle => '欢迎来到 SUDA！';

  @override
  String get loginWelcomeSubtitle => '走进故事，开口说英语！';

  @override
  String get loginErrorIdToken => '无法获取 Google ID 令牌，请重试。';

  @override
  String loginErrorFailed(String error) {
    return '登录失败：$error';
  }

  @override
  String get accountName => '姓名';

  @override
  String get accountInfo => '账号';

  @override
  String get accountDelete => '删除账号';

  @override
  String get accountDeleteTitle => '要删除账号吗？';

  @override
  String get accountDeleteConfirmText => '你的所有学习进度和数据都将被永久删除且无法恢复。确定要删除吗？';

  @override
  String get accountDeleteProfileImageTitle => '要删除头像吗？';

  @override
  String get accountDeleteProfileImageContent => '头像一旦删除将无法恢复。';

  @override
  String get accountGoBack => '返回';

  @override
  String get accountDeleteAction => '删除';

  @override
  String get accountSubscription => '订阅';

  @override
  String get accountFreePlanTitle => '免费版';

  @override
  String get accountFreePlanSubtitle => '升级 Premium，解锁更多功能';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => '你正在享受 Premium 权益';

  @override
  String accountPremiumRenewsOn(String date) {
    return '将于$date续订';
  }

  @override
  String get accountChangePlan => '更换套餐';

  @override
  String get changePlanTitle => '更换套餐';

  @override
  String get changePlanCurrentPlan => '当前套餐';

  @override
  String get changePlanAvailablePlans => '可选套餐';

  @override
  String changePlanRenewsOn(String date) {
    return '将于$date续订';
  }

  @override
  String get changePlanLoadFailed => '无法加载信息，请重试。';

  @override
  String get changePlanRetry => '重试';

  @override
  String get changePlanConfirmTitle => '要更换套餐吗？';

  @override
  String get changePlanConfirmBody => '套餐变更将在下一个扣费日生效。';

  @override
  String get changePlanConfirmOk => '确认更换';

  @override
  String get changePlanConfirmCancel => '保留当前套餐';

  @override
  String get changePlanOldPurchaseMissing => '未找到可更改的有效订阅。请在订阅生效后重试。';

  @override
  String get changePlanChangeRequested => '已提交套餐变更申请，可能会在下一个扣费日生效。';

  @override
  String get cefrLevelTitle => '选择你的英语水平';

  @override
  String get cefrLevelAbsoluteBeginner => '零基础';

  @override
  String get cefrLevelBeginner => '入门';

  @override
  String get cefrLevelBasic => '初级';

  @override
  String get cefrLevelIntermediate => '中级';

  @override
  String get firstCefrLevelTitle => '你的英语水平如何？';

  @override
  String get firstCefrLevelDescriptionPreA1 => '我会读英文';

  @override
  String get firstCefrLevelDescriptionA1 => '我会基本问候语和简单短语';

  @override
  String get firstCefrLevelDescriptionA2 => '我能理解并使用简短的句子';

  @override
  String get firstCefrLevelDescriptionB1 => '我能表达自己的观点并参与日常对话';

  @override
  String get firstCefrLevelSettingsHint => '可随时更改';

  @override
  String get firstCefrLevelConfirm => '确认';

  @override
  String get feedbackPlaceholder => '请分享你的想法、建议或遇到的问题…';

  @override
  String get feedbackSend => '发送';

  @override
  String get feedbackSuccess => '感谢你的反馈。';

  @override
  String get microphonePermissionDenied => '未获得麦克风权限，无法开始。';

  @override
  String get holdMicrophoneToSpeak => '按住麦克风说话';

  @override
  String get roleplayTypeMessagePlaceholder => '输入你的回复…';

  @override
  String get yourTurnFirst => '由你先开始！';

  @override
  String get sayLineBelowToStart => '说出下面这句话即可开始。';

  @override
  String get roleplayExitWait => '等一下！';

  @override
  String get roleplayExitMessage => '现在退出将无法获得奖励。确定要退出吗？';

  @override
  String get roleplayExitKeepPlaying => '继续对话';

  @override
  String get roleplayExitExit => '退出';

  @override
  String get roleplayAutoHint => '自动提示';

  @override
  String get roleplayHintLabel => '提示';

  @override
  String get roleplayHintShowAnswer => '点击查看英文参考回复';

  @override
  String get roleplayVoiceSpeed => '语速';

  @override
  String get roleplayEndedFailed => '任务失败…';

  @override
  String get roleplayEndedComplete => '情景对话已完成';

  @override
  String get roleplayEndedEnding => '即将进入结局…';

  @override
  String get roleplayFinishNotEnoughProgress => '对话进度不足';

  @override
  String get roleplayFinishCompleted => '情景对话已完成';

  @override
  String get roleplayFinishMovingToEnding => '即将进入结局…';

  @override
  String get roleplayAnalyzing => '正在分析你的情景对话…';

  @override
  String get roleplayOpeningAiCharacter => 'AI 角色';

  @override
  String get roleplayOpeningScenario => '场景';

  @override
  String get roleplayOpeningAiDisclaimer => 'AI 可能会出错。\n请勿分享个人信息或敏感信息。';

  @override
  String get endingFailTitle => '你还没有完成所有任务！';

  @override
  String get endingFailSubtitle => '再试一次，解锁完整故事。';

  @override
  String get roleplayTryAgainMessage => '很遗憾，你的得分不足，无法获得奖励。';

  @override
  String get endingReport => '报告问题';

  @override
  String get endingHowWas => '这次情景对话体验如何？';

  @override
  String get endingNext => '下一步';

  @override
  String get reportTitle => '报告问题';

  @override
  String get profileHistory => '历史记录';

  @override
  String get profileSaved => '收藏';

  @override
  String get profileHistoryEmpty => '暂无历史记录';

  @override
  String get profileSavedEmpty => '暂无收藏的表达。';

  @override
  String get profileSavedRemoveTitle => '要取消收藏吗？';

  @override
  String get profileSavedRemoveContent => '之后仍可在历史记录中找到它。';

  @override
  String get profileSavedRemoveOk => '取消收藏';

  @override
  String get profileSavedRemoveCancel => '继续练习';

  @override
  String get seriesOverviewTabEpisodes => '剧集';

  @override
  String get seriesOverviewTabSimilarTopic => '相似主题';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return '第$number集';
  }

  @override
  String get seriesOverviewPlay => '开始';

  @override
  String get seriesOverviewLocked => '未解锁';

  @override
  String get seriesOverviewEpisodeLockedToast => '完成上一集即可解锁。';

  @override
  String get notificationPermissionBlockedTitle => '通知已关闭';

  @override
  String get notificationPermissionBlockedMessage => '请在设备设置中开启通知，以接收推送消息。';

  @override
  String get openSettings => '前往设置';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmpty => '暂无通知';

  @override
  String get notificationSendToday => '今天';

  @override
  String get notificationSendOneDayAgo => '1天前';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String get reregistrationRestrictedMessage => '删除账号2天后才能重新注册，请稍后重试。';

  @override
  String get expressionSavedToProfile => '已收藏到个人中心';

  @override
  String get expressionUnsavedToProfile => '已取消收藏';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      '这次无法提供反馈。请尝试用至少7个英文单词回答！';

  @override
  String get roleplayResultScoreMeaning => '含义';

  @override
  String get roleplayResultScoreRelevance => '相关性';

  @override
  String get roleplayResultScoreVocabulary => '词汇';

  @override
  String get roleplayResultScoreGrammar => '语法';

  @override
  String get closePopup => '关闭';

  @override
  String get reviewChatTapHint => '点击聊天气泡播放音频。';

  @override
  String get reviewChatNoAudioToPlay => '暂无可播放的音频。';

  @override
  String get seriesInformationTopicDifficulty => '主题难度';

  @override
  String get seriesInformationLearningGoals => '学习目标';

  @override
  String get energyInfoTitle => '能量';

  @override
  String get energyOutOfEnergyTitle => '能量不足';

  @override
  String get energyInfoRechargeUntil => '距下次恢复还有 @@TIME@@';

  @override
  String get energyInfoFull => '能量已满。';

  @override
  String get energyInfoUnlimitedEndsIn => '无限模式已开启';

  @override
  String get energyInsufficient => '能量不足。';

  @override
  String get endRoleplay => '结束情景对话';

  @override
  String get energyEnablePushTitle => '开启通知';

  @override
  String get energyEnablePushSubtitle => '开启通知，将能量补充至满值。';

  @override
  String get energyEnablePushPrice => '免费';

  @override
  String get energyEnablePushOfferBadge => '仅限一次';

  @override
  String get energyEnablePushCompleted => '能量已补满！';

  @override
  String get energyPurchaseUnlimitedTitle => '无限畅玩卡';

  @override
  String get energyPurchaseUnlimitedSubtitle => '购买后立即生效，有效期10分钟。';

  @override
  String get energyPurchaseCapacityTitle => '提升能量上限';

  @override
  String get energyPurchaseCapacitySubtitle => '将可恢复的能量上限永久提高1点。';

  @override
  String get energyGoPremiumTitle => '升级 Premium';

  @override
  String get energyGoPremiumExplore => '查看权益';

  @override
  String get profileGoPremiumTitle => '订阅 SUDA Premium';

  @override
  String get profileGoPremiumExplore => '查看权益';

  @override
  String get energyPurchasePendingApproval => '你的付款正在等待批准。';

  @override
  String get energyPurchaseNotCompleted => '购买未完成。';

  @override
  String get iapPurchaseProcessing => '正在处理你的购买。';

  @override
  String get iapPurchaseCompleted => '购买已完成。';

  @override
  String get welcomeGiftTitle => '欢迎礼物已送达！';

  @override
  String get welcomeGiftBenefitLead => '享受10分钟无限畅玩！';

  @override
  String get welcomeGiftLine2 => 'Premium 功能已解锁';

  @override
  String get welcomeGiftLine3 => '无限畅玩已解锁';

  @override
  String get welcomeGiftStartNow => '立即开始';

  @override
  String get paywallHeroTitle1 => '多多练习';

  @override
  String get paywallHeroTitle2 => '进步更快';

  @override
  String get paywallHeroBody => '使用 Premium 延长练习时间，并获得 AI 反馈，提升英语表达信心。';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => '增加每日练习量';

  @override
  String get paywallBenefitMaxEnergy => '能量上限最高30点';

  @override
  String get paywallBenefitAiFeedback => 'AI 句子反馈';

  @override
  String get paywallChoosePlan => '选择套餐';

  @override
  String get paywallAnnualPlanTitle => '年度套餐';

  @override
  String get paywallAnnualPlanSubtitle => '相比月度套餐节省33%以上。';

  @override
  String get paywallMonthlyPlanTitle => '月度套餐';

  @override
  String get paywallMonthlyPlanSubtitle => '按月订阅，灵活使用。';

  @override
  String get paywallBestBadge => '最划算';

  @override
  String get paywallCta => '立即订阅';

  @override
  String get paywallAutoRenewNotice => '除非在当前计费周期结束前至少24小时取消订阅，否则订阅将自动续订。';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/月';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/年';
  }

  @override
  String get paywallFallbackAnnualPerMonth => 'S\$11.67';

  @override
  String get paywallFallbackAnnual => 'S\$139.99';

  @override
  String get paywallFallbackMonthly => 'S\$19.98';

  @override
  String get paywallFallbackMonthlyTimes12 => 'S\$239.76';

  @override
  String get paywallCompletedTitle => '恭喜！';

  @override
  String get paywallCompletedBody => '你的 Premium 权益现已生效。';

  @override
  String get paywallCompletedContinue => '继续';

  @override
  String get roleplayChooseYourRole => '请选择角色';

  @override
  String get roleplaySimilarRoleplays => '相似角色扮演';

  @override
  String get roleplayBeingPrepared => '该角色扮演正在准备中。';

  @override
  String get roleplayUnlockPreviousRole => '完成上一角色的全部结局即可解锁此角色。';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '已完成 $percent%';
  }

  @override
  String get roleplayTurnGradeA => '哇!';

  @override
  String get roleplayTurnGradeB => '好!';

  @override
  String get roleplayTurnGradeC => '嗯…';

  @override
  String get roleplayTurnGradeD => '哦…';

  @override
  String get tutorialPage1Title => '查看你的**任务**，\n开始对话吧。';

  @override
  String get tutorialPage1Tip => '*提示：说得越自然，\n奖励越大！';

  @override
  String get tutorialPage2Title => '听不懂时\n请使用**翻译**。';

  @override
  String get tutorialPage3Title => '卡住时\n请使用**提示**。';

  @override
  String get tutorialPage3Subtitle => '你可以随时\n开启或关闭自动提示。';

  @override
  String get tutorialPage4Title => '发音有困难的话，\n先听再跟读。';

  @override
  String get tutorialPage4Tip => '*提示：不看翻译来回答，\n可以获得更高分数。';

  @override
  String get tutorialPage5Title => '不方便大声说？';

  @override
  String get tutorialPage5Subtitle => '切换到**文字模式**。';

  @override
  String get tutorialPage6Title => '没有人在评判你。\n你可以的！';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get agreementHeading => '请查看并同意以下条款后继续。';

  @override
  String get agreementTermsLabel => '我同意《用户协议》。';

  @override
  String get agreementPrivacyLabel => '我同意《隐私政策》。';

  @override
  String get agreementTermsTitle => '用户协议';

  @override
  String get agreementPrivacyTitle => '隐私政策';

  @override
  String get agreementDetailsLink => '查看详情';

  @override
  String get agreementButtonConfirm => '同意并继续';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAccount => '账号';

  @override
  String get settingsRestorePurchases => '恢复购买';

  @override
  String get restorePurchasesNothing => '没有可恢复的购买项目。';

  @override
  String get restorePurchasesCompleted => '购买项目已恢复。';

  @override
  String get settingsNotification => '通知';

  @override
  String get settingsTutorial => '教程';

  @override
  String get settingsCefrLevel => '英语水平';

  @override
  String get pushNotifications => '推送通知';

  @override
  String get pushNotificationsDesc => '接收提醒和重要更新。';

  @override
  String get settingsFeedback => '意见反馈';

  @override
  String get settingsAnnouncements => '公告';

  @override
  String get announcementsEmpty => '暂无公告';

  @override
  String get noticesEmpty => '暂无帖子';

  @override
  String get deletedPost => '该帖子已删除。';

  @override
  String get postNoLongerAvailable => '该帖子已无法查看。';

  @override
  String get backToHome => '返回首页';

  @override
  String get settingsSignOut => '退出登录';

  @override
  String get settingsFsdLaboratory => 'FSD 实验室';

  @override
  String get settingsPrivacy => '隐私政策';

  @override
  String get settingsTerms => '用户协议';

  @override
  String get settingsOpenSource => '开源许可';

  @override
  String loginWelcome(String name) {
    return '欢迎你，$name！';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return '继续即表示你同意我们的$terms和$privacy。';
  }

  @override
  String get loginTermsTitle => '用户协议';

  @override
  String get loginPrivacyTitle => '隐私政策';

  @override
  String get loginCatchphrase => '开口说，才能学得会。';

  @override
  String get loginWelcomeTitle => '欢迎来到 SUDA！';

  @override
  String get loginWelcomeSubtitle => '走进故事，开口说英语！';

  @override
  String get loginErrorIdToken => '无法获取 Google ID 令牌，请重试。';

  @override
  String loginErrorFailed(String error) {
    return '登录失败：$error';
  }

  @override
  String get accountName => '姓名';

  @override
  String get accountInfo => '账号';

  @override
  String get accountDelete => '删除账号';

  @override
  String get accountDeleteTitle => '要删除账号吗？';

  @override
  String get accountDeleteConfirmText => '你的所有学习进度和数据都将被永久删除且无法恢复。确定要删除吗？';

  @override
  String get accountDeleteProfileImageTitle => '要删除头像吗？';

  @override
  String get accountDeleteProfileImageContent => '头像一旦删除将无法恢复。';

  @override
  String get accountGoBack => '返回';

  @override
  String get accountDeleteAction => '删除';

  @override
  String get accountSubscription => '订阅';

  @override
  String get accountFreePlanTitle => '免费版';

  @override
  String get accountFreePlanSubtitle => '升级 Premium，解锁更多功能';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => '你正在享受 Premium 权益';

  @override
  String accountPremiumRenewsOn(String date) {
    return '将于$date续订';
  }

  @override
  String get accountChangePlan => '更换套餐';

  @override
  String get changePlanTitle => '更换套餐';

  @override
  String get changePlanCurrentPlan => '当前套餐';

  @override
  String get changePlanAvailablePlans => '可选套餐';

  @override
  String changePlanRenewsOn(String date) {
    return '将于$date续订';
  }

  @override
  String get changePlanLoadFailed => '无法加载信息，请重试。';

  @override
  String get changePlanRetry => '重试';

  @override
  String get changePlanConfirmTitle => '要更换套餐吗？';

  @override
  String get changePlanConfirmBody => '套餐变更将在下一个扣费日生效。';

  @override
  String get changePlanConfirmOk => '确认更换';

  @override
  String get changePlanConfirmCancel => '保留当前套餐';

  @override
  String get changePlanOldPurchaseMissing => '未找到可更改的有效订阅。请在订阅生效后重试。';

  @override
  String get changePlanChangeRequested => '已提交套餐变更申请，可能会在下一个扣费日生效。';

  @override
  String get cefrLevelTitle => '选择你的英语水平';

  @override
  String get cefrLevelAbsoluteBeginner => '零基础';

  @override
  String get cefrLevelBeginner => '入门';

  @override
  String get cefrLevelBasic => '初级';

  @override
  String get cefrLevelIntermediate => '中级';

  @override
  String get firstCefrLevelTitle => '你的英语水平如何？';

  @override
  String get firstCefrLevelDescriptionPreA1 => '我会读英文';

  @override
  String get firstCefrLevelDescriptionA1 => '我会基本问候语和简单短语';

  @override
  String get firstCefrLevelDescriptionA2 => '我能理解并使用简短的句子';

  @override
  String get firstCefrLevelDescriptionB1 => '我能表达自己的观点并参与日常对话';

  @override
  String get firstCefrLevelSettingsHint => '可随时更改';

  @override
  String get firstCefrLevelConfirm => '确认';

  @override
  String get feedbackPlaceholder => '请分享你的想法、建议或遇到的问题…';

  @override
  String get feedbackSend => '发送';

  @override
  String get feedbackSuccess => '感谢你的反馈。';

  @override
  String get microphonePermissionDenied => '未获得麦克风权限，无法开始。';

  @override
  String get holdMicrophoneToSpeak => '按住麦克风说话';

  @override
  String get roleplayTypeMessagePlaceholder => '输入你的回复…';

  @override
  String get yourTurnFirst => '由你先开始！';

  @override
  String get sayLineBelowToStart => '说出下面这句话即可开始。';

  @override
  String get roleplayExitWait => '等一下！';

  @override
  String get roleplayExitMessage => '现在退出将无法获得奖励。确定要退出吗？';

  @override
  String get roleplayExitKeepPlaying => '继续对话';

  @override
  String get roleplayExitExit => '退出';

  @override
  String get roleplayAutoHint => '自动提示';

  @override
  String get roleplayHintLabel => '提示';

  @override
  String get roleplayHintShowAnswer => '点击查看英文参考回复';

  @override
  String get roleplayVoiceSpeed => '语速';

  @override
  String get roleplayEndedFailed => '任务失败…';

  @override
  String get roleplayEndedComplete => '情景对话已完成';

  @override
  String get roleplayEndedEnding => '即将进入结局…';

  @override
  String get roleplayFinishNotEnoughProgress => '对话进度不足';

  @override
  String get roleplayFinishCompleted => '情景对话已完成';

  @override
  String get roleplayFinishMovingToEnding => '即将进入结局…';

  @override
  String get roleplayAnalyzing => '正在分析你的情景对话…';

  @override
  String get roleplayOpeningAiCharacter => 'AI 角色';

  @override
  String get roleplayOpeningScenario => '场景';

  @override
  String get roleplayOpeningAiDisclaimer => 'AI 可能会出错。\n请勿分享个人信息或敏感信息。';

  @override
  String get endingFailTitle => '你还没有完成所有任务！';

  @override
  String get endingFailSubtitle => '再试一次，解锁完整故事。';

  @override
  String get roleplayTryAgainMessage => '很遗憾，你的得分不足，无法获得奖励。';

  @override
  String get endingReport => '报告问题';

  @override
  String get endingHowWas => '这次情景对话体验如何？';

  @override
  String get endingNext => '下一步';

  @override
  String get reportTitle => '报告问题';

  @override
  String get profileHistory => '历史记录';

  @override
  String get profileSaved => '收藏';

  @override
  String get profileHistoryEmpty => '暂无历史记录';

  @override
  String get profileSavedEmpty => '暂无收藏的表达。';

  @override
  String get profileSavedRemoveTitle => '要取消收藏吗？';

  @override
  String get profileSavedRemoveContent => '之后仍可在历史记录中找到它。';

  @override
  String get profileSavedRemoveOk => '取消收藏';

  @override
  String get profileSavedRemoveCancel => '继续练习';

  @override
  String get seriesOverviewTabEpisodes => '剧集';

  @override
  String get seriesOverviewTabSimilarTopic => '相似主题';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return '第$number集';
  }

  @override
  String get seriesOverviewPlay => '开始';

  @override
  String get seriesOverviewLocked => '未解锁';

  @override
  String get seriesOverviewEpisodeLockedToast => '完成上一集即可解锁。';

  @override
  String get notificationPermissionBlockedTitle => '通知已关闭';

  @override
  String get notificationPermissionBlockedMessage => '请在设备设置中开启通知，以接收推送消息。';

  @override
  String get openSettings => '前往设置';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmpty => '暂无通知';

  @override
  String get notificationSendToday => '今天';

  @override
  String get notificationSendOneDayAgo => '1天前';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String get reregistrationRestrictedMessage => '删除账号2天后才能重新注册，请稍后重试。';

  @override
  String get expressionSavedToProfile => '已收藏到个人中心';

  @override
  String get expressionUnsavedToProfile => '已取消收藏';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      '这次无法提供反馈。请尝试用至少7个英文单词回答！';

  @override
  String get roleplayResultScoreMeaning => '含义';

  @override
  String get roleplayResultScoreRelevance => '相关性';

  @override
  String get roleplayResultScoreVocabulary => '词汇';

  @override
  String get roleplayResultScoreGrammar => '语法';

  @override
  String get closePopup => '关闭';

  @override
  String get reviewChatTapHint => '点击聊天气泡播放音频。';

  @override
  String get reviewChatNoAudioToPlay => '暂无可播放的音频。';

  @override
  String get seriesInformationTopicDifficulty => '主题难度';

  @override
  String get seriesInformationLearningGoals => '学习目标';

  @override
  String get energyInfoTitle => '能量';

  @override
  String get energyOutOfEnergyTitle => '能量不足';

  @override
  String get energyInfoRechargeUntil => '距下次恢复还有 @@TIME@@';

  @override
  String get energyInfoFull => '能量已满。';

  @override
  String get energyInfoUnlimitedEndsIn => '无限模式已开启';

  @override
  String get energyInsufficient => '能量不足。';

  @override
  String get endRoleplay => '结束情景对话';

  @override
  String get energyEnablePushTitle => '开启通知';

  @override
  String get energyEnablePushSubtitle => '开启通知，将能量补充至满值。';

  @override
  String get energyEnablePushPrice => '免费';

  @override
  String get energyEnablePushOfferBadge => '仅限一次';

  @override
  String get energyEnablePushCompleted => '能量已补满！';

  @override
  String get energyPurchaseUnlimitedTitle => '无限畅玩卡';

  @override
  String get energyPurchaseUnlimitedSubtitle => '购买后立即生效，有效期10分钟。';

  @override
  String get energyPurchaseCapacityTitle => '提升能量上限';

  @override
  String get energyPurchaseCapacitySubtitle => '将可恢复的能量上限永久提高1点。';

  @override
  String get energyGoPremiumTitle => '升级 Premium';

  @override
  String get energyGoPremiumExplore => '查看权益';

  @override
  String get profileGoPremiumTitle => '订阅 SUDA Premium';

  @override
  String get profileGoPremiumExplore => '查看权益';

  @override
  String get energyPurchasePendingApproval => '你的付款正在等待批准。';

  @override
  String get energyPurchaseNotCompleted => '购买未完成。';

  @override
  String get iapPurchaseProcessing => '正在处理你的购买。';

  @override
  String get iapPurchaseCompleted => '购买已完成。';

  @override
  String get welcomeGiftTitle => '欢迎礼物已送达！';

  @override
  String get welcomeGiftBenefitLead => '享受10分钟无限畅玩！';

  @override
  String get welcomeGiftLine2 => 'Premium 功能已解锁';

  @override
  String get welcomeGiftLine3 => '无限畅玩已解锁';

  @override
  String get welcomeGiftStartNow => '立即开始';

  @override
  String get paywallHeroTitle1 => '多多练习';

  @override
  String get paywallHeroTitle2 => '进步更快';

  @override
  String get paywallHeroBody => '使用 Premium 延长练习时间，并获得 AI 反馈，提升英语表达信心。';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => '增加每日练习量';

  @override
  String get paywallBenefitMaxEnergy => '能量上限最高30点';

  @override
  String get paywallBenefitAiFeedback => 'AI 句子反馈';

  @override
  String get paywallChoosePlan => '选择套餐';

  @override
  String get paywallAnnualPlanTitle => '年度套餐';

  @override
  String get paywallAnnualPlanSubtitle => '相比月度套餐节省33%以上。';

  @override
  String get paywallMonthlyPlanTitle => '月度套餐';

  @override
  String get paywallMonthlyPlanSubtitle => '按月订阅，灵活使用。';

  @override
  String get paywallBestBadge => '最划算';

  @override
  String get paywallCta => '立即订阅';

  @override
  String get paywallAutoRenewNotice => '除非在当前计费周期结束前至少24小时取消订阅，否则订阅将自动续订。';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/月';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/年';
  }

  @override
  String get paywallFallbackAnnualPerMonth => 'S\$11.67';

  @override
  String get paywallFallbackAnnual => 'S\$139.99';

  @override
  String get paywallFallbackMonthly => 'S\$19.98';

  @override
  String get paywallFallbackMonthlyTimes12 => 'S\$239.76';

  @override
  String get paywallCompletedTitle => '恭喜！';

  @override
  String get paywallCompletedBody => '你的 Premium 权益现已生效。';

  @override
  String get paywallCompletedContinue => '继续';

  @override
  String get roleplayChooseYourRole => '请选择角色';

  @override
  String get roleplaySimilarRoleplays => '相似角色扮演';

  @override
  String get roleplayBeingPrepared => '该角色扮演正在准备中。';

  @override
  String get roleplayUnlockPreviousRole => '完成上一角色的全部结局即可解锁此角色。';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '已完成 $percent%';
  }

  @override
  String get roleplayTurnGradeA => '哇!';

  @override
  String get roleplayTurnGradeB => '好!';

  @override
  String get roleplayTurnGradeC => '嗯…';

  @override
  String get roleplayTurnGradeD => '哦…';

  @override
  String get tutorialPage1Title => '查看你的**任务**，\n开始对话吧。';

  @override
  String get tutorialPage1Tip => '*提示：说得越自然，\n奖励越大！';

  @override
  String get tutorialPage2Title => '听不懂时\n请使用**翻译**。';

  @override
  String get tutorialPage3Title => '卡住时\n请使用**提示**。';

  @override
  String get tutorialPage3Subtitle => '你可以随时\n开启或关闭自动提示。';

  @override
  String get tutorialPage4Title => '发音有困难的话，\n先听再跟读。';

  @override
  String get tutorialPage4Tip => '*提示：不看翻译来回答，\n可以获得更高分数。';

  @override
  String get tutorialPage5Title => '不方便大声说？';

  @override
  String get tutorialPage5Subtitle => '切换到**文字模式**。';

  @override
  String get tutorialPage6Title => '没有人在评判你。\n你可以的！';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get agreementHeading => '請閱讀並同意以下條款，以繼續使用。';

  @override
  String get agreementTermsLabel => '我同意使用條款。';

  @override
  String get agreementPrivacyLabel => '我同意隱私政策。';

  @override
  String get agreementTermsTitle => '使用條款';

  @override
  String get agreementPrivacyTitle => '隱私政策';

  @override
  String get agreementDetailsLink => '查看詳情';

  @override
  String get agreementButtonConfirm => '同意並繼續';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAccount => '帳號';

  @override
  String get settingsRestorePurchases => '恢復購買項目';

  @override
  String get restorePurchasesNothing => '沒有可恢復的購買項目。';

  @override
  String get restorePurchasesCompleted => '購買項目已恢復。';

  @override
  String get settingsNotification => '通知';

  @override
  String get settingsTutorial => '教學';

  @override
  String get settingsCefrLevel => '英語程度';

  @override
  String get pushNotifications => '推播通知';

  @override
  String get pushNotificationsDesc => '接收提醒和重要更新。';

  @override
  String get settingsFeedback => '意見回饋';

  @override
  String get settingsAnnouncements => '公告';

  @override
  String get announcementsEmpty => '目前沒有公告';

  @override
  String get noticesEmpty => '目前沒有貼文';

  @override
  String get deletedPost => '這則貼文已刪除。';

  @override
  String get postNoLongerAvailable => '這則貼文已無法查看。';

  @override
  String get backToHome => '返回首頁';

  @override
  String get settingsSignOut => '登出';

  @override
  String get settingsFsdLaboratory => 'FSD 實驗室';

  @override
  String get settingsPrivacy => '隱私政策';

  @override
  String get settingsTerms => '服務條款';

  @override
  String get settingsOpenSource => '開放原始碼授權';

  @override
  String loginWelcome(String name) {
    return '$name，歡迎你！';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return '繼續使用即表示你同意我們的$terms和$privacy。';
  }

  @override
  String get loginTermsTitle => '使用條款';

  @override
  String get loginPrivacyTitle => '隱私政策';

  @override
  String get loginCatchphrase => '開口說，英語就是這樣學會的。';

  @override
  String get loginWelcomeTitle => '歡迎來到 SUDA！';

  @override
  String get loginWelcomeSubtitle => '走進故事情境，開口說英語！';

  @override
  String get loginErrorIdToken => '無法取得 Google ID Token，請再試一次。';

  @override
  String loginErrorFailed(String error) {
    return '登入失敗：$error';
  }

  @override
  String get accountName => '姓名';

  @override
  String get accountInfo => '帳號';

  @override
  String get accountDelete => '刪除帳號';

  @override
  String get accountDeleteTitle => '要刪除帳號嗎？';

  @override
  String get accountDeleteConfirmText => '你的所有進度和資料都將永久刪除且無法復原。確定要刪除嗎？';

  @override
  String get accountDeleteProfileImageTitle => '要刪除個人頭像嗎？';

  @override
  String get accountDeleteProfileImageContent => '個人頭像刪除後將無法復原。';

  @override
  String get accountGoBack => '返回';

  @override
  String get accountDeleteAction => '刪除';

  @override
  String get accountSubscription => '訂閱';

  @override
  String get accountFreePlanTitle => '免費方案';

  @override
  String get accountFreePlanSubtitle => '升級至 Premium，解鎖更多功能';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => '你正在享用 Premium 權益';

  @override
  String accountPremiumRenewsOn(String date) {
    return '將於 $date 續訂';
  }

  @override
  String get accountChangePlan => '更改方案';

  @override
  String get changePlanTitle => '更改方案';

  @override
  String get changePlanCurrentPlan => '目前方案';

  @override
  String get changePlanAvailablePlans => '可選方案';

  @override
  String changePlanRenewsOn(String date) {
    return '將於 $date 續訂';
  }

  @override
  String get changePlanLoadFailed => '無法載入資訊，請再試一次。';

  @override
  String get changePlanRetry => '再試一次';

  @override
  String get changePlanConfirmTitle => '要更改方案嗎？';

  @override
  String get changePlanConfirmBody => '方案變更將於下次計費日生效。';

  @override
  String get changePlanConfirmOk => '確認更改';

  @override
  String get changePlanConfirmCancel => '保留目前方案';

  @override
  String get changePlanOldPurchaseMissing => '找不到可變更的有效訂閱。請在訂閱生效後再試一次。';

  @override
  String get changePlanChangeRequested => '已提出方案變更申請，可能會在下次計費日生效。';

  @override
  String get cefrLevelTitle => '選擇你的英語程度';

  @override
  String get cefrLevelAbsoluteBeginner => '零基礎';

  @override
  String get cefrLevelBeginner => '入門';

  @override
  String get cefrLevelBasic => '初級';

  @override
  String get cefrLevelIntermediate => '中級';

  @override
  String get firstCefrLevelTitle => '你的英語程度如何？';

  @override
  String get firstCefrLevelDescriptionPreA1 => '我會讀英文';

  @override
  String get firstCefrLevelDescriptionA1 => '我懂基本問候語和簡單片語';

  @override
  String get firstCefrLevelDescriptionA2 => '我能理解並使用簡短的句子';

  @override
  String get firstCefrLevelDescriptionB1 => '我能表達意見並參與日常對話';

  @override
  String get firstCefrLevelSettingsHint => '之後可隨時更改';

  @override
  String get firstCefrLevelConfirm => '確認';

  @override
  String get feedbackPlaceholder => '歡迎分享你的想法、建議或遇到的任何問題⋯⋯';

  @override
  String get feedbackSend => '送出';

  @override
  String get feedbackSuccess => '感謝你的回饋。';

  @override
  String get microphonePermissionDenied => '未取得麥克風權限，無法開始。';

  @override
  String get holdMicrophoneToSpeak => '按住麥克風說話';

  @override
  String get roleplayTypeMessagePlaceholder => '輸入你的回覆⋯⋯';

  @override
  String get yourTurnFirst => '由你先開始！';

  @override
  String get sayLineBelowToStart => '說出下方句子以開始。';

  @override
  String get roleplayExitWait => '等等！';

  @override
  String get roleplayExitMessage => '現在離開將無法獲得獎勵。確定要離開嗎？';

  @override
  String get roleplayExitKeepPlaying => '繼續進行';

  @override
  String get roleplayExitExit => '離開';

  @override
  String get roleplayAutoHint => '自動提示';

  @override
  String get roleplayHintLabel => '提示';

  @override
  String get roleplayHintShowAnswer => '點一下查看建議的英文回覆';

  @override
  String get roleplayVoiceSpeed => '語音速度';

  @override
  String get roleplayEndedFailed => '任務失敗⋯⋯';

  @override
  String get roleplayEndedComplete => '角色扮演完成';

  @override
  String get roleplayEndedEnding => '即將進入結局⋯⋯';

  @override
  String get roleplayFinishNotEnoughProgress => '進度不足';

  @override
  String get roleplayFinishCompleted => '角色扮演已完成';

  @override
  String get roleplayFinishMovingToEnding => '即將進入結局⋯⋯';

  @override
  String get roleplayAnalyzing => '正在分析你的角色扮演⋯⋯';

  @override
  String get roleplayOpeningAiCharacter => 'AI 角色';

  @override
  String get roleplayOpeningScenario => '情境';

  @override
  String get roleplayOpeningAiDisclaimer => 'AI 可能會出錯。\n請勿分享個人或敏感資訊。';

  @override
  String get endingFailTitle => '你沒有完成所有任務！';

  @override
  String get endingFailSubtitle => '再試一次，探索完整故事。';

  @override
  String get roleplayTryAgainMessage => '很可惜，你的分數不足以獲得獎勵。';

  @override
  String get endingReport => '回報問題';

  @override
  String get endingHowWas => '這次角色扮演體驗如何？';

  @override
  String get endingNext => '下一步';

  @override
  String get reportTitle => '回報問題';

  @override
  String get profileHistory => '歷史紀錄';

  @override
  String get profileSaved => '已儲存';

  @override
  String get profileHistoryEmpty => '目前沒有紀錄';

  @override
  String get profileSavedEmpty => '目前沒有儲存的英文表達。';

  @override
  String get profileSavedRemoveTitle => '要從已儲存項目中移除嗎？';

  @override
  String get profileSavedRemoveContent => '之後仍可在歷史紀錄中找到它。';

  @override
  String get profileSavedRemoveOk => '移除';

  @override
  String get profileSavedRemoveCancel => '繼續練習';

  @override
  String get seriesOverviewTabEpisodes => '集數';

  @override
  String get seriesOverviewTabSimilarTopic => '相似主題';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return '第 $number 集';
  }

  @override
  String get seriesOverviewPlay => '開始';

  @override
  String get seriesOverviewLocked => '未解鎖';

  @override
  String get seriesOverviewEpisodeLockedToast => '完成上一集即可解鎖。';

  @override
  String get notificationPermissionBlockedTitle => '通知已關閉';

  @override
  String get notificationPermissionBlockedMessage => '若要接收推播通知，請在裝置設定中開啟通知。';

  @override
  String get openSettings => '開啟設定';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmpty => '目前沒有通知';

  @override
  String get notificationSendToday => '今天';

  @override
  String get notificationSendOneDayAgo => '1 天前';

  @override
  String notificationSendDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get reregistrationRestrictedMessage => '刪除帳號後需等待 2 天才能重新註冊，請稍後再試。';

  @override
  String get expressionSavedToProfile => '已儲存至個人檔案';

  @override
  String get expressionUnsavedToProfile => '已取消儲存';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      '這次無法提供回饋。試著用至少 7 個英文單字作答！';

  @override
  String get roleplayResultScoreMeaning => '語意';

  @override
  String get roleplayResultScoreRelevance => '切題度';

  @override
  String get roleplayResultScoreVocabulary => '詞彙';

  @override
  String get roleplayResultScoreGrammar => '文法';

  @override
  String get closePopup => '關閉';

  @override
  String get reviewChatTapHint => '點一下對話氣泡即可播放音訊。';

  @override
  String get reviewChatNoAudioToPlay => '沒有可播放的音訊。';

  @override
  String get seriesInformationTopicDifficulty => '主題難度';

  @override
  String get seriesInformationLearningGoals => '學習目標';

  @override
  String get energyInfoTitle => '能量';

  @override
  String get energyOutOfEnergyTitle => '能量不足';

  @override
  String get energyInfoRechargeUntil => '距離下次補充還有 @@TIME@@';

  @override
  String get energyInfoFull => '能量已滿。';

  @override
  String get energyInfoUnlimitedEndsIn => '無限暢玩模式使用中';

  @override
  String get energyInsufficient => '你的能量不足。';

  @override
  String get endRoleplay => '結束角色扮演';

  @override
  String get energyEnablePushTitle => '開啟通知';

  @override
  String get energyEnablePushSubtitle => '開啟通知，即可將能量完全補滿。';

  @override
  String get energyEnablePushPrice => '免費';

  @override
  String get energyEnablePushOfferBadge => '僅限一次';

  @override
  String get energyEnablePushCompleted => '能量已補滿！';

  @override
  String get energyPurchaseUnlimitedTitle => '無限暢玩通行證';

  @override
  String get energyPurchaseUnlimitedSubtitle => '購買後立即生效，有效期 10 分鐘。';

  @override
  String get energyPurchaseCapacityTitle => '能量上限升級';

  @override
  String get energyPurchaseCapacitySubtitle => '可補充的能量上限永久增加 1 點。';

  @override
  String get energyGoPremiumTitle => '升級 Premium';

  @override
  String get energyGoPremiumExplore => '了解更多';

  @override
  String get profileGoPremiumTitle => '升級至 SUDA Premium';

  @override
  String get profileGoPremiumExplore => '了解更多';

  @override
  String get energyPurchasePendingApproval => '你的付款正在等待核准。';

  @override
  String get energyPurchaseNotCompleted => '購買尚未完成。';

  @override
  String get iapPurchaseProcessing => '正在處理你的購買。';

  @override
  String get iapPurchaseCompleted => '購買已完成。';

  @override
  String get welcomeGiftTitle => '你的迎新禮物已送達！';

  @override
  String get welcomeGiftBenefitLead => '享受 10 分鐘的無限暢玩！';

  @override
  String get welcomeGiftLine2 => 'Premium 功能已解鎖';

  @override
  String get welcomeGiftLine3 => '無限暢玩已解鎖';

  @override
  String get welcomeGiftStartNow => '立即開始';

  @override
  String get paywallHeroTitle1 => '練習更多';

  @override
  String get paywallHeroTitle2 => '進步更快';

  @override
  String get paywallHeroBody => '使用 Premium 延長練習時間，並獲得 AI 回饋，建立英語自信。';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => '每天練習更多';

  @override
  String get paywallBenefitMaxEnergy => '能量上限可達 30 點';

  @override
  String get paywallBenefitAiFeedback => 'AI 句子回饋';

  @override
  String get paywallChoosePlan => '選擇你的方案';

  @override
  String get paywallAnnualPlanTitle => '年繳方案';

  @override
  String get paywallAnnualPlanSubtitle => '比月繳方案節省超過 33%。';

  @override
  String get paywallMonthlyPlanTitle => '月繳方案';

  @override
  String get paywallMonthlyPlanSubtitle => '彈性按月使用。';

  @override
  String get paywallBestBadge => '最划算';

  @override
  String get paywallCta => '立即訂閱';

  @override
  String get paywallAutoRenewNotice => '若未在本期計費週期結束前至少 24 小時取消訂閱，訂閱將自動續訂。';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/月';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/年';
  }

  @override
  String get paywallFallbackAnnualPerMonth => 'NT\$281.67';

  @override
  String get paywallFallbackAnnual => 'NT\$3,380';

  @override
  String get paywallFallbackMonthly => 'NT\$470';

  @override
  String get paywallFallbackMonthlyTimes12 => 'NT\$5,640';

  @override
  String get paywallCompletedTitle => '恭喜！';

  @override
  String get paywallCompletedBody => '你的 Premium 權益現已生效。';

  @override
  String get paywallCompletedContinue => '繼續';

  @override
  String get roleplayChooseYourRole => '請選擇角色';

  @override
  String get roleplaySimilarRoleplays => '相似角色扮演';

  @override
  String get roleplayBeingPrepared => '此角色扮演正在準備中。';

  @override
  String get roleplayUnlockPreviousRole => '完成上一角色的全部結局即可解鎖此角色。';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return '已完成 $percent%';
  }

  @override
  String get roleplayTurnGradeA => '哇！';

  @override
  String get roleplayTurnGradeB => '好！';

  @override
  String get roleplayTurnGradeC => '嗯…';

  @override
  String get roleplayTurnGradeD => '哦…';

  @override
  String get tutorialPage1Title => '查看你的**任務**，\n開始對話吧。';

  @override
  String get tutorialPage1Tip => '*提示：說得越自然，\n獎勵越大！';

  @override
  String get tutorialPage2Title => '聽不懂時\n請使用**翻譯**。';

  @override
  String get tutorialPage3Title => '卡住時\n請使用**提示**。';

  @override
  String get tutorialPage3Subtitle => '你可以隨時\n開啟或關閉自動提示。';

  @override
  String get tutorialPage4Title => '發音有困難的話，\n先聽再跟讀。';

  @override
  String get tutorialPage4Tip => '*提示：不看翻譯來回答，\n可以獲得更高分數。';

  @override
  String get tutorialPage5Title => '不方便大聲說？';

  @override
  String get tutorialPage5Subtitle => '切換到**文字模式**。';

  @override
  String get tutorialPage6Title => '沒有人在評判你。\n你沒問題的！';
}
