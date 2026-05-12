import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../../domain/entities/horario_clase.dart';
import '../../../domain/entities/ausencia.dart';

class HomeWeeklySchedule extends StatelessWidget {
  final List<HorarioClase> horario;
  final List<Ausencia> ausencias;
  final List<HorarioClase> sustituciones; // Añadido
  final Function(HorarioClase, DateTime) onAction;

  const HomeWeeklySchedule({
    super.key, 
    required this.horario, 
    this.ausencias = const [],
    this.sustituciones = const [], // Añadido
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final hoyIndex = hoy.weekday - 1;
    final lunes = hoy.subtract(Duration(days: hoy.weekday - 1));
    final fechasSemana = List.generate(5, (i) => lunes.add(Duration(days: i)));

    // Combinamos horario normal y sustituciones para calcular los tramos
    final tramosSet = <String>{};
    for (var s in horario) {
      tramosSet.add("${s.inicio} — ${s.fin}");
    }
    for (var s in sustituciones) {
      tramosSet.add("${s.inicio} — ${s.fin}");
    }
    final sortedTramos = tramosSet.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAppleHeader(),
        const SizedBox(height: 28),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(5, (index) {
              final diaNombre = ["LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES"][index];
              final fechaDia = fechasSemana[index];
              return _buildDayColumn(context, diaNombre, fechaDia, index == hoyIndex, sortedTramos);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayColumn(BuildContext context, String diaNombre, DateTime fecha, bool isToday, List<String> allTramos) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          _buildDayHeader(diaNombre.substring(0, 3), isToday, fecha),
          const SizedBox(height: 20),
          ...allTramos.map((tramoStr) {
            // Buscamos sesiones normales
            final sesionesNormales = horario.where((h) {
              return h.dia.toUpperCase() == diaNombre && "${h.inicio} — ${h.fin}" == tramoStr;
            }).toList();

            // Buscamos sustituciones (guardias asignadas) para este día y tramo
            final sesionesSustitucion = sustituciones.where((h) {
              if (h.fecha == null) return false;
              return h.fecha!.day == fecha.day && 
                     h.fecha!.month == fecha.month && 
                     "${h.inicio} — ${h.fin}" == tramoStr;
            }).toList();

            final todasLasSesiones = [...sesionesNormales, ...sesionesSustitucion];

            return _buildTramoSlot(context, tramoStr, todasLasSesiones, fecha, isToday);
          }).toList(),
          const SizedBox(height: 12),
          _buildEmptySlot(() => onAction(HorarioClase(profesor: "", aula: "", grupo: "", asignatura: "", dia: diaNombre, inicio: "", fin: ""), fecha)),
        ],
      ),
    );
  }

  Widget _buildDayHeader(String label, bool isToday, DateTime fecha) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: isToday ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)) : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isToday ? const Color(0xFF6366F1) : Colors.grey[600],
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            DateFormat('d MMM', 'es').format(fecha).toUpperCase(),
            style: TextStyle(
              color: isToday ? const Color(0xFF6366F1).withOpacity(0.6) : Colors.grey[400],
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTramoSlot(BuildContext context, String tramoStr, List<HorarioClase> sesiones, DateTime fecha, bool isToday) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
          child: Text(
            tramoStr,
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        if (sesiones.isEmpty)
          _buildMiniEmptySlot()
        else
          ...sesiones.map((s) {
            final ausencia = ausencias.firstWhere(
              (a) => a.idHorario == s.id && a.fecha.day == fecha.day && a.fecha.month == fecha.month,
              orElse: () => Ausencia(profesorId: "", fecha: fecha, fechaInicio: fecha, idHorario: -1, tipo: null),
            );
            return GestureDetector(
              onTap: () => onAction(s, fecha),
              child: _buildSwiftUICard(s, isToday, context, ausencia),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildMiniEmptySlot() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Icon(Icons.add_rounded, color: Colors.grey[300], size: 20)),
    );
  }

  Widget _buildEmptySlot(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: const Color(0xFF6366F1).withOpacity(0.4), size: 24),
            const SizedBox(height: 6),
            const Text(
              "Reportar incidencia",
              style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Mi Horario",
          style: TextStyle(
            fontSize: 26, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF0F172A),
            letterSpacing: -1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            "Horario",
            style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSwiftUICard(HorarioClase s, bool isToday, BuildContext context, Ausencia ausencia) {
    final bool isSubstitution = s.profesorAusente.isNotEmpty;
    final bool hasAusencia = ausencia.tipo != null;
    
    // Si es guardia, usamos Morado Neón. Si no, color normal vibrante.
    Color accentColor = isSubstitution ? const Color(0xFFA855F7) : _getAccentColor(s.asignatura, isToday);
    
    // Si yo falto, color rojo intenso
    if (hasAusencia) {
      accentColor = ausencia.tipo == 'FALTA' ? const Color(0xFFFF3B30) : const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(5, 0, 5, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSubstitution 
                ? accentColor.withOpacity(0.25) 
                : (hasAusencia ? accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.75)),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSubstitution || hasAusencia || isToday ? accentColor.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                width: (isToday || hasAusencia || isSubstitution) ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.inicio,
                      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    if (isSubstitution)
                      _buildBadge("GUARDIA", accentColor)
                    else if (hasAusencia)
                      _buildBadge(ausencia.tipo!, accentColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isSubstitution ? "Sustituyes a ${s.profesorAusente}" : s.asignatura,
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 13, 
                    color: (hasAusencia || isSubstitution) ? accentColor : const Color(0xFF1E293B),
                    height: 1.1,
                    decoration: ausencia.tipo == 'FALTA' ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(isSubstitution ? Icons.shield_rounded : Icons.location_on_rounded, size: 10, color: accentColor.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${s.aula} • ${s.grupo}",
                        style: TextStyle(color: accentColor.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getAccentColor(String asignatura, bool isToday) {
    if (!isToday) return Colors.blueGrey[300]!;
    final name = asignatura.toUpperCase();
    if (name.contains("MACS")) return const Color(0xFFF43F5E); // Rose brillante
    if (name.contains("MAT")) return const Color(0xFF6366F1); // Indigo
    if (name.contains("BIO") || name.contains("NATU")) return const Color(0xFF10B981); // Esmeralda
    if (name.contains("ENG") || name.contains("ING")) return const Color(0xFF06B6D4); // Cian
    if (name.contains("DAM") || name.contains("ASIR")) return const Color(0xFFA855F7); // Morado neón
    return const Color(0xFF6366F1);
  }
}
