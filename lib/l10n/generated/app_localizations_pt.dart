// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Inimigos da Bola';

  @override
  String get weeklySessionTitle => 'Racha de segunda — 03/06';

  @override
  String get weeklySessionPlaceTime => 'Arena X · 20:00';

  @override
  String get confirmedSectionTitle => 'Confirmados';

  @override
  String get waitlistSectionTitle => 'Lista de espera';

  @override
  String get declinedSectionTitle => 'Não vão';

  @override
  String get pendingSectionTitle => 'Pendentes';

  @override
  String get goingButtonLabel => 'Vou!';

  @override
  String get notGoingButtonLabel => 'Não vou';

  @override
  String get lastUpdatedLabel => 'Última atualização: 18:42';

  @override
  String confirmedCounter(int confirmed, int maxPlayers) {
    return '$confirmed de $maxPlayers confirmados';
  }

  @override
  String get monthlyPlayerLabel => 'Mensalista';

  @override
  String get casualPlayerLabel => 'Avulso';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginSubtitle =>
      'Use email e senha no primeiro acesso. Depois, o app poderá abrir com biometria ou senha.';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldError => 'Informe um email válido.';

  @override
  String get passwordFieldLabel => 'Senha';

  @override
  String get passwordFieldError => 'Informe sua senha.';

  @override
  String get loginButton => 'Entrar';

  @override
  String get loginSubmittingButton => 'Entrando...';

  @override
  String get homeMenuLabel => 'Início';

  @override
  String get guestAttendancesMenuLabel => 'Confirmações avulsas';

  @override
  String get playersMenuLabel => 'Jogadores';

  @override
  String get skillRatingsMenuLabel => 'Avaliar jogadores';

  @override
  String get teamsDrawMenuLabel => 'Sorteio';

  @override
  String get gameModeMenuLabel => 'Modo Jogo';

  @override
  String get statsMenuLabel => 'Stats';

  @override
  String get moreMenuLabel => 'Mais';

  @override
  String get settingsMenuLabel => 'Configurações';

  @override
  String get logoutMenuLabel => 'Sair';
}
