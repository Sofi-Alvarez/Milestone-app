import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'logo_mark.dart';
import 'pwa_install.dart';

/// Sheet "Milestone es mejor en la app" — mismo patrón que Facebook al
/// entrar desde el navegador: logo, copy corto de marca, CTA primario
/// (descargar) y uno secundario para descartarlo. Se muestra una sola
/// vez, justo al entrar a Home por primera vez tras el onboarding.
Future<void> showDownloadAppSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (context) => const _DownloadAppSheet(),
  );
}

class _DownloadAppSheet extends StatelessWidget {
  const _DownloadAppSheet();

  Future<void> _handleDownload(BuildContext context) async {
    if (isPwaInstallSupported) {
      // Chrome/Edge/Android: dispara el diálogo nativo del navegador
      // y espera la elección real del usuario.
      final accepted = await triggerPwaInstall();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (accepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Listo! Milestone ya está en tu pantalla de inicio.')),
        );
      }
      return;
    }
    // Safari/iOS y navegadores sin soporte para el diálogo automático
    // no exponen ninguna API — ahí solo se puede guiar al usuario.
    if (context.mounted) await _showManualInstructions(context);
  }

  Future<void> _showManualInstructions(BuildContext context) {
    Navigator.of(context).pop();
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar a la pantalla de inicio'),
        content: Text(
          isIOS
              ? 'Tocá el botón Compartir (⬆️) en la barra del navegador y '
                  'elegí "Agregar a inicio".'
              : 'Abrí el menú (⋮) de tu navegador y elegí "Instalar app" o '
                  '"Agregar a pantalla de inicio".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(HitoSpacing.lg, HitoSpacing.sm, HitoSpacing.lg, HitoSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(HitoRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: HitoSpacing.lg),
            const LogoMark(diameter: 64),
            const SizedBox(height: HitoSpacing.md),
            Text(
              'Milestone es mejor en la app',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: HitoSpacing.xs),
            Text(
              'Llevá tus metas y gastos siempre a mano, con notificaciones '
              'y acceso más rápido desde tu pantalla de inicio.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: HitoSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _handleDownload(context),
                child: const Text('Descargar app'),
              ),
            ),
            const SizedBox(height: HitoSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ahora no'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
