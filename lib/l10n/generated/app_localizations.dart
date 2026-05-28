import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Inimigos da Bola'**
  String get appTitle;

  /// No description provided for @weeklySessionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Racha de segunda — 03/06'**
  String get weeklySessionTitle;

  /// No description provided for @weeklySessionPlaceTime.
  ///
  /// In pt, this message translates to:
  /// **'Arena X · 20:00'**
  String get weeklySessionPlaceTime;

  /// No description provided for @confirmedSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirmados'**
  String get confirmedSectionTitle;

  /// No description provided for @waitlistSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lista de espera'**
  String get waitlistSectionTitle;

  /// No description provided for @declinedSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não vão'**
  String get declinedSectionTitle;

  /// No description provided for @pendingSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get pendingSectionTitle;

  /// No description provided for @goingButtonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vou!'**
  String get goingButtonLabel;

  /// No description provided for @notGoingButtonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Não vou'**
  String get notGoingButtonLabel;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Última atualização: 18:42'**
  String get lastUpdatedLabel;

  /// No description provided for @confirmedCounter.
  ///
  /// In pt, this message translates to:
  /// **'{confirmed} de {maxPlayers} confirmados'**
  String confirmedCounter(int confirmed, int maxPlayers);

  /// No description provided for @monthlyPlayerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mensalista'**
  String get monthlyPlayerLabel;

  /// No description provided for @casualPlayerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Avulso'**
  String get casualPlayerLabel;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Use email e senha no primeiro acesso. Depois, o app poderá abrir com biometria ou senha.'**
  String get loginSubtitle;

  /// No description provided for @emailFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get emailFieldLabel;

  /// No description provided for @emailFieldError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um email válido.'**
  String get emailFieldError;

  /// No description provided for @passwordFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordFieldLabel;

  /// No description provided for @passwordFieldError.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha.'**
  String get passwordFieldError;

  /// No description provided for @loginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginButton;

  /// No description provided for @loginSubmittingButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrando...'**
  String get loginSubmittingButton;

  /// No description provided for @homeMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeMenuLabel;

  /// No description provided for @guestAttendancesMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmações avulsas'**
  String get guestAttendancesMenuLabel;

  /// No description provided for @playersMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Jogadores'**
  String get playersMenuLabel;

  /// No description provided for @skillRatingsMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar jogadores'**
  String get skillRatingsMenuLabel;

  /// No description provided for @teamsDrawMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sorteio'**
  String get teamsDrawMenuLabel;

  /// No description provided for @gameModeMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modo Jogo'**
  String get gameModeMenuLabel;

  /// No description provided for @statsMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Stats'**
  String get statsMenuLabel;

  /// No description provided for @moreMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get moreMenuLabel;

  /// No description provided for @settingsMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsMenuLabel;

  /// No description provided for @logoutMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logoutMenuLabel;
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
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
