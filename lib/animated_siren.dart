import 'package:flutter/material.dart';

class AnimatedSiren extends StatefulWidget {
  const AnimatedSiren({Key? key}) : super(key: key);

  @override
  _AnimatedSirenState createState() => _AnimatedSirenState();
}

class _AnimatedSirenState extends State<AnimatedSiren> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Speed of the spinning light
    )..repeat(); // Continuous animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating red light effect
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.red.withOpacity(0.8),
                    Colors.red.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: [0.2, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Siren body
          Positioned(
            bottom: 20,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Inner bulb effect
          Positioned(
            bottom: 55,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
          // Black base
          Positioned(
            bottom: 0,
            child: Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
