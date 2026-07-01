import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/logo_mark.dart';

/// Último dato que pedimos antes de entrar — así el Home puede saludar
/// con el nombre real en vez de un genérico "Bienvenido".
class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.onContinue, required this.onBack});

  final ValueChanged<String> onContinue;
  final VoidCallback onBack;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _controller.text.trim();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HitoSpacing.lg,
              vertical: HitoSpacing.xl,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const LogoMark(diameter: 72),
                const SizedBox(height: HitoSpacing.lg),
                Text(
                  '¿Cómo te llamamos?',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HitoSpacing.sm),
                Text(
                  'Así te vamos a saludar cada vez que abras Milestone.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: HitoSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: HitoSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: recessedColor(theme),
                    borderRadius: BorderRadius.circular(HitoRadius.md),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) {
                      if (name.isNotEmpty) widget.onContinue(name);
                    },
                    style: theme.textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      hintText: 'Tu nombre',
                      contentPadding: EdgeInsets.symmetric(
                        vertical: HitoSpacing.md,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: name.isEmpty
                        ? null
                        : () => widget.onContinue(name),
                    child: const Text('Continuar'),
                  ),
                ),
                const SizedBox(height: HitoSpacing.xs),
                TextButton(
                  onPressed: () => widget.onContinue(''),
                  child: const Text('Omitir por ahora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
