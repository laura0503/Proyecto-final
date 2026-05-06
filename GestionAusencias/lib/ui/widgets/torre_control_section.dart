import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SlotMonitor {
  final int ausenciaId;
  final String inicio;
  final String fin;
  final String grupo;
  final String aula;
  final String asignatura;
  final String profesorAusente;
  final String? sustitutoNombre;
  final bool esActual;
  final String planta;

  _SlotMonitor({
    required this.ausenciaId,
    required this.inicio,
    required this.fin,
    required this.grupo,
    required this.aula,
    required this.asignatura,
    required this.profesorAusente,
    this.sustitutoNombre,
    required this.esActual,
    this.planta = "PLANTA 1",
  });

  bool get esDesierta => sustitutoNombre == null;
}

class TorreControlSection extends StatefulWidget {
  final bool isDark;
  const TorreControlSection({super.key, required this.isDark});

  @override
  State<TorreControlSection> createState() => _TorreControlSectionState();
}

class _TorreControlSectionState extends State<TorreControlSection> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  List<_SlotMonitor> _slots = [];

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
    final supabase = Supabase.instance.client;
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    try {
      final results = await Future.wait([
        supabase.from('ausencia').select('''
          id_ausencia,
          fecha,
          profesor_ausente:id_profesor_ausente (nombre),
          horario:id_horario_sesion (
            Asignaturas:id_asignatura (nombre),
            aulas:id_aula (nombre),
            grupo:id_grupo (nombre),
            horario_tramo:id_tramo (horario_inicio, horario_fin)
          )
        ''')
            .gte('fecha', inicioHoy.toIso8601String())
            .lte('fecha', finHoy.toIso8601String()),
        supabase.from('sustitucion').select('''
          id_ausencia,
          sustituto:id_profesor_sustituto (nombre),
          ausencia:id_ausencia (fecha)
        ''')
            .gte('ausencia.fecha', inicioHoy.toIso8601String())
            .lte('ausencia.fecha', finHoy.toIso8601String()),
      ]);

      final ausenciasRaw = results[0] as List;
      final sustitucionesRaw = results[1] as List;

      final Map<int, String> cobertura = {};
      for (final s in sustitucionesRaw) {
        final idAus = s['id_ausencia'] as int?;
        if (idAus != null && s['sustituto'] != null) {
          cobertura[idAus] = s['sustituto']['nombre']?.toString() ?? 'Sustituto';
        }
      }

      final nowStr = DateFormat('HH:mm').format(DateTime.now());
      
      final slots = ausenciasRaw.map((a) {
        final horario = a['horario'];
        final tramo = horario?['horario_tramo'] ?? {};
        final inicio = (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
        final fin = (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
        
        return _SlotMonitor(
          ausenciaId: a['id_ausencia'] ?? 0,
          inicio: inicio,
          fin: fin,
          grupo: horario?['grupo']?['nombre']?.toString() ?? 'N/A',
          aula: horario?['aulas']?['nombre']?.toString() ?? 'N/A',
          asignatura: horario?['Asignaturas']?['nombre']?.toString() ?? 'N/A',
          profesorAusente: a['profesor_ausente']?['nombre']?.toString() ?? 'Desconocido',
          sustitutoNombre: cobertura[a['id_ausencia']],
          esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
        );
      }).toList();

      if (mounted) setState(() { _slots = slots; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final desiertas = _slots.where((s) => s.esDesierta).length;
    final cubiertas = _slots.length - desiertas;
    final eficiencia = _slots.isEmpty ? 100 : ((cubiertas / _slots.length) * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TÍTULO Y BOTONES DE ACCIÓN
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
            Row(
              children: [
                _buildActionBtn(Icons.file_download_outlined, "Exportar Log"),
                const SizedBox(width: 12),
                _buildActionBtn(Icons.add_alert_rounded, "Nueva Alerta", color: const Color(0xFF4F46E5), isPrimary: true),
              ],
            )
          ],
        ),
        const SizedBox(height: 32),

        // 2. TARJETAS DE KPI (PROFESORES AUSENTES, GUARDIAS, ALERTAS)
        Row(
          children: [
            _buildKpiCard("PROFESORES AUSENTES", "${_slots.length}", "+5% vs ayer", Icons.people_outline, const Color(0xFF4F46E5)),
            const SizedBox(width: 20),
            _buildKpiCard("GUARDIAS CUBIERTAS", "$cubiertas", "$eficiencia% eficiencia", Icons.verified_user_outlined, const Color(0xFF10B981)),
            const SizedBox(width: 20),
            _buildCriticalCard(desiertas),
          ],
        ),
        const SizedBox(height: 48),

        // 3. ESTADO DE AULAS (GRID)
        Row(
          children: [
            const Text("Estado de Aulas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const Spacer(),
            _buildLegendDot("Operativo", const Color(0xFF10B981)),
            const SizedBox(width: 16),
            _buildLegendDot("Desierta", const Color(0xFFF43F5E)),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_slots.isEmpty)
          _buildEmptyState()
        else
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: _slots.map((s) => _buildClassCard(s)).toList(),
          ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String val, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 0.5)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(sub, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: 0.7, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 4),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalCard(int desiertas) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFFF43F5E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ALERTAS CRÍTICAS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5)),
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Text("$desiertas", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Text("Requiere Acción", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Text("Hay clases sin profesor ahora mismo", style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(_SlotMonitor s) {
    final color = s.esDesierta ? const Color(0xFFF43F5E) : const Color(0xFF10B981);
    
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: s.esActual ? color : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.planta, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  Text(s.aula, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(s.esDesierta ? Icons.close_rounded : Icons.check_rounded, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(s.esDesierta ? "DESIERTA" : "Cubierta", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProfeRow(Icons.person_off_outlined, "Titular Ausente", s.profesorAusente),
          const SizedBox(height: 12),
          _buildProfeRow(
            s.esDesierta ? Icons.warning_amber_rounded : Icons.person_search_rounded, 
            s.esDesierta ? "Sin asignar" : "Sustituto en Aula", 
            s.sustitutoNombre ?? "Requiere sustituto urgente",
            isAlert: s.esDesierta,
          ),
          const SizedBox(height: 24),
          if (s.esDesierta)
            _buildSmallActionBtn("Asignar Guardia Ahora", color)
          else
             Row(
               children: [
                 Icon(Icons.history, color: Colors.grey.shade400, size: 14),
                 const SizedBox(width: 6),
                 Text("Fichado hace: 12 min", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
               ],
             )
        ],
      ),
    );
  }

  Widget _buildProfeRow(IconData icon, String label, String name, {bool isAlert = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: isAlert ? const Color(0xFFF43F5E) : Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isAlert ? const Color(0xFFF43F5E) : Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
            Text(name, style: TextStyle(color: isAlert ? const Color(0xFFF43F5E) : const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        )
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String text, {Color color = Colors.black, bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isPrimary ? Colors.white : color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: isPrimary ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSmallActionBtn(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildLegendDot(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No hay ausencias hoy", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey)),
        ],
      ),
    );
  }
}
