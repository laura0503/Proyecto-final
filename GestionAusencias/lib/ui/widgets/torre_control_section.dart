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
    final dateStr = hoy.toIso8601String().substring(0, 10);
    final nombresDias = ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"];
    final diaNombre = nombresDias[hoy.weekday];

    try {
      final ausenciasRes = await supabase
          .from('ausencia')
          .select('''
            id_ausencia, id_profesor_ausente, es_dia_completo, tipo,
            profesor_ausente:id_profesor_ausente (nombre),
            horario:id_horario_sesion (
              id, id_tramo,
              asignatura:id_asignatura (nombre),
              aula:id_aula (nombre),
              grupo:id_grupo (nombre),
              tramo:id_tramo (horario_inicio, horario_fin)
            )
          ''')
          .lte('fecha_inicio', dateStr)
          .or('fecha_fin.is.null, fecha_fin.gte.$dateStr');

      final sustitucionesRes = await supabase
          .from('sustitucion')
          .select('''
            id_ausencia, 
            sustituto:id_profesor_sustituto (nombre),
            fecha_sustitucion
          ''')
          .eq('fecha_sustitucion', dateStr);

      final guardiasRes = await supabase
          .from('horario')
          .select('''
            id_profesor, id_tramo,
            profesores:id_profesor (nombre),
            tramo:id_tramo (horario_inicio, horario_fin)
          ''')
          .eq('dia_semana', diaNombre)
          .eq('es_guardia', true);

      final List ausenciasRaw = ausenciasRes as List;
      final List sustitucionesRaw = sustitucionesRes as List;
      final List guardiasRaw = guardiasRes as List;

      final Map<int, String> cobertura = {};
      for (final s in sustitucionesRaw) {
        final idAus = s['id_ausencia'] as int?;
        if (idAus != null) {
          cobertura[idAus] = s['sustituto']?['nombre']?.toString() ?? 'Sustituto';
        }
      }

      final nowStr = DateFormat('HH:mm').format(DateTime.now());
      List<SlotMonitor> allSlots = [];

      for (final a in ausenciasRaw) {
        final bool esDiaCompleto = a['es_dia_completo'] ?? false;
        final String tipo = a['tipo'] ?? 'AUSENCIA';
        
        if (esDiaCompleto) {
          final profId = a['id_profesor_ausente'];
          final clasesProfesor = await supabase
              .from('horario')
              .select('''
                id, id_tramo,
                asignatura:id_asignatura (nombre),
                aula:id_aula (nombre),
                grupo:id_grupo (nombre),
                tramo:id_tramo (horario_inicio, horario_fin)
              ''')
              .eq('id_profesor', profId)
              .eq('dia_semana', diaNombre)
              .eq('es_guardia', false);

          for (final c in (clasesProfesor as List)) {
            final tramo = c['tramo'] ?? {};
            final inicio = (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
            final fin = (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
            
            allSlots.add(SlotMonitor(
              ausenciaId: a['id_ausencia'] ?? 0,
              idTramo: c['id_tramo'] as int?,
              inicio: inicio,
              fin: fin,
              grupo: c['grupo']?['nombre']?.toString() ?? 'N/A',
              aula: c['aula']?['nombre']?.toString() ?? 'N/A',
              asignatura: c['asignatura']?['nombre']?.toString() ?? 'N/A',
              profesorAusente: a['profesor_ausente']?['nombre']?.toString() ?? 'Desconocido',
              tipo: tipo,
              sustitutoNombre: cobertura[a['id_ausencia']],
              esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
              esPasado: nowStr.compareTo(fin) >= 0,
            ));
          }
        } else {
          final horario = a['horario'];
          if (horario != null) {
            final tramo = horario['tramo'] ?? {};
            final inicio = (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
            final fin = (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
            
            allSlots.add(SlotMonitor(
              ausenciaId: a['id_ausencia'] ?? 0,
              idTramo: horario['id_tramo'] as int?,
              inicio: inicio,
              fin: fin,
              grupo: horario['grupo']?['nombre']?.toString() ?? 'N/A',
              aula: horario['aula']?['nombre']?.toString() ?? 'N/A',
              asignatura: horario['asignatura']?['nombre']?.toString() ?? 'N/A',
              profesorAusente: a['profesor_ausente']?['nombre']?.toString() ?? 'Desconocido',
              tipo: tipo,
              sustitutoNombre: cobertura[a['id_ausencia']],
              esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
              esPasado: nowStr.compareTo(fin) >= 0,
            ));
          }
        }
      }

      allSlots.sort((a, b) => a.inicio.compareTo(b.inicio));

      final guardias = guardiasRaw.map((g) {
        final tramo = g['tramo'] ?? {};
        final inicio = (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
        final fin = (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
        return GuardiaMonitor(
          profId: g['id_profesor'] as int? ?? 0,
          nombre: g['profesores']?['nombre']?.toString() ?? 'N/A',
          inicio: inicio,
          fin: fin,
          idTramo: g['id_tramo'] as int?,
          esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
          esPasado: nowStr.compareTo(fin) >= 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _slots = allSlots;
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: Color(0xFF1E293B)),
                ),
                Text(
                  "Estado actual del centro educativo en tiempo real",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
