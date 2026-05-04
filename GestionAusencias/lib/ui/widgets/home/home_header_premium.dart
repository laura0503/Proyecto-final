
import 'package:flutter/material.dart';

import './fichaje_dialog.dart';

class HomeHeaderPremium extends StatelessWidget {
  final String nombre;
  final String fecha;
  final String saludo;

  const HomeHeaderPremium({
    super.key,
    required this.nombre,
    required this.fecha,
    required this.saludo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$saludo, Prof. $nombre",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fecha,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _actionButton(context, "Fichaje", const Color(0xFF4F46E5)),
            const SizedBox(width: 16),
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=prof'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, Color color) {
    return _AnimatedHeaderButton(
      label: label,
      color: color,
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.4),
          builder: (context) => FichajeDialog(profesorNombre: nombre),
        );
      },
    );
  }
}

class _AnimatedHeaderButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedHeaderButton({required this.label, required this.color, required this.onTap});

  @override
  State<_AnimatedHeaderButton> createState() => _AnimatedHeaderButtonState();
}

class _AnimatedHeaderButtonState extends State<_AnimatedHeaderButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
