import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlowingLogoLoop extends StatefulWidget {
  const GlowingLogoLoop({super.key});

  @override
  State<GlowingLogoLoop> createState() => _GlowingLogoLoopState();
}

class _GlowingLogoLoopState extends State<GlowingLogoLoop>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          return Transform.scale(
            scale: _glow.value,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    const Color(0xFF448AFF).withOpacity(0.8),
                    const Color(0xFF448AFF).withOpacity(0.2),
                  ],
                  stops: const [0.0, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcATop,
              child: SvgPicture.asset(
                'assets/images/logo_brain.svg',
                width: 150,
                height: 150,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF448AFF),
                  BlendMode.srcIn,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
