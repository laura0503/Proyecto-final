import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/profesor.dart';
import '../shared/profesor_avatar.dart';

class HomeEstadoDia extends StatefulWidget {
  final List<Profesor> profesores;
  final List<int> idsOcupados;

  const HomeEstadoDia({
    super.key,
    required this.profesores,
    required this.idsOcupados,
  });

  @override
  State<HomeEstadoDia> createState() => _HomeEstadoDiaState();
}

class _HomeEstadoDiaState extends State<HomeEstadoDia> {
  bool _verTodos = false;

  String _saludo(Profesor p) {
    final id = int.tryParse(p.id) ?? -1;
    if (p.estadoAusente) return 'Falta';
    if (widget.idsOcupados.contains(id)) return 'En Clase';
    return 'Presente';
  }

  Color _color(Profesor p) {
    if (p.estadoAusente) return const Color(0xFFEF4444);
    final id = int.tryParse(p.id) ?? -1;
    if (widget.idsOcupados.contains(id)) return const Color(0xFF3B82F6);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.72);

    final sorted = [...widget.profesores]
      ..sort((a, b) {
        if (a.estadoAusente && !b.estadoAusente) return -1;
        if (!a.estadoAusente && b.estadoAusente) return 1;
        return 0;
      });

    final visible = _verTodos ? sorted : sorted.take(5).toList();
    final extra = sorted.length - 5;

    final dia = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF354231).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.today_rounded, size: 18, color: Color(0xFF354231)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado del día',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            dia,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              ...visible.map((p) => _ProfesorRow(
                    profesor: p,
                    estado: _saludo(p),
                    color: _color(p),
                    isDark: isDark,
                  )),
              if (!_verTodos && extra > 0)
                InkWell(
                  onTap: () => setState(() => _verTodos = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Ver $extra más',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A6F54),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfesorRow extends StatelessWidget {
  final Profesor profesor;
  final String estado;
  final Color color;
  final bool isDark;

  const _ProfesorRow({
    required this.profesor,
    required this.estado,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          ProfesorAvatar(profesor: profesor, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profesor.nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profesor.asignatura,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              estado,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
