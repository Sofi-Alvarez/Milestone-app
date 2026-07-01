import 'package:flutter/material.dart';

import '../../data/user_settings.dart';
import '../auth/auth_service.dart';
import '../auth/check_email_screen.dart';
import '../auth/email_screen.dart';
import 'all_done_screen.dart';
import 'name_screen.dart';
import 'splash_screen.dart';
import 'theme_screen.dart';
import 'welcome_screen.dart';

enum _OnboardingStep { splash, welcome, email, checkEmail, allDone, name, theme }

/// Coordina las pantallas del onboarding (ver wireframe de Figma).
/// El paso `allDone` se alcanza cuando el usuario vuelve a la app
/// habiendo confirmado el magic link (ver RootScreen en main.dart) —
/// de ahí pasa a `name` y `theme` antes de entrar de verdad a Home.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.authService,
    required this.linkConfirmed,
    required this.onComplete,
    this.settingsRepository,
    this.themeModeNotifier,
  });

  final AuthService authService;
  final bool linkConfirmed;
  final VoidCallback onComplete;

  /// Si viene seteado, `name`/`theme` se guardan de verdad. En modo
  /// demo sin Firestore disponible puede venir null — en ese caso esos
  /// pasos igual se muestran, solo que no persisten nada.
  final UserSettingsRepository? settingsRepository;
  final ValueNotifier<ThemeMode>? themeModeNotifier;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  _OnboardingStep _step = _OnboardingStep.splash;
  String _email = '';

  @override
  void didUpdateWidget(OnboardingFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.linkConfirmed && !oldWidget.linkConfirmed) {
      setState(() => _step = _OnboardingStep.allDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _OnboardingStep.splash:
        return SplashScreen(
          onFinished: () => setState(() => _step = _OnboardingStep.welcome),
        );
      case _OnboardingStep.welcome:
        return WelcomeScreen(
          onContinue: () => setState(() => _step = _OnboardingStep.email),
        );
      case _OnboardingStep.email:
        return EmailScreen(
          authService: widget.authService,
          onBack: () => setState(() => _step = _OnboardingStep.welcome),
          onLinkSent: (email) {
            setState(() {
              _email = email;
              _step = _OnboardingStep.checkEmail;
            });
            // Modo demo: no hay link real para abrir, simulamos que el
            // usuario lo confirmó después de un instante.
            if (widget.authService.isDemoMode) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _step = _OnboardingStep.allDone);
              });
            }
          },
        );
      case _OnboardingStep.checkEmail:
        return CheckEmailScreen(
          email: _email,
          authService: widget.authService,
          onBack: () => setState(() => _step = _OnboardingStep.email),
        );
      case _OnboardingStep.allDone:
        return AllDoneScreen(
          onEnter: () => setState(() => _step = _OnboardingStep.name),
        );
      case _OnboardingStep.name:
        return NameScreen(
          onBack: () => setState(() => _step = _OnboardingStep.allDone),
          onContinue: (name) {
            if (name.isNotEmpty) widget.settingsRepository?.updateName(name);
            setState(() => _step = _OnboardingStep.theme);
          },
        );
      case _OnboardingStep.theme:
        // Sin repositorio de tema disponible (no debería pasar en la
        // práctica) saltamos directo a Home en vez de bloquear al
        // usuario en una pantalla que no puede hacer nada.
        final themeModeNotifier = widget.themeModeNotifier;
        if (themeModeNotifier == null) {
          widget.onComplete();
          return const SizedBox.shrink();
        }
        return ThemeScreen(
          themeModeNotifier: themeModeNotifier,
          onBack: () => setState(() => _step = _OnboardingStep.name),
          onFinish: widget.onComplete,
        );
    }
  }
}
