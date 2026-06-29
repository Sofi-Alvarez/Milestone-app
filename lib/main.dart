import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/goals_repository.dart';
import 'features/auth/auth_service.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/savings/savings_screen.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

/// El onboarding (magic link) sigue en modo demo porque el envío de email
/// real está bloqueado (cupo de Firebase agotado, SMTP sin configurar).
/// Esto es independiente de Firestore/Metas, que ya usan Firebase real
/// con un usuario anónimo (ver `_ensureUid` más abajo). Volver a `false`
/// cuando el envío de magic link funcione de nuevo.
const kForceDemoAuth = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final uid = await _ensureUid();
  final demoAuth = kForceDemoAuth ? null : FirebaseAuth.instance;

  runApp(HitoApp(
    authService: AuthService(demoAuth),
    goalsRepository: uid == null ? null : GoalsRepository(uid),
  ));
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

class HitoApp extends StatefulWidget {
  const HitoApp({
    super.key,
    required this.authService,
    required this.goalsRepository,
  });

  final AuthService authService;
  final GoalsRepository? goalsRepository;

  @override
  State<HitoApp> createState() => _HitoAppState();
}

class _HitoAppState extends State<HitoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milestone',
      theme: HitoTheme.light(),
      darkTheme: HitoTheme.dark(),
      themeMode: _themeMode,
      home: RootScreen(
        authService: widget.authService,
        goalsRepository: widget.goalsRepository,
      ),
      builder: (context, child) => Stack(
        children: [
          ?child,
          _ThemeModeToggle(
            themeMode: _themeMode,
            onToggle: _toggleThemeMode,
          ),
        ],
      ),
    );
  }
}

/// Botón de QA para alternar claro/oscuro mientras se revisa el sistema
/// visual en ambos modos. Arrastrable para no tapar botones del app bar.
/// Quitar antes de shippear.
class _ThemeModeToggle extends StatefulWidget {
  const _ThemeModeToggle({required this.themeMode, required this.onToggle});

  final ThemeMode themeMode;
  final VoidCallback onToggle;

  @override
  State<_ThemeModeToggle> createState() => _ThemeModeToggleState();
}

class _ThemeModeToggleState extends State<_ThemeModeToggle> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final screenSize = MediaQuery.of(context).size;
    final position = _position ?? Offset(screenSize.width - 56, 80);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final next = position + details.delta;
            _position = Offset(
              next.dx.clamp(0, screenSize.width - 48),
              next.dy.clamp(0, screenSize.height - 48),
            );
          });
        },
        child: Material(
          color: Colors.black87,
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              size: 20,
            ),
            onPressed: widget.onToggle,
          ),
        ),
      ),
    );
  }
}

/// Decide entre onboarding y home, y captura el magic link entrante.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.authService,
    required this.goalsRepository,
  });

  final AuthService authService;
  final GoalsRepository? goalsRepository;

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
      return HomePlaceholder(goalsRepository: widget.goalsRepository);
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

/// TODO: el Home (lib/features/home/) queda pendiente de revisión visual.
/// Mientras tanto, después del onboarding entramos directo a la sección de
/// Ahorro > Metas, que es el flujo que se está afinando ahora.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key, required this.goalsRepository});

  final GoalsRepository? goalsRepository;

  @override
  Widget build(BuildContext context) {
    if (goalsRepository == null) {
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
    return SavingsScreen(goalsRepository: goalsRepository!);
  }
}
