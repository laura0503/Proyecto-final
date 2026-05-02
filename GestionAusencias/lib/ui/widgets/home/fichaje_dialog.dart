
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class FichajeDialog extends StatefulWidget {
  final String profesorNombre;
  
  const FichajeDialog({super.key, required this.profesorNombre});

  @override
  State<FichajeDialog> createState() => _FichajeDialogState();
}

class _FichajeDialogState extends State<FichajeDialog> {
  bool _isOnGuard = false;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  
  int _teachersOnGuard = 1;
  String _suggestedTeacher = "Elena Roa";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleGuard() {
    if (_isOnGuard) {
      _showEndGuardConfirmation();
    } else {
      _startGuard();
    }
  }

  void _startGuard() {
    setState(() {
      _isOnGuard = true;
      _elapsedTime = Duration.zero;
      _teachersOnGuard++;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
      });
    });
  }

  void _stopGuard() {
    _timer?.cancel();
    setState(() {
      _isOnGuard = false;
      _teachersOnGuard--;
    });
  }

  void _showEndGuardConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Finalizar Guardia", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(_teachersOnGuard > 1 
          ? "Hay otros profesores de guardia. ¿Estás seguro de que quieres salir?"
          : "¿Deseas finalizar tu turno de guardia?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopGuard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Finalizar"),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 550,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopStatus(),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildTimerSection(),
                        const SizedBox(height: 32),
                        _buildPrimaryButton(),
                        const SizedBox(height: 40),
                        _buildTeamSection(),
                        const SizedBox(height: 32),
                        _buildInfoSections(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      decoration: BoxDecoration(
        color: _isOnGuard ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isOnGuard ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: _isOnGuard ? [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 10)] : null,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isOnGuard ? "ESTÁS DE GUARDIA" : "NO ESTÁS DE GUARDIA",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
              color: _isOnGuard ? Colors.green[700] : Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            "Turno Actual: 09:00 - 10:00",
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        Text(
          "TIEMPO TRANSCURRIDO",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_elapsedTime),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w900,
            letterSpacing: -4,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return _AnimatedPressButton(
      onPressed: _toggleGuard,
      isOnGuard: _isOnGuard,
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Equipo en Turno",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$_teachersOnGuard profesores de guardia",
                style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTeamCard(
                name: widget.profesorNombre,
                time: _isOnGuard ? "Desde las ${DateFormat('HH:mm').format(DateTime.now().subtract(_elapsedTime))}" : "Fuera de turno",
                location: "Aula 204",
                isMe: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeamCard(
                name: "Prof. $_suggestedTeacher",
                time: "Sugerido (por karma)",
                location: "Turno Recomendado",
                isRecommended: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamCard({required String name, required String time, required String location, bool isMe = false, bool isRecommended = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF4F46E5).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? const Color(0xFF4F46E5).withOpacity(0.3) : (isRecommended ? Colors.blue.withOpacity(0.2) : Colors.grey[200]!),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18, 
            backgroundColor: isRecommended ? Colors.blue[50] : Colors.grey[200],
            child: Icon(isMe ? Icons.person : Icons.person_outline, size: 20, color: isMe ? Colors.indigo : Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                    child: const Text("RECOMENDADO", style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSections() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoCard(
            title: "Información de Aula",
            subtitle: "Aula 204 • Planta 2",
            icon: Icons.meeting_room_rounded,
            content: "Sustitución: Prof. Thorne (Física)\nNotas: Los alumnos deben continuar con la página 42 del libro de texto.",
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            title: "Instrucciones",
            subtitle: "Protocolo de Guardia",
            icon: Icons.list_alt_rounded,
            content: "• Revisar pasillos del bloque B cada 15 min.\n• Asegurar que el baño permanezca libre.",
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required String subtitle, required IconData icon, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 10, height: 1.5, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPressButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isOnGuard;

  const _AnimatedPressButton({required this.onPressed, required this.isOnGuard});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: widget.isOnGuard ? const Color(0xFFE11D48) : const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (widget.isOnGuard ? Colors.red : Colors.indigo).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isOnGuard ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Text(
                widget.isOnGuard ? "Finalizar Guardia" : "Iniciar Guardia",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
