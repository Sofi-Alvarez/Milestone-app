import 'package:flutter/material.dart';

/// Entrada con fade + leve deslizamiento hacia arriba, escalonada por
/// [index] — para listas cortas (hasta ~10 ítems) donde algo nuevo
/// aparece o desaparece, como "Registros recientes" o "Registros
/// pendientes". Respeta la preferencia de "reducir movimiento": si está
/// activada, el contenido aparece directo, sin animación.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo la primera vez que este widget entra en pantalla — si el
    // stream vuelve a emitir y este mismo ítem sigue en su posición,
    // Flutter reutiliza el State y no se repite la animación.
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      Future.delayed(Duration(milliseconds: widget.index * 40), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(opacity);
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offset, child: widget.child),
    );
  }
}
