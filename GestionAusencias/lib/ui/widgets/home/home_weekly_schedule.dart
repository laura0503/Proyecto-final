import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/ausencia.dart';
import '../../../domain/usecases/guardar_observacion_usecase.dart';

class HomeWeeklySchedule extends StatefulWidget {
  final List<HorarioClase> horario;
  final List<Ausencia> ausencias;
  final List<HorarioClase> sustituciones;
  final Function(HorarioClase, DateTime) onAction;
  final int weekOffset;
  final void Function(int offset)? onWeekChanged;

  const HomeWeeklySchedule({
    super.key,
    required this.horario,
    this.ausencias = const [],
    this.sustituciones = const [],
    required this.onAction,
    this.weekOffset = 0,
    this.onWeekChanged,
  });

  @override
  State<HomeWeeklySchedule> createState() => _HomeWeeklyScheduleState();
}

class _HomeWeeklyScheduleState extends State<HomeWeeklySchedule> {
  final ScrollController _scrollController = ScrollController();
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    _weekOffset = widget.weekOffset;
  }

  @override
  void didUpdateWidget(HomeWeeklySchedule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekOffset != widget.weekOffset) {
      _weekOffset = widget.weekOffset;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const Color _accentColor = Color(0xFF4F46E5);
  static const Color _secondaryColor = Color(0xFF7C3AED);
  
  static const List<Color> _vibrantColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
  ];
 // Violeta
  static const _color = Color(0xFFA855F7);
  static const _diasLabel = [
    "", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"
  ];

  DateTime _fechaDeEstaSemana(int weekday) {
    final hoy = DateTime.now();
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    return DateTime(lunes.year, lunes.month, lunes.day + (weekday - 1) + (_weekOffset * 7));
  }

  int _weekdayDesdeDia(String dia) {
    const map = {
      "LUNES": 1, "MARTES": 2, "MIÉRCOLES": 3, "JUEVES": 4, "VIERNES": 5,
    };
    return map[dia.toUpperCase()] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    // Solo sustituciones asignadas a este profesor, sin duplicados
    final vistas = <String>{};
    final guardiasAsignadas = <HorarioClase>[];

    for (final s in widget.sustituciones) {
      final ausente = s.profesorAusente;
      if (ausente.isEmpty) continue;

      DateTime fecha = s.fecha ?? (() {
        final wd = _weekdayDesdeDia(s.dia);
        return wd > 0 ? _fechaDeEstaSemana(wd) : DateTime.now();
      })();

      final key = '${DateFormat('yyyy-MM-dd').format(fecha)}_${s.inicio}_$ausente';
      if (vistas.add(key)) guardiasAsignadas.add(s);
    }

    final Map<String, List<HorarioClase>> porDia = {};
    for (final s in guardiasAsignadas) {
      final fecha = s.fecha ?? _fechaDeEstaSemana(_weekdayDesdeDia(s.dia));
      final key = DateFormat('yyyy-MM-dd').format(fecha);
      porDia.putIfAbsent(key, () => []).add(s);
    }

    final semana = List.generate(5, (i) => _fechaDeEstaSemana(i + 1));
    return _buildWeeklyHorizontalView(semana, porDia, guardiasAsignadas.length);
  }

  Widget _buildWeeklyHorizontalView(List<DateTime> semana,
      Map<String, List<HorarioClase>> porDia, int totalAsignadas) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(totalAsignadas),
              Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...semana.map((fecha) {
                          final key = DateFormat('yyyy-MM-dd').format(fecha);
                          final sesiones = List<HorarioClase>.from(porDia[key] ?? [])
                            ..sort((a, b) => a.inicio.compareTo(b.inicio));
                          return _buildDayColumn(fecha, sesiones);
                        }),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: _accentColor, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Mi Agenda Semanal",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildWeekNavigator(),
              const SizedBox(width: 16),
              _buildWeekBadge(total),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBadge(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _accentColor, // Color sólido para resaltar
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        "$total guardias esta semana",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          _navButton(Icons.chevron_left, () {
            final next = _weekOffset - 1;
            setState(() => _weekOffset = next);
            widget.onWeekChanged?.call(next);
          }),
          const Text(" HOY ", style: TextStyle(color: _accentColor, fontWeight: FontWeight.w900, fontSize: 11)),
          _navButton(Icons.chevron_right, () {
            final next = _weekOffset + 1;
            setState(() => _weekOffset = next);
            widget.onWeekChanged?.call(next);
          }),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: _accentColor),
      ),
    );
  }

  Widget _buildDayColumn(DateTime fecha, List<HorarioClase> sesiones) {
    final hoy = DateTime.now();
    final isToday = fecha.day == hoy.day &&
        fecha.month == hoy.month &&
        fecha.year == hoy.year;

    final diaNombre = DateFormat('EEE', 'es').format(fecha).toUpperCase();
    final diaNumero = DateFormat('d MMM', 'es').format(fecha).toUpperCase();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Cabecera del día
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                Text(
                  diaNombre,
                  style: TextStyle(
                    color: isToday ? _accentColor : const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diaNumero,
                  style: TextStyle(
                    color: isToday ? _accentColor.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 4,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (sesiones.isEmpty)
                      _buildEmptyState()
                    else
                      ...sesiones.map((s) => _buildGuardiaCard(s)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.2), size: 24),
          const SizedBox(height: 8),
          Text(
            "Sin guardias",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardiaCard(HorarioClase s) {
    final nombreAusente = s.profesorAusente;
    final tieneAsignacion = nombreAusente != null && nombreAusente.isNotEmpty;
    
    // Color dinámico basado en el nombre, hora y día para asegurar variedad
    final salt = "${s.profesorAusente}_${s.inicio}_${s.dia}";
    final colorIndex = salt.hashCode.abs() % _vibrantColors.length;
    final cardColor = _vibrantColors[colorIndex];

    final aula = s.aula.isNotEmpty && s.aula != 'N/A' ? "Aula ${s.aula}" : null;
    final grupo = s.grupo.isNotEmpty && s.grupo != 'N/A' ? s.grupo : null;
    final ubicacion = [aula, grupo].whereType<String>().join(' • ');
    final tieneTareas = s.instrucciones.isNotEmpty;

    return GestureDetector(
      onTap: () => _showGuardiaDetail(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border(
            left: BorderSide(color: cardColor, width: 6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.inicio,
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nombreAusente ?? "Sustitución",
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.room_outlined, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    ubicacion,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (tieneTareas) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_outlined, size: 12, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.instrucciones,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGuardiaDetail(HorarioClase s) {
    final obsController = TextEditingController(text: s.observacion);
    final guardiaUseCase = context.read<GuardarObservacionUseCase>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool guardando = false;
        String obsGuardada = s.observacion;
        DateTime? fechaObs = s.fechaObservacion;

        return StatefulBuilder(
        builder: (ctx, setStateDialog) {

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.97),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: _color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Detalles de la Guardia",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white38),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info básica
                    _buildDetailRow(Icons.person_outline, "PROFESOR AUSENTE", s.profesorAusente),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.location_on_outlined, "UBICACIÓN", "${s.aula} • ${s.grupo}"),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, "HORARIO", "${s.inicio} — ${s.fin}"),

                    // Tareas dejadas
                    if (s.instrucciones.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _color.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.assignment_outlined, size: 14, color: _color),
                              const SizedBox(width: 6),
                              const Text("TAREAS DEJADAS",
                                  style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ]),
                            const SizedBox(height: 10),
                            Text(s.instrucciones,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ],

                    // Observaciones del sustituto
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.edit_note_rounded, size: 16, color: Colors.orangeAccent),
                            const SizedBox(width: 6),
                            const Text("OBSERVACIONES DEL SUSTITUTO",
                                style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            if (fechaObs != null) ...[
                              const Spacer(),
                              Text(
                                DateFormat('dd/MM HH:mm').format(fechaObs!.toLocal()),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 10),

                          // Si hay observación guardada, mostrarla
                          if (obsGuardada.isNotEmpty)
                            Text(obsGuardada,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.5)),

                          // Campo de texto para escribir/editar
                          const SizedBox(height: 10),
                          TextField(
                            controller: obsController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: obsGuardada.isEmpty
                                  ? "Ej: Grupo tranquilo, actividad completada..."
                                  : "Editar observación...",
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.07),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.orangeAccent),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Botón guardar (solo si hay idAusencia)
                          if (s.idAusencia != null)
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: guardando
                                    ? null
                                    : () async {
                                        final texto = obsController.text.trim();
                                        if (texto.isEmpty) return;
                                        setStateDialog(() => guardando = true);
                                        try {
                                          await guardiaUseCase.execute(
                                            idAusencia: s.idAusencia!,
                                            observacion: texto,
                                          );
                                          setStateDialog(() {
                                            obsGuardada = texto;
                                            fechaObs = DateTime.now();
                                            guardando = false;
                                          });
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(
                                              const SnackBar(
                                                content: Text("Observación guardada"),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (_) {
                                          setStateDialog(() => guardando = false);
                                        }
                                      },
                                icon: guardando
                                    ? const SizedBox(width: 14, height: 14,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.save_rounded, size: 16),
                                label: Text(guardando ? "Guardando..." : "Guardar observación",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("CERRAR", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white38),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value.isEmpty ? "No especificado" : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
