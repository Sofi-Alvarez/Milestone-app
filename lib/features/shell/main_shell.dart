import 'package:flutter/material.dart';

import '../../data/budgets_repository.dart';
import '../../data/goals_repository.dart';
import '../../data/transactions_repository.dart';
import '../../data/user_settings.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/download_app_sheet.dart';
import '../../widgets/pwa_install.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../register/register_screen.dart';
import '../savings/savings_screen.dart';

/// Shell de navegación principal: el bottom nav cambia entre las cinco
/// pantallas reales (Inicio, Ahorro, Registrar, Historial, Perfil).
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.budgetsRepository,
    this.showDownloadPrompt = false,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final UserSettingsRepository settingsRepository;
  final BudgetsRepository budgetsRepository;

  /// true solo la primera vez que se entra a Home tras completar el
  /// onboarding — dispara el sheet "Milestone es mejor en la app".
  final bool showDownloadPrompt;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // Cambia cada vez que se entra a Historial desde otra sección — fuerza
  // que RegistroView reconstruya su estado y los filtros/búsqueda queden
  // limpios en vez de arrastrarse entre visitas.
  int _historyVisit = 0;
  HistoryInitialView _historyInitialView = HistoryInitialView.registro;

  @override
  void initState() {
    super.initState();
    if (widget.showDownloadPrompt && !isPwaAlreadyInstalled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showDownloadAppSheet(context);
      });
    }
  }

  void _goTo(int index, {HistoryInitialView? historyView}) {
    setState(() {
      if (index == 3 && _index != 3) _historyVisit++;
      if (historyView != null) _historyInitialView = historyView;
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        goalsRepository: widget.goalsRepository,
        transactionsRepository: widget.transactionsRepository,
        settingsRepository: widget.settingsRepository,
        onViewHistory: () => _goTo(3),
        onOpenSavings: () => _goTo(1),
        onOpenHistoryStats: () =>
            _goTo(3, historyView: HistoryInitialView.estadistica),
      ),
      SavingsScreen(
        goalsRepository: widget.goalsRepository,
        transactionsRepository: widget.transactionsRepository,
        budgetsRepository: widget.budgetsRepository,
      ),
      RegisterScreen(
        transactionsRepository: widget.transactionsRepository,
        onDone: () => _goTo(0),
      ),
      HistoryScreen(
        key: ValueKey(_historyVisit),
        transactionsRepository: widget.transactionsRepository,
        initialView: _historyInitialView,
      ),
      ProfileScreen(
        goalsRepository: widget.goalsRepository,
        transactionsRepository: widget.transactionsRepository,
        settingsRepository: widget.settingsRepository,
        budgetsRepository: widget.budgetsRepository,
      ),
    ];

    // La pantalla de Registrar tiene su propia navegación (X para
    // volver, CTA que lleva a Home) — el bottom nav no aporta ahí y
    // compite visualmente con el CTA de guardar.
    const registerIndex = 2;
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _index == registerIndex
          ? null
          : HitoBottomNavBar(currentIndex: _index, onTap: _goTo),
    );
  }
}
