import 'dart:async';
import 'package:flutter/material.dart';
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _cargarDatos());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      final hoy = DateTime.now();
      final dateStr = hoy.toIso8601String().substring(0, 10);
      final diaIndice = hoy.weekday;
      final nowStr = "${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}";

      final results = await Future.wait([
        supabase.from('ausencia').select('''
            id_ausencia, id_profesor_ausente, es_dia_completo, tipo_detalle, observaciones,
            profesor_ausente:id_profesor_ausente (nombre),
            horario:id_horario_sesion (
              id, asignatura:id_asignatura(nombre), aula:id_aula(nombre), grupo:id_grupo(nombre),
              horario_tramo!inner(horario_inicio, horario_fin, id_horario)
            )
          ''').eq('fecha', dateStr),
        supabase.from('horario').select('''
            id_profesor, es_guardia, dia_semana,
            profesores:id_profesor (nombre),
            horario_tramo!inner(horario_inicio, horario_fin, id_horario)
          ''').eq('dia_semana', diaIndice).eq('es_guardia', true),
        supabase.from('sustitucion').select('''
            id_ausencia, sustituto:id_profesor_sustituto (nombre), ausencia!inner(fecha)
          ''').eq('ausencia.fecha', dateStr),
      ]);

      final List ausencias = results[0] as List;
      final List guardiasRaw = results[1] as List;
      final List susts = results[2] as List;

      final Map<int, String> cobertura = {};
      for (var s in susts) {
        final idAus = s['id_ausencia'];
        if (idAus != null) {
          cobertura[idAus is String ? int.parse(idAus) : idAus] = s['sustituto']?['nombre'];
        }
      }

      final List<SlotMonitor> allSlots = [];
      for (var a in ausencias) {
        final h = a['horario'];
        if (h != null) {
          final t = h['horario_tramo'];
          if (t != null) {
            final inicio = t['horario_inicio'].toString().substring(0, 5);
            final fin = t['horario_fin'].toString().substring(0, 5);
            final idAus = a['id_ausencia'] is String ? int.parse(a['id_ausencia']) : a['id_ausencia'];
            allSlots.add(SlotMonitor(
              ausenciaId: idAus,
              idTramo: t['id_horario'] ?? 0,
              inicio: inicio,
              fin: fin,
              grupo: h['grupo']?['nombre'] ?? 'N/A',
              aula: h['aula']?['nombre'] ?? 'N/A',
              asignatura: h['asignatura']?['nombre'] ?? 'N/A',
              profesorAusente: a['profesor_ausente']?['nombre'] ?? 'Desconocido',
              tipo: "FALTA",
              tipoDetalle: a['tipo_detalle']?.toString() ?? "",
              sustitutoNombre: cobertura[idAus],
              esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
              esPasado: false,
            ));
          }
        } else if (a['es_dia_completo'] == true) {
          final idAus = a['id_ausencia'] is String ? int.parse(a['id_ausencia']) : a['id_ausencia'];
          allSlots.add(SlotMonitor(
            ausenciaId: idAus,
            idTramo: 0,
            inicio: "08:00",
            fin: "21:00",
            grupo: "Toda la jornada",
            aula: "N/A",
            asignatura: "Día Completo",
            profesorAusente: a['profesor_ausente']?['nombre'] ?? 'Desconocido',
            tipo: "FALTA",
            tipoDetalle: a['tipo_detalle']?.toString() ?? "",
            sustitutoNombre: cobertura[idAus],
            esActual: true,
            esPasado: false,
          ));
        }
      }
      allSlots.sort((a, b) => a.inicio.compareTo(b.inicio));

      final List<GuardiaMonitor> equipo = (guardiasRaw as List).map((g) {
        final t = g['horario_tramo'];
        final inicio = (t['horario_inicio'] ?? '00:00').toString().substring(0, 5);
        final fin = (t['horario_fin'] ?? '00:00').toString().substring(0, 5);
        final rawProfId = g['id_profesor'];
        return GuardiaMonitor(
          profId: rawProfId is String ? int.parse(rawProfId) : (rawProfId ?? 0),
          nombre: g['profesores']?['nombre'] ?? 'N/A',
          inicio: inicio,
          fin: fin,
          idTramo: t['id_horario'] is String ? int.parse(t['id_horario']) : (t['id_horario'] ?? 0),
          esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
          esPasado: nowStr.compareTo(fin) >= 0,
        );
      }).toList()..sort((a, b) => a.inicio.compareTo(b.inicio));

      if (mounted) {
        setState(() {
          _slots = allSlots;
          _guardias = equipo;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error TorreControl: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final desiertas = _slots.where((s) => s.esDesierta).length;
    final cubiertas = _slots.length - desiertas;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monitor de Centro",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
            ),
          ),
          const SizedBox(height: 24),
          TorreControlKpiRow(
            totalAusentes: _slots.length,
            cubiertas: cubiertas,
            desiertas: desiertas,
          ),
          const SizedBox(height: 24),
          TorreControlGestionCard(
            slots: _slots,
            guardias: _guardias,
            isLoading: false,
            onRefresh: _cargarDatos,
            onAsignar: (slot) => showAsignarGuardiaSheet(context, slot, _cargarDatos),
          ),
          const SizedBox(height: 32),
          TorreControlGuardTeam(
            guardias: _guardias,
            isLoading: false,
          ),
          const SizedBox(height: 60), // Espacio extra al final
        ],
      ),
    );
  }
}
