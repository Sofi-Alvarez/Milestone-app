import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/budgets_repository.dart';
import 'data/goals_repository.dart';
import 'data/transactions_repository.dart';
import 'data/user_settings.dart';
import 'features/auth/auth_service.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/shell/main_shell.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

/// El onboarding (magic link) sigue en modo demo porque el envío de email
/// real está bloqueado (cupo de Firebase agotado, SMTP sin configurar).
/// Esto es independiente de Firestore/Metas, que ya usan Firebase real
/// con un usuario anónimo (ver `_ensureUid` más abajo). Volver a `false`
/// cuando el envío de magic link funcione de nuevo.
const kForceDemoAuth = true;

/// Tema global — vive fuera del árbol de widgets para que Perfil pueda
/// cambiarlo sin tener que atravesar toda la jerarquía con callbacks.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RestartWidget(child: AppBootstrap()));
}

/// Garantiza un usuario de Firebase Auth (anónimo si no hay sesión real)
/// para que Firestore tenga un uid dueño de los datos de las metas.
/// Esto NO afecta el flujo de onboarding — esa UI usa su propia instancia
/// de [AuthService], que en modo demo ignora a Firebase por completo.
Future<String?> _ensureUid() async {
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser!.uid;
    final credential = await auth.signInAnonymously();
    return credential.user?.uid;
  } catch (_) {
    return null;
  }
}

/// Permite reiniciar toda la app desde adentro (usado por "Cerrar
/// sesión" y "Eliminar cuenta" en Perfil): remonta [child] con una key
/// nueva, lo que fuerza a [AppBootstrap] a volver a resolver el uid de
/// Firebase Auth desde cero.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?._restart();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}

/// Resuelve el uid de Firebase Auth y arma los repositorios antes de
/// mostrar la app. Se remonta entero cuando [RestartWidget.restartApp]
/// se dispara, así que un uid nuevo (tras cerrar sesión o eliminar la
/// cuenta) se refleja en toda la app sin reiniciar el proceso.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<String?> _uidFuture = _ensureUid();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _uidFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final uid = snapshot.data;
        final demoAuth = kForceDemoAuth ? null : FirebaseAuth.instance;
        return HitoApp(
          authService: AuthService(demoAuth),
          goalsRepository: uid == null ? null : GoalsRepository(uid),
          transactionsRepository: uid == null ? null : TransactionsRepository(uid),
          settingsRepository: uid == null ? null : UserSettingsRepository(uid),
          budgetsRepository: uid == null ? null : BudgetsRepository(uid),
        );
      },
    );
  }
}

class HitoApp extends StatelessWidget {
  const HitoApp({
    super.key,
    required this.authService,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.budgetsRepository,
  });

  final AuthService authService;
  final GoalsRepository? goalsRepository;
  final TransactionsRepository? transactionsRepository;
  final UserSettingsRepository? settingsRepository;
  final BudgetsRepository? budgetsRepository;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Milestone',
          theme: HitoTheme.light(),
          darkTheme: HitoTheme.dark(),
          themeMode: themeMode,
          home: RootScreen(
            authService: authService,
            goalsRepository: goalsRepository,
            transactionsRepository: transactionsRepository,
            settingsRepository: settingsRepository,
            budgetsRepository: budgetsRepository,
          ),
        );
      },
    );
  }
}

/// Decide entre onboarding y home, y captura el magic link entrante.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.authService,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.budgetsRepository,
  });

  final AuthService authService;
  final GoalsRepository? goalsRepository;
  final TransactionsRepository? transactionsRepository;
  final UserSettingsRepository? settingsRepository;
  final BudgetsRepository? budgetsRepository;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  late final _authService = widget.authService;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;

  /// Si ya había sesión al abrir la app (usuario recurrente), nos saltamos
  /// el onboarding directo. Esto se decide una sola vez, al arrancar.
  late final bool _returningUser = _authService.currentUser != null;

  /// true cuando el link se confirmó (mismo dispositivo o, en web, otra
  /// pestaña con la misma sesión) — dispara la pantalla "Todo listo",
  /// pero NO entra a Home todavía.
  bool _readyForAllDone = false;

  /// true solo cuando el usuario toca "Entrar a Milestone".
  bool _enteredHome = false;

  bool _skippedInitialAuthEvent = false;

  @override
  void initState() {
    super.initState();
    // authStateChanges replica el valor actual al suscribirse; lo ignoramos
    // una vez porque ya lo capturamos en _returningUser.
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (!_skippedInitialAuthEvent) {
        _skippedInitialAuthEvent = true;
        return;
      }
      if (user != null) setState(() => _readyForAllDone = true);
    });
    _listenForMagicLink();
  }

  void _listenForMagicLink() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      final link = uri.toString();
      if (!_authService.isSignInLink(link)) return;

      final email = await _authService.consumePendingEmail();
      if (email == null) return;
      // El authStateChanges de arriba se encarga de mostrar "Todo listo".
      await _authService.signInWithMagicLink(email: email, link: link);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_returningUser || _enteredHome) {
      return HomePlaceholder(
        goalsRepository: widget.goalsRepository,
        transactionsRepository: widget.transactionsRepository,
        settingsRepository: widget.settingsRepository,
        budgetsRepository: widget.budgetsRepository,
      );
    }
    return OnboardingFlow(
      authService: _authService,
      // En modo real, allDone se dispara al confirmar el link (mismo
      // dispositivo o sync entre pestañas). En modo demo, OnboardingFlow
      // se auto-avanza solo (ver onLinkSent en onboarding_flow.dart).
      linkConfirmed: _readyForAllDone,
      onComplete: () => setState(() => _enteredHome = true),
    );
  }
}

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.budgetsRepository,
  });

  final GoalsRepository? goalsRepository;
  final TransactionsRepository? transactionsRepository;
  final UserSettingsRepository? settingsRepository;
  final BudgetsRepository? budgetsRepository;

  @override
  Widget build(BuildContext context) {
    if (goalsRepository == null ||
        transactionsRepository == null ||
        settingsRepository == null ||
        budgetsRepository == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No pudimos conectar con la base de datos. '
              'Revisá que Firestore y el sign-in anónimo estén '
              'habilitados en la consola de Firebase.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return MainShell(
      goalsRepository: goalsRepository!,
      transactionsRepository: transactionsRepository!,
      settingsRepository: settingsRepository!,
      budgetsRepository: budgetsRepository!,
    );
  }
}
