import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/torre_control/torre_control_models.dart';
import '../../../widgets/torre_control/torre_control_asignar_sheet.dart';

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
              esPasado: nowStr.compareTo(fin) >= 0,
            ));
          }
        }
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
      debugPrint("Error MobileMonitor: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
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
                    const Text("RESUMEN DE HOY", 
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _buildKpiGrid(_slots.length, cubiertas, desiertas),
                  ],
                ),
              ),
            ),
            if (_isLoading && _slots.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.white24)),
              )
            else if (_slots.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _slots.length) {
                        return _buildGuardSection();
                      }
                      return _buildAbsenceCard(_slots[index]);
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
    return SliverAppBar(
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

  Widget _buildKpiGrid(int total, int cubiertas, int desiertas) {
    return Row(
      children: [
        Expanded(child: _buildKpiCard("TOTAL", total.toString(), const Color(0xFF6366F1), Icons.analytics_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildKpiCard("CUBIERTO", cubiertas.toString(), const Color(0xFF10B981), Icons.check_circle_outline_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildKpiCard("FALTA", desiertas.toString(), const Color(0xFFEF4444), Icons.error_outline_rounded)),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildAbsenceCard(SlotMonitor slot) {
    final statusColor = slot.sustitutoNombre != null ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: slot.esActual ? const Color(0xFF6366F1).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.03),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => showAsignarGuardiaSheet(context, slot, _cargarDatos),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeBadge(slot),
                    _buildStatusBadge(slot),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor.withValues(alpha: 0.2), statusColor.withValues(alpha: 0.05)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(slot.profesorAusente.substring(0, 1), 
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot.profesorAusente, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text("${slot.asignatura} • ${slot.grupo}", 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (slot.sustitutoNombre != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text("Sustituye: ${slot.sustitutoNombre}", 
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ] else if (!slot.esPasado) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showAsignarGuardiaSheet(context, slot, _cargarDatos),
                      icon: const Icon(Icons.add_moderator_rounded, size: 18),
                      label: const Text("ASIGNAR GUARDIA"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge(SlotMonitor slot) {
    final active = slot.esActual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_filled_rounded, size: 14, color: active ? const Color(0xFF818CF8) : Colors.white38),
          const SizedBox(width: 6),
          Text("${slot.inicio} - ${slot.fin}", 
            style: TextStyle(color: active ? const Color(0xFF818CF8) : Colors.white60, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SlotMonitor slot) {
    if (slot.esPasado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        child: const Text("PASADO", style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900)),
      );
    }
    final esLibre = slot.sustitutoNombre == null;
    final color = esLibre ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(esLibre ? "DESIERTA" : "CUBIERTA", 
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildGuardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text("EQUIPO DE GUARDIA", 
          style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (_guardias.isEmpty)
          _buildInfoBox("No hay guardias programadas")
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _guardias.map((g) => _buildGuardChip(g)).toList(),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGuardChip(GuardiaMonitor g) {
    final active = g.esActual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? const Color(0xFF6366F1).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF10B981) : (g.esPasado ? Colors.white24 : const Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(width: 10),
          Text(g.nombre, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.05), shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, size: 64, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          const Text("TODO EN ORDEN", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text("No hay incidencias para el día de hoy", style: TextStyle(color: Colors.white38, fontSize: 15)),
        ],
      ),
    );
  }
}
