import 'package:flutter/material.dart';

import '../themes/app_theme.dart';

/// Escena animada del logo de Loginova: la foto real del auto (Nissan GT-R
/// Liberty Walk, recortada sin fondo) avanzando sobre una carretera dibujada
/// a mano (CustomPainter) con líneas de carril que se desplazan, rebote de
/// suspensión, líneas de velocidad y un brillo que recorre la carrocería —
/// el efecto de "rodar" que pidió el usuario, con el auto integrado
/// directamente en la escena en vez de una foto enmarcada aparte. Incluye
/// nubes de fondo con parallax y una entrada deslizante al montarse.
class AnimatedLogo extends StatefulWidget {
  final double width;
  final double height;

  const AnimatedLogo({super.key, this.width = 260, this.height = 132});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  // Carretera + líneas de velocidad: mismo ritmo para que se vean
  // consistentes entre sí.
  late final AnimationController _motionController;
  // Nubes de fondo: mucho más lento, para dar sensación de profundidad.
  late final AnimationController _cloudController;
  // Rebote de suspensión al pasar baches.
  late final AnimationController _bounceController;
  // Brillo diagonal que recorre la carrocería de vez en cuando.
  late final AnimationController _shineController;
  // Entrada: el auto llega deslizándose desde la izquierda al montarse.
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _cloudController.dispose();
    _bounceController.dispose();
    _shineController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _motionController,
        _cloudController,
        _bounceController,
        _shineController,
        _entryController,
      ]),
      builder: (context, _) {
        final motion = _motionController.value; // 0..1, en bucle
        final bounce =
            Curves.easeInOut.transform(_bounceController.value) * 1.6;

        final entry = Curves.easeOutCubic.transform(_entryController.value);
        final slideX = (1 - entry) * -widget.width * 0.55;
        final fade = _entryController.value.clamp(0.0, 1.0);

        // Aspect ratio real de assets/images/gtr.png (foto recortada).
        const carAspect = 559 / 329;
        final carWidth = widget.width * 0.66;
        final carHeight = carWidth / carAspect;
        final roadHeight = widget.height * 0.24;

        return Opacity(
          opacity: fade,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFCDE9FB), Color(0xFFF3FAFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: LoginovaColors.primaryDark.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  // Sol/resplandor suave en la esquina, para que el cielo
                  // no se vea plano.
                  Positioned(
                    right: -widget.width * 0.12,
                    top: -widget.height * 0.25,
                    child: Container(
                      width: widget.width * 0.55,
                      height: widget.width * 0.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._buildClouds(_cloudController.value),
                  // Carretera con líneas de carril desplazándose.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: roadHeight,
                    child: CustomPaint(
                      painter: _RoadPainter(scroll: motion),
                      size: Size(widget.width, roadHeight),
                    ),
                  ),
                  // Líneas de velocidad a ambos lados del auto.
                  ..._buildSpeedLines(
                    motion,
                    centerX: widget.width * 0.5 + slideX,
                    bottom: roadHeight + carHeight * 0.42 - bounce,
                    carWidth: carWidth,
                  ),
                  // Sombra de contacto con el piso, debajo del auto.
                  Positioned(
                    left: widget.width * 0.5 - carWidth * 0.34 + slideX,
                    bottom: roadHeight - 2,
                    child: Container(
                      width: carWidth * 0.68,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.32),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // El auto: foto real recortada, con rebote de suspensión y
                  // brillo diagonal sobre la pintura.
                  Positioned(
                    left: widget.width * 0.5 - carWidth * 0.5 + slideX,
                    bottom: roadHeight - carHeight * 0.14 + bounce,
                    width: carWidth,
                    height: carHeight,
                    child: _CarPhoto(shine: _shineController.value),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildClouds(double t) {
    // Tres nubes a distinta altura/velocidad (parallax simple), que
    // recorren todo el ancho y reaparecen del otro lado sin salto visible
    // porque empiezan ya fuera del borde derecho.
    final specs = [
      (heightFactor: 0.14, sizeFactor: 0.30, speed: 1.0, opacity: 0.9),
      (heightFactor: 0.28, sizeFactor: 0.20, speed: 0.7, opacity: 0.7),
      (heightFactor: 0.08, sizeFactor: 0.16, speed: 1.3, opacity: 0.6),
    ];

    return List.generate(specs.length, (i) {
      final s = specs[i];
      final phase = (t * s.speed + i * 0.33) % 1.0;
      final left = widget.width * 1.15 - phase * widget.width * 1.5;
      final size = widget.width * s.sizeFactor;

      return Positioned(
        left: left,
        top: widget.height * s.heightFactor,
        child: Opacity(opacity: s.opacity, child: _CloudShape(size: size)),
      );
    });
  }

  List<Widget> _buildSpeedLines(
    double t, {
    required double centerX,
    required double bottom,
    required double carWidth,
  }) {
    final lines = <Widget>[];
    for (var side = -1; side <= 1; side += 2) {
      for (var i = 0; i < 3; i++) {
        final phase = (t + i * 0.28) % 1.0;
        final opacity = (1 - phase) * 0.5;
        final travel = phase * 16;
        final baseX = centerX + side * (carWidth * 0.5 + 4 + travel);

        lines.add(
          Positioned(
            left: side < 0 ? baseX - 18 : baseX,
            bottom: bottom - i * 8,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 16 - i * 2,
                height: 2.4,
                decoration: BoxDecoration(
                  color: LoginovaColors.primaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      }
    }
    return lines;
  }
}

/// Foto real del auto (recorte con fondo eliminado) con un brillo diagonal
/// que recorre solo la carrocería visible (usa el propio canal alfa de la
/// imagen como máscara vía [BlendMode.srcATop]) para sugerir reflejo de luz
/// en movimiento sin tocar el contenido de la foto.
class _CarPhoto extends StatelessWidget {
  final double shine;

  const _CarPhoto({required this.shine});

  @override
  Widget build(BuildContext context) {
    const band = 0.18;
    final center = -band + shine * (1 + band * 2);
    final stops = [
      (center - band).clamp(0.0, 1.0),
      center.clamp(0.0, 1.0),
      (center + band).clamp(0.0, 1.0),
    ];

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: const Alignment(-1.6, -1),
        end: const Alignment(1.6, 1),
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.55),
          Colors.transparent,
        ],
        stops: stops,
      ).createShader(bounds),
      child: Image.asset('assets/images/gtr.png', fit: BoxFit.contain),
    );
  }
}

/// Nube simple: tres círculos superpuestos, más barato que un path
/// complejo y se ve bien a este tamaño.
class _CloudShape extends StatelessWidget {
  final double size;
  const _CloudShape({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.6,
      height: size * 0.8,
      child: Stack(
        children: [
          Positioned(left: size * 0.25, top: 0, child: _bubble(size * 0.8)),
          Positioned(left: 0, top: size * 0.25, child: _bubble(size * 0.65)),
          Positioned(
            left: size * 0.75,
            top: size * 0.2,
            child: _bubble(size * 0.7),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double d) => Container(
    width: d,
    height: d,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

/// Carretera vista de perfil: asfalto con degradado (más claro cerca del
/// horizonte), franja de borde y líneas de carril discontinuas que se
/// desplazan con [scroll] (0..1, en bucle) para simular avance continuo.
class _RoadPainter extends CustomPainter {
  final double scroll;

  _RoadPainter({required this.scroll});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6B7785),
          LoginovaColors.textPrimary.withValues(alpha: 0.92),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, roadPaint);

    // Línea de horizonte: un borde más claro donde la carretera "empieza".
    final horizonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, 1), Offset(size.width, 1), horizonPaint);

    // Línea central discontinua, desplazándose para dar sensación de
    // movimiento hacia adelante.
    final dashPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    const dashWidth = 16.0;
    const dashGap = 12.0;
    const period = dashWidth + dashGap;
    // El auto de la foto mira hacia la izquierda (es su "adelante"), así que
    // el asfalto debe desplazarse de izquierda a derecha para leerse como
    // avance; con el signo invertido se veía como si fuera en reversa.
    final offsetX = (scroll * period * 2.4) % period;
    final laneY = size.height * 0.5;

    for (double x = offsetX - period; x < size.width + period; x += period) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, laneY - 1.5, dashWidth, 3),
          const Radius.circular(2),
        ),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.scroll != scroll;
}
