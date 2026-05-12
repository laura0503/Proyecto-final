import 'package:flutter/material.dart';

class FichajeAnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isOnGuard;
  final bool isLoading;

  const FichajeAnimatedButton({
    super.key,
    required this.onPressed,
    required this.isOnGuard,
    this.isLoading = false,
  });

  @override
  State<FichajeAnimatedButton> createState() => _FichajeAnimatedButtonState();
}

class _FichajeAnimatedButtonState extends State<FichajeAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  widget.isLoading
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : (widget.isOnGuard
                          ? [
                            const Color(0xFFFF3B30),
                            const Color(0xFFFF453A),
                          ]
                          : [
                            const Color(0xFF5856D6),
                            const Color(0xFF4F46E5),
                          ]),
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              if (!widget.isLoading)
                BoxShadow(
                  color: (widget.isOnGuard
                          ? const Color(0xFFFF3B30)
                          : const Color(0xFF5856D6))
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else ...[
                Icon(
                  widget.isOnGuard
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isOnGuard ? "Finalizar Guardia" : "Iniciar Guardia",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
