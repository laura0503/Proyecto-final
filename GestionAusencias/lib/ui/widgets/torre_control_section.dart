import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'torre_control/torre_control_models.dart';
import 'torre_control/torre_control_kpi_row.dart';
import 'torre_control/torre_control_gestion_card.dart';
import 'torre_control/torre_control_guard_team.dart';
import 'torre_control/torre_control_asignar_sheet.dart';

class TorreControlSection extends StatefulWidget {
  final bool isDark;
  const TorreControlSection({super.key, required this.isDark});

  @override
  State<TorreControlSection> createState() => _TorreControlSectionState();
}

class _TorreControlSectionState extends State<TorreControlSection> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  List<SlotMonitor> _slots = [];
  List<GuardiaMonitor> _guardias = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _cargarDatos(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    final supabase = Supabase.instance.client;
    final hoy = DateTime.now();
    final dateStr =
        '${hoy.year.toString().padLeft(4, '0')}-'
        '${hoy.month.toString().padLeft(2, '0')}-'
        '${hoy.day.toString().padLeft(2, '0')}';

    try {
      final results = await Future.wait([
        supabase.from('ausencia').select('''
          id_ausencia, fecha,
          profesor_ausente:id_profesor_ausente (nombre),
          horario:id_horario_sesion (
            id_tramo,
            Asignaturas:id_asignatura (nombre),
            aulas:id_aula (nombre),
            grupo:id_grupo (nombre),
            horario_tramo:id_tramo (horario_inicio, horario_fin)
          )
        ''').eq('fecha', dateStr),
        supabase.from('sustitucion').select('''
          id_ausencia, id_sustitucion,
          sustituto:id_profesor_sustituto (nombre),
          ausencia:id_ausencia (fecha)
        ''').eq('ausencia.fecha', dateStr),
        supabase
            .from('horario')
            .select('''
              id_profesor, id_tramo,
              profesores:id_profesor (nombre),
              horario_tramo:id_tramo (horario_inicio, horario_fin)
            ''')
            .eq('dia_semana', hoy.weekday)
            .eq('es_guardia', true),
      ]);

      final ausenciasRaw = results[0] as List;
      final sustitucionesRaw = results[1] as List;
      final guardiasRaw = results[2] as List;

      final Map<int, String> cobertura = {};
      for (final s in sustitucionesRaw) {
        final idAus = s['id_ausencia'] as int?;
        if (idAus != null && s['sustituto'] != null) {
          cobertura[idAus] =
              s['sustituto']['nombre']?.toString() ?? 'Sustituto';
        }
      }

      final nowStr = DateFormat('HH:mm').format(DateTime.now());

      final slots = ausenciasRaw.map((a) {
        final horario = a['horario'];
        final tramo = horario?['horario_tramo'] ?? {};
        final inicio =
            (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
        final fin =
            (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
        return SlotMonitor(
          ausenciaId: a['id_ausencia'] ?? 0,
          idTramo: horario?['id_tramo'] as int?,
          inicio: inicio,
          fin: fin,
          grupo: horario?['grupo']?['nombre']?.toString() ?? 'N/A',
          aula: horario?['aulas']?['nombre']?.toString() ?? 'N/A',
          asignatura:
              horario?['Asignaturas']?['nombre']?.toString() ?? 'N/A',
          profesorAusente:
              a['profesor_ausente']?['nombre']?.toString() ?? 'Desconocido',
          sustitutoNombre: cobertura[a['id_ausencia']],
          esActual:
              nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
        );
      }).toList();

      final guardias = guardiasRaw.map((g) {
        final tramo = g['horario_tramo'] ?? {};
        final inicio =
            (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
        final fin =
            (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
        return GuardiaMonitor(
          profId: g['id_profesor'] as int? ?? 0,
          nombre: g['profesores']?['nombre']?.toString() ?? 'N/A',
          inicio: inicio,
          fin: fin,
          idTramo: g['id_tramo'] as int?,
          esActual:
              nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _slots = slots;
          _guardias = guardias;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onAsignar(SlotMonitor slot) {
    showAsignarGuardiaSheet(context, slot, _cargarDatos);
  }

  @override
  Widget build(BuildContext context) {
    final desiertas = _slots.where((s) => s.esDesierta).length;
    final cubiertas = _slots.length - desiertas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Monitor de Centro",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Estado actual del centro educativo en tiempo real",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        TorreControlKpiRow(
          totalAusentes: _slots.length,
          cubiertas: cubiertas,
          desiertas: desiertas,
        ),
        const SizedBox(height: 32),

        TorreControlGestionCard(
          slots: _slots,
          guardias: _guardias,
          isLoading: _isLoading,
          onRefresh: _cargarDatos,
          onAsignar: _onAsignar,
        ),
        const SizedBox(height: 48),

        TorreControlGuardTeam(guardias: _guardias, isLoading: _isLoading),
      ],
    );
  }
}
