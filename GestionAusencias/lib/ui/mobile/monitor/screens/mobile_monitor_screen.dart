import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/torre_control/torre_control_models.dart';
import '../widgets/monitor_absence_card.dart';
import '../widgets/monitor_empty_state.dart';
import '../widgets/monitor_guard_section.dart';
import '../widgets/monitor_kpi_card.dart';

class MobileMonitorScreen extends StatefulWidget {
  const MobileMonitorScreen({super.key});

  @override
  State<MobileMonitorScreen> createState() => _MobileMonitorScreenState();
}

class _MobileMonitorScreenState extends State<MobileMonitorScreen> {
  bool _isLoading = true;
  List<SlotMonitor> _slots = [];
  List<GuardiaMonitor> _guardias = [];
  Timer? _refreshTimer;

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
      final nowStr = '${hoy.hour.toString().padLeft(2, '0')}:${hoy.minute.toString().padLeft(2, '0')}';

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
        if (h == null) continue;
        final t = h['horario_tramo'];
        if (t == null) continue;
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
          tipo: 'FALTA',
          tipoDetalle: a['tipo_detalle']?.toString() ?? '',
          sustitutoNombre: cobertura[idAus],
          esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
          esPasado: nowStr.compareTo(fin) >= 0,
        ));
      }
      allSlots.sort((a, b) => a.inicio.compareTo(b.inicio));

      final List<GuardiaMonitor> equipo = guardiasRaw.map((g) {
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
      debugPrint('Error MobileMonitor: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desiertas = _slots.where((s) => s.esDesierta).length;
    final cubiertas = _slots.length - desiertas;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: const Color(0xFF6366F1),
        edgeOffset: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RESUMEN DE HOY',
                        style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    MonitorKpiGrid(total: _slots.length, cubiertas: cubiertas, desiertas: desiertas),
                  ],
                ),
              ),
            ),
            if (_isLoading && _slots.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.white24)),
              )
            else if (_slots.isEmpty && !_isLoading)
              const SliverFillRemaining(child: MonitorEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _slots.length) return MonitorGuardSection(guardias: _guardias);
                      return MonitorAbsenceCard(slot: _slots[index], onAssign: _cargarDatos);
                    },
                    childCount: _slots.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return const SliverAppBar(
      expandedHeight: 0,
      toolbarHeight: 20,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
    );
  }
}
