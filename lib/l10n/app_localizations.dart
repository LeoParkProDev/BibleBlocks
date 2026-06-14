import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @navBlocks.
  ///
  /// In ko, this message translates to:
  /// **'블록뷰'**
  String get navBlocks;

  /// No description provided for @navChecklist.
  ///
  /// In ko, this message translates to:
  /// **'체크리스트'**
  String get navChecklist;

  /// No description provided for @navPlans.
  ///
  /// In ko, this message translates to:
  /// **'계획'**
  String get navPlans;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @loginTagline.
  ///
  /// In ko, this message translates to:
  /// **'성경 읽기 시각화'**
  String get loginTagline;

  /// No description provided for @loginKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인'**
  String get loginKakao;

  /// No description provided for @loginGuest.
  ///
  /// In ko, this message translates to:
  /// **'게스트로 시작'**
  String get loginGuest;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 표시 언어를 선택하세요'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 기본'**
  String get languageSystem;

  /// No description provided for @settingsShareTitle.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡으로 공유하기'**
  String get settingsShareTitle;

  /// No description provided for @settingsShareSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'3D 성경책과 진행도를 친구에게 공유해보세요'**
  String get settingsShareSubtitle;

  /// No description provided for @settingsModelTitle.
  ///
  /// In ko, this message translates to:
  /// **'3D 모델'**
  String get settingsModelTitle;

  /// No description provided for @settingsResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'진행도 초기화'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 읽기 기록을 삭제합니다'**
  String get settingsResetSubtitle;

  /// No description provided for @settingsDonateTitle.
  ///
  /// In ko, this message translates to:
  /// **'개발자 후원하기'**
  String get settingsDonateTitle;

  /// No description provided for @settingsDonateSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'BibleBlocks가 도움이 되셨다면 커피 한 잔 ☕'**
  String get settingsDonateSubtitle;

  /// No description provided for @settingsSourceTitle.
  ///
  /// In ko, this message translates to:
  /// **'성경 본문 출처'**
  String get settingsSourceTitle;

  /// No description provided for @skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// No description provided for @onbIntentTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 읽고 싶으세요?'**
  String get onbIntentTitle;

  /// No description provided for @onbIntentSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'마음에 드는 방식을 골라보세요. 언제든 바꿀 수 있어요.'**
  String get onbIntentSubtitle;

  /// No description provided for @onbIntentReadAll.
  ///
  /// In ko, this message translates to:
  /// **'통독'**
  String get onbIntentReadAll;

  /// No description provided for @onbIntentReadAllDesc.
  ///
  /// In ko, this message translates to:
  /// **'성경 전체를 천천히 끝까지'**
  String get onbIntentReadAllDesc;

  /// No description provided for @onbIntentDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일 한 장'**
  String get onbIntentDaily;

  /// No description provided for @onbIntentDailyDesc.
  ///
  /// In ko, this message translates to:
  /// **'부담 없이 하루 한 장씩'**
  String get onbIntentDailyDesc;

  /// No description provided for @onbIntentTopic.
  ///
  /// In ko, this message translates to:
  /// **'주제별 묵상'**
  String get onbIntentTopic;

  /// No description provided for @onbIntentTopicDesc.
  ///
  /// In ko, this message translates to:
  /// **'필요한 주제의 말씀으로'**
  String get onbIntentTopicDesc;

  /// No description provided for @onbPlanTitle.
  ///
  /// In ko, this message translates to:
  /// **'짧은 계획으로 시작해볼까요?'**
  String get onbPlanTitle;

  /// No description provided for @onbPlanSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'끝까지 읽을 확률이 가장 높은 단기 계획이에요.'**
  String get onbPlanSubtitle;

  /// No description provided for @onbPlanLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에 정할게요'**
  String get onbPlanLater;

  /// No description provided for @onbNotifTitle.
  ///
  /// In ko, this message translates to:
  /// **'매일 이 시간에 말씀 한 구절'**
  String get onbNotifTitle;

  /// No description provided for @onbNotifSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'잊지 않도록 부드럽게 알려드려요. 원치 않으면 건너뛰어도 돼요.'**
  String get onbNotifSubtitle;

  /// No description provided for @onbNotifChangeTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 변경'**
  String get onbNotifChangeTime;

  /// No description provided for @onbNotifEnable.
  ///
  /// In ko, this message translates to:
  /// **'알림 받기'**
  String get onbNotifEnable;

  /// No description provided for @onbFirstTitle.
  ///
  /// In ko, this message translates to:
  /// **'첫 블록을 채워볼까요?'**
  String get onbFirstTitle;

  /// No description provided for @onbFirstTitleDone.
  ///
  /// In ko, this message translates to:
  /// **'첫 블록이 채워졌어요! 🎉'**
  String get onbFirstTitleDone;

  /// No description provided for @onbFirstSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'창세기 1장을 읽음으로 체크하면 3D 성경책에 첫 블록이 들어갑니다.'**
  String get onbFirstSubtitle;

  /// No description provided for @onbFirstSubtitleDone.
  ///
  /// In ko, this message translates to:
  /// **'한 장을 읽을 때마다 이렇게 성경책이 블록으로 차올라요.'**
  String get onbFirstSubtitleDone;

  /// No description provided for @onbFirstCheck.
  ///
  /// In ko, this message translates to:
  /// **'창세기 1장 읽음 체크'**
  String get onbFirstCheck;

  /// No description provided for @onbStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onbStart;

  /// No description provided for @notesTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 노트·북마크'**
  String get notesTitle;

  /// No description provided for @notesSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'구절·메모 검색'**
  String get notesSearchHint;

  /// No description provided for @notesFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get notesFilterAll;

  /// No description provided for @notesFilterBookmark.
  ///
  /// In ko, this message translates to:
  /// **'북마크'**
  String get notesFilterBookmark;

  /// No description provided for @notesFilterNote.
  ///
  /// In ko, this message translates to:
  /// **'노트'**
  String get notesFilterNote;

  /// No description provided for @notesFilterHighlight.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get notesFilterHighlight;

  /// No description provided for @notesEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 표시한 구절이 없어요'**
  String get notesEmptyTitle;

  /// No description provided for @notesEmptySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'본문을 읽다가 절을 탭해 하이라이트·북마크·노트를 남겨보세요'**
  String get notesEmptySubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
