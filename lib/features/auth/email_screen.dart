import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'auth_service.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({
    super.key,
    required this.authService,
    required this.onBack,
    required this.onLinkSent,
  });

  final AuthService authService;
  final VoidCallback onBack;
  final ValueChanged<String> onLinkSent;

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Ingresá un email válido.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.sendMagicLink(email);
      widget.onLinkSent(email);
    } catch (e) {
      // TODO: quitar este print una vez resuelto el diagnóstico del envío real.
      debugPrint('sendMagicLink failed: $e');
      setState(() => _error = 'No pudimos enviar el link. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(height: HitoSpacing.lg),
              Center(
                child: Icon(
                  Icons.mail_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: HitoSpacing.lg),
              Text('Entra sin contraseñas', style: theme.textTheme.headlineLarge),
              const SizedBox(height: HitoSpacing.sm),
              Text(
                'Te enviaremos un enlace a tu correo. Tocás, y ya estás dentro.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: HitoSpacing.xl),
              Text('Ingresá correo electrónico', style: theme.textTheme.labelLarge),
              const SizedBox(height: HitoSpacing.sm),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'tu@correo.com',
                  suffixIcon: _emailController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_emailController.clear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: HitoSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: HitoSpacing.xs),
                  Expanded(
                    child: Text(
                      'Sin contraseñas que recordar. Tu correo es tu clave.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: HitoSpacing.sm),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const Spacer(),
              Text(
                'Al continuar, aceptás nuestros Términos de Servicio y Privacidad.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: HitoSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _sendLink,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar enlace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
