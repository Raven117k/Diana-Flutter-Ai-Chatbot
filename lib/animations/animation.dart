import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_animations/simple_animations.dart';

class BrainAssembleAnimation extends StatelessWidget {
  const BrainAssembleAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return RadialGradient(
              center: Alignment.center,
              radius: value,
              colors: [const Color(0xFF448AFF), Colors.transparent],
              stops: const [0.9, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Opacity(
            opacity: value,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/logo_brain.svg',
                width: 300,
                height: 300,
                colorFilter:
                    const ColorFilter.mode(Color.fromARGB(255, 24, 182, 255), BlendMode.srcIn),
              ),
            ),
          ),
        );
      },
    );
  }
}
