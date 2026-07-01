import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/budgets_repository.dart';
import '../../data/goals_repository.dart';
import '../../data/transactions_repository.dart';
import '../../data/user_settings.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirm_dialog.dart';

/// Perfil: acá vive la configuración real de la app — nombre, tema,
/// qué notificaciones ver, y las acciones de cuenta (cerrar sesión /
/// eliminar cuenta). Todo interactivo y persistido en Firestore, nada
/// decorativo.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.goalsRepository,
    required this.transactionsRepository,
    required this.settingsRepository,
    required this.budgetsRepository,
  });

  final GoalsRepository goalsRepository;
  final TransactionsRepository transactionsRepository;
  final UserSettingsRepository settingsRepository;
  final BudgetsRepository budgetsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: pageColor(theme),
      appBar: AppBar(
        backgroundColor: pageColor(theme),
        elevation: 0,
        title: const Text('Perfil'),
        centerTitle: false,
      ),
      body: StreamBuilder<UserSettings>(
        stream: settingsRepository.watchSettings(),
        builder: (context, snapshot) {
          final settings = snapshot.data ?? UserSettings.empty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              HitoSpacing.md,
              HitoSpacing.lg,
              HitoSpacing.md,
              HitoSpacing.xxl,
            ),
            children: [
              _ProfileHeader(name: settings.name, settingsRepository: settingsRepository),
              const SizedBox(height: HitoSpacing.lg),
              _SectionLabel('Cuenta'),
              const SizedBox(height: HitoSpacing.sm),
              _SettingsCard(
                children: [
                  _ActionRow(
                    icon: Icons.badge_outlined,
                    label: 'Nombre',
                    trailing: settings.name.isEmpty ? 'Sin definir' : settings.name,
                    onTap: () => _editName(context, settingsRepository, settings.name),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.lg),
              _SectionLabel('Apariencia'),
              const SizedBox(height: HitoSpacing.sm),
              _SettingsCard(
                children: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (context, mode, _) => _SwitchRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Tema oscuro',
                      value: mode == ThemeMode.dark,
                      onChanged: (v) => themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.lg),
              _SectionLabel('Notificaciones'),
              const SizedBox(height: HitoSpacing.sm),
              _SettingsCard(
                children: [
                  _SwitchRow(
                    icon: Icons.edit_note_outlined,
                    label: 'Recordatorio para registrar',
                    subtitle: 'Avisa si hace tiempo que no registrás movimientos',
                    value: settings.notifyRegisterReminder,
                    onChanged: (v) =>
                        settingsRepository.updateNotificationPref('notifyRegisterReminder', v),
                  ),
                  const _RowDivider(),
                  _SwitchRow(
                    icon: Icons.summarize_outlined,
                    label: 'Resumen diario',
                    subtitle: 'Un resumen de tus ingresos y gastos del día',
                    value: settings.notifyDailySummary,
                    onChanged: (v) =>
                        settingsRepository.updateNotificationPref('notifyDailySummary', v),
                  ),
                  const _RowDivider(),
                  _SwitchRow(
                    icon: Icons.warning_amber_outlined,
                    label: 'Alertas de gasto',
                    subtitle: 'Cuando tu saldo cae por debajo del mínimo',
                    value: settings.notifySpendingAlerts,
                    onChanged: (v) =>
                        settingsRepository.updateNotificationPref('notifySpendingAlerts', v),
                  ),
                  const _RowDivider(),
                  _SwitchRow(
                    icon: Icons.savings_outlined,
                    label: 'Metas de ahorro',
                    subtitle: 'Cuando alcanzás una meta de ahorro',
                    value: settings.notifySavingsGoals,
                    onChanged: (v) =>
                        settingsRepository.updateNotificationPref('notifySavingsGoals', v),
                  ),
                ],
              ),
              const SizedBox(height: HitoSpacing.xl),
              // Acciones sensibles de cuenta — siempre al final del scroll,
              // separadas del resto de la configuración para que no se
              // toquen sin querer.
              _SettingsCard(
                children: [
                  _ActionRow(
                    icon: Icons.logout,
                    label: 'Cerrar sesión',
                    onTap: () => _confirmSignOut(context),
                  ),
                  const _RowDivider(),
                  _ActionRow(
                    icon: Icons.delete_forever_outlined,
                    label: 'Eliminar cuenta',
                    labelColor: theme.colorScheme.error,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    UserSettingsRepository repo,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribí tu nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await repo.updateName(result);
    if (context.mounted) showAppSnackBar(context, 'Nombre actualizado');
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Vas a volver a la pantalla de bienvenida. Tus datos quedan guardados '
          'para la próxima vez que entres desde este dispositivo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (context.mounted) RestartWidget.restartApp(context);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final firstConfirm = await confirmDialog(
      context,
      title: '¿Eliminar cuenta?',
      body: 'Se van a borrar todas tus metas, movimientos, registros y pagos '
          'programados. Esta acción no se puede deshacer.',
      confirmLabel: 'Continuar',
      destructive: true,
    );
    if (!firstConfirm || !context.mounted) return;

    final typedController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmá escribiendo ELIMINAR'),
          content: TextField(
            controller: typedController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'ELIMINAR'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: typedController.text.trim().toUpperCase() == 'ELIMINAR'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Eliminar todo'),
            ),
          ],
        ),
      ),
    );
    if (secondConfirm != true || !context.mounted) return;

    try {
      await goalsRepository.deleteAllData();
      await transactionsRepository.deleteAllData();
      await budgetsRepository.deleteAllData();
      await settingsRepository.deleteProfile();
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }
      if (context.mounted) RestartWidget.restartApp(context);
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, 'No pudimos eliminar la cuenta: $e', isError: true);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.settingsRepository});

  final String name;
  final UserSettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HitoSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(24),
        boxShadow: cardShadow(),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: initial != null
                ? Text(
                    initial,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : Icon(Icons.person_outline, size: 32, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: HitoSpacing.sm),
          Text(
            name.isEmpty ? 'Sin nombre' : name,
            style: theme.textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: HitoSpacing.xs),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: BorderRadius.circular(HitoRadius.lg),
        boxShadow: cardShadow(),
      ),
      child: Column(children: children),
    );
  }
}

/// Divisor indentado a la altura del texto (no del ícono) — mismo patrón
/// que usan las listas de cards en Ahorro, más prolijo que una línea a
/// todo el ancho.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: HitoSpacing.md + 20 + HitoSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: theme.colorScheme.outline.withValues(alpha: 0.15),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md, vertical: HitoSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: labelColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: HitoSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: labelColor),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(width: HitoSpacing.xs),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HitoSpacing.md, vertical: HitoSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: HitoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
