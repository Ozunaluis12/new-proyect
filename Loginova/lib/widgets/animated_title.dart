import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Título animado del login: cada letra de "LOGINOVA" entra en cascada
/// (fade + deslizamiento hacia arriba) y luego un brillo diagonal recorre
/// el texto en bucle, usando el propio alfa de las letras como máscara
/// ([BlendMode.srcATop]) para que solo brille sobre los caracteres. El
/// subtítulo aparece justo después, con el mismo tipo de entrada. Le da al
/// título el mismo dinamismo que ya tiene el logo animado de al lado.
class AnimatedTitle extends StatefulWidget {
  final String title;
  final String subtitle;

  const AnimatedTitle({
    super.key,
    this.title = 'LOGINOVA',
    this.subtitle = 'Gestión Logística Profesional',
  });

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.title.split('');

    return Column(
      children: [
        AnimatedBuilder(
          animation: _shineController,
          builder: (context, child) {
            const band = 0.22;
            final center = -band + _shineController.value * (1 + band * 2);
            final stops = [
              (center - band).clamp(0.0, 1.0),
              center.clamp(0.0, 1.0),
              (center + band).clamp(0.0, 1.0),
            ];
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: const Alignment(-1.4, -1),
                end: const Alignment(1.4, 1),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
                stops: stops,
              ).createShader(bounds),
              child: child,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < letters.length; i++) ...[
                _AnimatedLetter(
                  letter: letters[i],
                  controller: _entryController,
                  index: i,
                  total: letters.length,
                ),
                if (i != letters.length - 1) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            final t = Curves.easeOut.transform(
              const Interval(0.55, 1.0).transform(_entryController.value),
            );
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 10),
                child: child,
              ),
            );
          },
          child: Text(
            widget.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: LoginovaColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Una letra del título con su propia entrada escalonada: [index]/[total]
/// determina cuándo, dentro de la animación compartida de [controller],
/// empieza a aparecer esta letra en particular (efecto cascada).
class _AnimatedLetter extends StatelessWidget {
  final String letter;
  final AnimationController controller;
  final int index;
  final int total;

  const _AnimatedLetter({
    required this.letter,
    required this.controller,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index / total) * 0.45;
    final end = (start + 0.5).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          Interval(start, end).transform(controller.value),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
        );
      },
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: LoginovaColors.primary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
