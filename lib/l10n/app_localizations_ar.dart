// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get agreementHeading =>
      'يرجى مراجعة البنود أدناه والموافقة عليها للمتابعة.';

  @override
  String get agreementTermsLabel => 'أوافق على شروط الاستخدام.';

  @override
  String get agreementPrivacyLabel => 'أوافق على سياسة الخصوصية.';

  @override
  String get agreementTermsTitle => 'شروط الاستخدام';

  @override
  String get agreementPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get agreementDetailsLink => 'عرض التفاصيل';

  @override
  String get agreementButtonConfirm => 'تأكيد ومتابعة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsRestorePurchases => 'استعادة المشتريات';

  @override
  String get restorePurchasesNothing => 'لا توجد مشتريات لاستعادتها.';

  @override
  String get restorePurchasesCompleted => 'تمت استعادة المشتريات.';

  @override
  String get settingsNotification => 'الإشعارات';

  @override
  String get settingsTutorial => 'البرنامج التعليمي';

  @override
  String get settingsCefrLevel => 'مستوى اللغة الإنجليزية';

  @override
  String get pushNotifications => 'الإشعارات الفورية';

  @override
  String get pushNotificationsDesc => 'تلقَّ التذكيرات والتحديثات المهمة.';

  @override
  String get settingsFeedback => 'الملاحظات';

  @override
  String get settingsAnnouncements => 'الإعلانات';

  @override
  String get announcementsEmpty => 'لا توجد إعلانات بعد';

  @override
  String get noticesEmpty => 'لا توجد منشورات بعد';

  @override
  String get deletedPost => 'تم حذف هذا المنشور.';

  @override
  String get postNoLongerAvailable => 'لم يعد هذا المنشور متاحًا.';

  @override
  String get backToHome => 'العودة إلى الصفحة الرئيسية';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String get settingsFsdLaboratory => 'مختبر FSD';

  @override
  String get settingsPrivacy => 'سياسة الخصوصية';

  @override
  String get settingsTerms => 'شروط الخدمة';

  @override
  String get settingsOpenSource => 'تراخيص المصادر المفتوحة';

  @override
  String loginWelcome(String name) {
    return 'مرحبًا بك، $name!';
  }

  @override
  String loginTermsTemplate(String terms, String privacy) {
    return 'بالمتابعة، فإنك توافق على $terms و$privacy.';
  }

  @override
  String get loginTermsTitle => 'شروط الاستخدام';

  @override
  String get loginPrivacyTitle => 'سياسة الخصوصية';

  @override
  String get loginCatchphrase => 'ابدأ بالتحدث. هكذا تتعلم.';

  @override
  String get loginWelcomeTitle => 'مرحبًا بك في SUDA!';

  @override
  String get loginWelcomeSubtitle => 'انغمس في قصة وابدأ التحدث بالإنجليزية!';

  @override
  String get loginErrorIdToken =>
      'تعذّر الحصول على رمز تعريف Google. يرجى المحاولة مرة أخرى.';

  @override
  String loginErrorFailed(String error) {
    return 'فشل تسجيل الدخول: $error';
  }

  @override
  String get accountName => 'الاسم';

  @override
  String get accountInfo => 'الحساب';

  @override
  String get accountDelete => 'حذف الحساب';

  @override
  String get accountDeleteTitle => 'هل تريد حذف الحساب؟';

  @override
  String get accountDeleteConfirmText =>
      'ستفقد كل تقدمك وبياناتك نهائيًا. هل أنت متأكد؟';

  @override
  String get accountDeleteProfileImageTitle => 'هل تريد حذف صورة الملف الشخصي؟';

  @override
  String get accountDeleteProfileImageContent =>
      'بعد حذفها، لا يمكن استعادة صورة ملفك الشخصي.';

  @override
  String get accountGoBack => 'العودة';

  @override
  String get accountDeleteAction => 'حذف';

  @override
  String get accountSubscription => 'الاشتراك';

  @override
  String get accountFreePlanTitle => 'الخطة المجانية';

  @override
  String get accountFreePlanSubtitle =>
      'اشترك في Premium لفتح المزيد من الميزات';

  @override
  String get accountPremiumTitle => 'Premium';

  @override
  String get accountPremiumSubtitle => 'أنت تستمتع بمزايا Premium';

  @override
  String accountPremiumRenewsOn(String date) {
    return 'يتجدد الاشتراك في $date';
  }

  @override
  String get accountChangePlan => 'تغيير الخطة';

  @override
  String get changePlanTitle => 'تغيير الخطة';

  @override
  String get changePlanCurrentPlan => 'الخطة الحالية';

  @override
  String get changePlanAvailablePlans => 'الخطط المتاحة';

  @override
  String changePlanRenewsOn(String date) {
    return 'يتجدد الاشتراك في $date';
  }

  @override
  String get changePlanLoadFailed =>
      'تعذّر تحميل المعلومات. يرجى المحاولة مرة أخرى.';

  @override
  String get changePlanRetry => 'إعادة المحاولة';

  @override
  String get changePlanConfirmTitle => 'هل تريد تغيير الخطة؟';

  @override
  String get changePlanConfirmBody =>
      'يسري تغيير الخطة في تاريخ الفوترة التالي.';

  @override
  String get changePlanConfirmOk => 'تأكيد';

  @override
  String get changePlanConfirmCancel => 'الاحتفاظ بالخطة الحالية';

  @override
  String get changePlanOldPurchaseMissing =>
      'تعذّر العثور على اشتراك نشط لتغييره. حاول مرة أخرى بعد تفعيل اشتراكك.';

  @override
  String get changePlanChangeRequested =>
      'تم طلب تغيير الخطة. قد يُطبّق في تاريخ الفوترة التالي.';

  @override
  String get cefrLevelTitle => 'اختر مستواك في اللغة الإنجليزية';

  @override
  String get cefrLevelAbsoluteBeginner => 'مبتدئ تمامًا';

  @override
  String get cefrLevelBeginner => 'مبتدئ';

  @override
  String get cefrLevelBasic => 'أساسي';

  @override
  String get cefrLevelIntermediate => 'متوسط';

  @override
  String get firstCefrLevelTitle => 'ما مستواك في اللغة الإنجليزية؟';

  @override
  String get firstCefrLevelDescriptionPreA1 => 'أستطيع قراءة الإنجليزية';

  @override
  String get firstCefrLevelDescriptionA1 =>
      'أعرف التحيات الأساسية والعبارات البسيطة';

  @override
  String get firstCefrLevelDescriptionA2 =>
      'أستطيع استخدام جمل قصيرة وبسيطة وفهمها';

  @override
  String get firstCefrLevelDescriptionB1 =>
      'أستطيع التعبير عن رأيي والمشاركة في المحادثات اليومية';

  @override
  String get firstCefrLevelSettingsHint => 'يمكنك تغييره في أي وقت';

  @override
  String get firstCefrLevelConfirm => 'تأكيد';

  @override
  String get feedbackPlaceholder =>
      'شاركنا أفكارك أو اقتراحاتك أو أي مشكلات واجهتها...';

  @override
  String get feedbackSend => 'إرسال';

  @override
  String get feedbackSuccess => 'شكرًا لك على ملاحظاتك.';

  @override
  String get microphonePermissionDenied =>
      'لا يمكن البدء من دون إذن الميكروفون.';

  @override
  String get holdMicrophoneToSpeak => 'اضغط مطولًا على الميكروفون للتحدث';

  @override
  String get roleplayTypeMessagePlaceholder => 'اكتب رسالتك...';

  @override
  String get yourTurnFirst => 'ابدأ أنت أولًا!';

  @override
  String get sayLineBelowToStart => 'قل العبارة أدناه للبدء.';

  @override
  String get roleplayExitWait => 'انتظر!';

  @override
  String get roleplayExitMessage =>
      'إذا غادرت الآن، فستفوتك المكافأة. هل أنت متأكد من رغبتك في المغادرة؟';

  @override
  String get roleplayExitKeepPlaying => 'متابعة اللعب';

  @override
  String get roleplayExitExit => 'خروج';

  @override
  String get roleplayAutoHint => 'تلميح تلقائي';

  @override
  String get roleplayHintLabel => 'تلميح';

  @override
  String get roleplayHintShowAnswer => 'اضغط لعرض الإجابة المقترحة بالإنجليزية';

  @override
  String get roleplayVoiceSpeed => 'سرعة الصوت';

  @override
  String get roleplayEndedFailed => 'فشلت المهمة...';

  @override
  String get roleplayEndedComplete => 'اكتمل تمثيل الأدوار';

  @override
  String get roleplayEndedEnding => 'جارٍ الانتقال إلى النهاية...';

  @override
  String get roleplayFinishNotEnoughProgress => 'التقدم غير كافٍ';

  @override
  String get roleplayFinishCompleted => 'اكتمل تمثيل الأدوار';

  @override
  String get roleplayFinishMovingToEnding => 'جارٍ الانتقال إلى النهاية...';

  @override
  String get roleplayAnalyzing => 'جارٍ تحليل أدائك في تمثيل الأدوار...';

  @override
  String get roleplayOpeningAiCharacter => 'شخصية الذكاء الاصطناعي';

  @override
  String get roleplayOpeningScenario => 'السيناريو';

  @override
  String get roleplayOpeningAiDisclaimer =>
      'قد يخطئ الذكاء الاصطناعي.\nيرجى عدم مشاركة معلومات شخصية أو حساسة.';

  @override
  String get endingFailTitle => 'لم تُكمل جميع المهام!';

  @override
  String get endingFailSubtitle => 'حاول مرة أخرى لاكتشاف القصة كاملة.';

  @override
  String get roleplayTryAgainMessage =>
      'للأسف، لم تكن نتيجتك عالية بما يكفي للحصول على المكافأة.';

  @override
  String get endingReport => 'الإبلاغ عن مشكلة';

  @override
  String get endingHowWas => 'كيف كانت تجربة تمثيل الأدوار؟';

  @override
  String get endingNext => 'التالي';

  @override
  String get reportTitle => 'الإبلاغ عن مشكلة';

  @override
  String get profileHistory => 'السجل';

  @override
  String get profileSaved => 'المحفوظات';

  @override
  String get profileHistoryEmpty => 'لا يوجد سجل بعد';

  @override
  String get profileSavedEmpty => 'لا توجد عبارات محفوظة بعد.';

  @override
  String get profileSavedRemoveTitle =>
      'هل تريد إزالة هذه العبارة من المحفوظات؟';

  @override
  String get profileSavedRemoveContent =>
      'يمكنك العثور عليها مجددًا في السجل لاحقًا.';

  @override
  String get profileSavedRemoveOk => 'إزالة';

  @override
  String get profileSavedRemoveCancel => 'التدرّب أكثر';

  @override
  String get seriesOverviewTabEpisodes => 'الحلقات';

  @override
  String get seriesOverviewTabSimilarTopic => 'موضوع مشابه';

  @override
  String seriesOverviewEpisodeNumber(int number) {
    return 'الحلقة #$number';
  }

  @override
  String get seriesOverviewPlay => 'ابدأ';

  @override
  String get seriesOverviewLocked => 'مقفل';

  @override
  String get seriesOverviewEpisodeLockedToast =>
      'أكمل الحلقة السابقة لفتح هذه الحلقة.';

  @override
  String get notificationPermissionBlockedTitle => 'الإشعارات متوقفة';

  @override
  String get notificationPermissionBlockedMessage =>
      'فعّل الإشعارات من إعدادات جهازك لتلقي الإشعارات الفورية.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد';

  @override
  String get notificationSendToday => 'اليوم';

  @override
  String get notificationSendOneDayAgo => 'قبل يوم واحد';

  @override
  String notificationSendDaysAgo(int count) {
    return 'قبل $count أيام';
  }

  @override
  String get reregistrationRestrictedMessage =>
      'يمكنك التسجيل مجددًا بعد يومين من حذف حسابك. يرجى المحاولة لاحقًا.';

  @override
  String get expressionSavedToProfile => 'تم الحفظ في ملفك الشخصي';

  @override
  String get expressionUnsavedToProfile => 'أُلغي الحفظ';

  @override
  String get roleplayResultFeedbackInsufficientWords =>
      'لم نتمكن من تقديم ملاحظات هذه المرة. حاول أن تجعل إجابتك 7 كلمات أو أكثر!';

  @override
  String get roleplayResultScoreMeaning => 'المعنى';

  @override
  String get roleplayResultScoreRelevance => 'مدى الصلة';

  @override
  String get roleplayResultScoreVocabulary => 'المفردات';

  @override
  String get roleplayResultScoreGrammar => 'القواعد';

  @override
  String get closePopup => 'إغلاق';

  @override
  String get reviewChatTapHint => 'اضغط على فقاعة الدردشة لتشغيل الصوت.';

  @override
  String get reviewChatNoAudioToPlay => 'لا يوجد صوت لتشغيله.';

  @override
  String get seriesInformationTopicDifficulty => 'صعوبة الموضوع';

  @override
  String get seriesInformationLearningGoals => 'أهداف التعلم';

  @override
  String get energyInfoTitle => 'الطاقة';

  @override
  String get energyOutOfEnergyTitle => 'نفدت الطاقة';

  @override
  String get energyInfoRechargeUntil => 'إعادة الشحن التالية بعد @@TIME@@';

  @override
  String get energyInfoFull => 'طاقتك ممتلئة.';

  @override
  String get energyInfoUnlimitedEndsIn => 'وضع اللعب غير المحدود مفعّل';

  @override
  String get energyInsufficient => 'ليس لديك طاقة كافية.';

  @override
  String get endRoleplay => 'إنهاء تمثيل الأدوار';

  @override
  String get energyEnablePushTitle => 'تفعيل الإشعارات';

  @override
  String get energyEnablePushSubtitle =>
      'فعّل الإشعارات وأعد تعبئة طاقتك بالكامل.';

  @override
  String get energyEnablePushPrice => 'مجاني';

  @override
  String get energyEnablePushOfferBadge => 'عرض لمرة واحدة';

  @override
  String get energyEnablePushCompleted => 'تمت إعادة تعبئة الطاقة!';

  @override
  String get energyPurchaseUnlimitedTitle => 'بطاقة اللعب غير المحدود';

  @override
  String get energyPurchaseUnlimitedSubtitle =>
      'يبدأ فور إتمام الشراء. صالح لمدة 10 دقائق.';

  @override
  String get energyPurchaseCapacityTitle => 'ترقية الحد الأقصى للطاقة';

  @override
  String get energyPurchaseCapacitySubtitle =>
      'زِد الحد الأقصى للطاقة القابلة لإعادة الشحن بمقدار 1 بشكل دائم.';

  @override
  String get energyGoPremiumTitle => 'الترقية إلى Premium';

  @override
  String get energyGoPremiumExplore => 'استكشاف';

  @override
  String get profileGoPremiumTitle => 'احصل على SUDA Premium';

  @override
  String get profileGoPremiumExplore => 'استكشاف';

  @override
  String get energyPurchasePendingApproval => 'دفعتك في انتظار الموافقة';

  @override
  String get energyPurchaseNotCompleted => 'لم تكتمل عملية الشراء.';

  @override
  String get welcomeGiftTitle => 'وصلت هدية الترحيب!';

  @override
  String get welcomeGiftBenefitLead => 'استمتع بلعب غير محدود لمدة 10 دقائق!';

  @override
  String get welcomeGiftLine2 => 'تم فتح ميزات Premium';

  @override
  String get welcomeGiftLine3 => 'تم فتح اللعب غير المحدود';

  @override
  String get welcomeGiftStartNow => 'ابدأ الآن';

  @override
  String get paywallHeroTitle1 => 'تدرّب أكثر';

  @override
  String get paywallHeroTitle2 => 'تحسّن بشكل أسرع';

  @override
  String get paywallHeroBody =>
      'تدرّب لفترة أطول مع Premium واحصل على ملاحظات من الذكاء الاصطناعي لتعزيز ثقتك في استخدام الإنجليزية.';

  @override
  String get paywallPremiumLabel => 'PREMIUM';

  @override
  String get paywallBenefitDailyPractice => 'مزيد من التدريب اليومي';

  @override
  String get paywallBenefitMaxEnergy => 'حد أقصى للطاقة يصل إلى 30';

  @override
  String get paywallBenefitAiFeedback => 'ملاحظات الذكاء الاصطناعي على الجمل';

  @override
  String get paywallChoosePlan => 'اختر خطتك';

  @override
  String get paywallAnnualPlanTitle => 'الخطة السنوية';

  @override
  String get paywallAnnualPlanSubtitle =>
      'وفّر أكثر من 33% مقارنة بالخطة الشهرية.';

  @override
  String get paywallMonthlyPlanTitle => 'الخطة الشهرية';

  @override
  String get paywallMonthlyPlanSubtitle => 'اشتراك شهري مرن.';

  @override
  String get paywallBestBadge => 'الأفضل';

  @override
  String get paywallCta => 'ابدأ الآن';

  @override
  String get paywallAutoRenewNotice =>
      'تتجدد الاشتراكات تلقائيًا ما لم تُلغَ قبل 24 ساعة على الأقل من نهاية فترة الفوترة الحالية.';

  @override
  String paywallPricePerMonth(String price) {
    return '$price/شهر';
  }

  @override
  String paywallPricePerYear(String price) {
    return '$price/سنة';
  }

  @override
  String get paywallFallbackAnnualPerMonth => '\$8.33';

  @override
  String get paywallFallbackAnnual => '\$99.99';

  @override
  String get paywallFallbackMonthly => '\$13.99';

  @override
  String get paywallCompletedTitle => 'تهانينا!';

  @override
  String get paywallCompletedBody => 'مزايا Premium مفعّلة الآن.';

  @override
  String get paywallCompletedContinue => 'متابعة';

  @override
  String get roleplayChooseYourRole => 'اختر دورك';

  @override
  String get roleplaySimilarRoleplays => 'تمثيل أدوار مشابه';

  @override
  String get roleplayBeingPrepared => 'تمثيل الأدوار هذا قيد الإعداد.';

  @override
  String get roleplayUnlockPreviousRole =>
      'أكمل جميع نهايات الدور السابق لإلغاء قفل هذا الدور.';

  @override
  String seriesOverviewCompletionPercent(int percent) {
    return 'اكتمل $percent٪';
  }

  @override
  String get roleplayTurnGradeA => 'واو!';

  @override
  String get roleplayTurnGradeB => 'حسنًا!';

  @override
  String get roleplayTurnGradeC => 'همم…';

  @override
  String get roleplayTurnGradeD => 'أوه…';
}
