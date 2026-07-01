import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'auth_service.dart';

class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({
    super.key,
    required this.email,
    required this.authService,
    required this.onBack,
  });

  final String email;
  final AuthService authService;
  final VoidCallback onBack;

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await widget.authService.sendMagicLink(widget.email);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HitoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Volver',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const Spacer(flex: 2),
              Center(
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: HitoSpacing.lg),
              Text(
                'Revisá tu correo',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: HitoSpacing.sm),
              Text(
                'Enviamos un enlace para entrar a ${widget.email}. '
                'Abrilo desde este dispositivo para continuar.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _resending ? null : _resend,
                  child: const Text('Reenviar enlace'),
                ),
              ),
              const SizedBox(height: HitoSpacing.sm),
              Center(
                child: TextButton.icon(
                  onPressed: _resending ? null : _resend,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reenviar enlace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
