import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'torre_control/torre_control_models.dart';
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
  int _totalProfesores = 0;

  // Colores Premium
  final Color primaryPurple = const Color(0xFF6366F1);
  final Color alertRed = const Color(0xFFF43F5E);
  final Color glassWhite = Colors.white.withOpacity(0.1);

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
            id_ausencia, id_profesor_ausente, es_dia_completo, tipo_detalle,
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
        supabase.from('profesores').select('id_profesor'),
      ]);

      final List ausencias = results[0] as List;
      final List guardiasRaw = results[1] as List;
      final List susts = results[2] as List;
      final List profesCountRaw = results[3] as List;
      _totalProfesores = profesCountRaw.length;

      Map<int, String> cobertura = {};
      for (var s in susts) {
        final idAus = s['id_ausencia'];
        if (idAus != null) {
          cobertura[idAus is String ? int.parse(idAus) : idAus] = s['sustituto']?['nombre'];
        }
      }

      List<SlotMonitor> allSlots = [];
      for (var a in ausencias) {
        final h = a['horario'];
        // Si tiene horario específico, calculamos si es pasado
        if (h != null) {
          final t = h['horario_tramo'];
          final inicio = (t['horario_inicio'] ?? '00:00').toString().substring(0, 5);
          final fin = (t['horario_fin'] ?? '00:00').toString().substring(0, 5);
          final bool esPasado = nowStr.compareTo(fin) >= 0;

          if (!esPasado) {
            allSlots.add(SlotMonitor(
              ausenciaId: a['id_ausencia'] is String ? int.parse(a['id_ausencia']) : a['id_ausencia'],
              idTramo: t['id_horario'] is String ? int.parse(t['id_horario']) : (t['id_horario'] ?? 0),
              inicio: inicio,
              fin: fin,
              grupo: h['grupo']?['nombre'] ?? 'N/A',
              aula: h['aula']?['nombre'] ?? 'N/A',
              asignatura: h['asignatura']?['nombre'] ?? 'N/A',
              profesorAusente: a['profesor_ausente']?['nombre'] ?? 'Desconocido',
              tipo: "FALTA",
              tipoDetalle: a['tipo_detalle']?.toString() ?? "PUNTUAL",
              sustitutoNombre: cobertura[a['id_ausencia'] is String ? int.parse(a['id_ausencia']) : a['id_ausencia']],
              esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
              esPasado: false,
            ));
          }
        } else if (a['es_dia_completo'] == true) {
          // Si es día completo y no tiene sesión específica, lo mostramos siempre
          allSlots.add(SlotMonitor(
            ausenciaId: a['id_ausencia'] is String ? int.parse(a['id_ausencia']) : a['id_ausencia'],
            idTramo: 0,
            inicio: "08:00",
            fin: "21:00",
            grupo: "Toda la jornada",
            aula: "N/A",
            asignatura: "Día Completo",
            profesorAusente: a['profesor_ausente']?['nombre'] ?? 'Desconocido',
            tipo: "FALTA",
            tipoDetalle: a['tipo_detalle']?.toString() ?? "DÍA COMPLETO",
            sustitutoNombre: cobertura[a['id_ausencia'] is String ? int.parse(a['id_ausencia']) : a['id_ausencia']],
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
      }).toList();

      // ORDENAMOS EL EQUIPO DE GUARDIA POR HORA DE INICIO
      equipo.sort((a, b) => a.inicio.compareTo(b.inicio));


      setState(() {
        _slots = allSlots;
        _guardias = equipo;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Monitor Premium: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getDiaNombre(int weekday) {
    return ["", "LUNES", "MARTES", "MIÉRCOLES", "JUEVES", "VIERNES", "SÁBADO", "DOMINGO"][weekday];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final desiertas = _slots.where((s) => s.esDesierta).length;
    final cubiertas = _slots.length - desiertas;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&q=80&w=2070"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Monitor de Centro", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
              const SizedBox(height: 32),
              _buildKPIRow(desiertas, cubiertas),
              const SizedBox(height: 32),
              _buildMainManagementCard(),
              const SizedBox(height: 48),
              const Text("Equipo de Guardia para Hoy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              _buildGuardTeamScroll(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIRow(int desiertas, int cubiertas) {
    return Row(
      children: [
        Expanded(child: _buildKPICard("PROFESORES AUSENTES", "${_slots.length}", "+5% vs ayer", primaryPurple, Icons.people_outline)),
        const SizedBox(width: 24),
        Expanded(child: _buildCriticalCard(desiertas)),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("GUARDIAS CUBIERTAS", "$cubiertas", "${_slots.isEmpty ? 0 : (cubiertas*100/_slots.length).round()}% eficiencia", const Color(0xFF1E293B), Icons.verified_user_outlined)),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
              Icon(icon, size: 18, color: color.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: 0.6, backgroundColor: Colors.grey.shade100, color: color, minHeight: 4),
        ],
      ),
    );
  }

  Widget _buildCriticalCard(int desiertas) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: alertRed, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: alertRed.withOpacity(0.3), blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ALERTAS CRÍTICAS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1)),
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Text("$desiertas", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text("Requiere Acción", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          const Text("Hay clases sin profesor ahora mismo", style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMainManagementCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.security, color: primaryPurple, size: 20)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Gestión de Guardias del Día", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(DateFormat('EEEE d MMMM', 'es').format(DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
                IconButton(onPressed: _cargarDatos, icon: Icon(Icons.refresh, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (_slots.isEmpty) 
            const Padding(padding: EdgeInsets.all(48), child: Text("No hay ausencias reportadas para hoy", style: TextStyle(color: Colors.grey)))
          else
            Column(
              children: [
                _buildTableHeader(),
                ..._slots.map((s) => _buildAbsenceRow(s)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _headerText("HORARIO", 1.5),
          _headerText("PROFESOR AUSENTE", 3),
          _headerText("AULA - MATERIA", 3),
          _headerText("GUARDIA ASIGNADA", 3),
          const SizedBox(width: 120),
        ],
      ),
    );
  }

  Widget _headerText(String t, double f) => Expanded(flex: f.toInt(), child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)));

  Widget _buildAbsenceRow(SlotMonitor s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("${s.inicio} - ${s.fin}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(flex: 3, child: Row(children: [
            CircleAvatar(radius: 14, backgroundColor: alertRed.withOpacity(0.1), child: const Icon(Icons.person, size: 14, color: Colors.red)),
            const SizedBox(width: 12),
            Text(s.profesorAusente, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ])),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.aula, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(s.asignatura, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ])),
          Expanded(flex: 3, child: Row(children: [
            Icon(s.esDesierta ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 14, color: s.esDesierta ? Colors.orange : Colors.green),
            const SizedBox(width: 8),
            Text(s.esDesierta ? "Sin asignar" : s.sustitutoNombre!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: s.esDesierta ? Colors.orange : Colors.green)),
          ])),
          ElevatedButton(
            onPressed: () => showAsignarGuardiaSheet(context, s, _cargarDatos),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("ASIGNAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardTeamScroll() {
    if (_guardias.isEmpty) return const SizedBox();

    final ahora = _guardias.where((g) => g.esActual).toList();
    final proximas = _guardias.where((g) => !g.esActual && !g.esPasado).toList();
    final completadas = _guardias.where((g) => g.esPasado).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ahora.isNotEmpty) ...[
          _buildSectionHeader("EN GUARDIA AHORA", Icons.radio_button_checked, const Color(0xFF6366F1)),
          const SizedBox(height: 16),
          Wrap(spacing: 16, runSpacing: 16, children: ahora.map((g) => _buildActiveGuardCard(g)).toList()),
          const SizedBox(height: 32),
        ],
        if (proximas.isNotEmpty) ...[
          _buildSectionHeader("PRÓXIMAS GUARDIAS", Icons.schedule, Colors.white70),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: proximas.map((g) => _buildFutureGuardCard(g)).toList()),
          const SizedBox(height: 32),
        ],
        if (completadas.isNotEmpty) ...[
          _buildSectionHeader("COMPLETADAS", Icons.check_circle_outline, Colors.white38),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: completadas.map((g) => _buildCompletedGuardChip(g)).toList()),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildActiveGuardCard(GuardiaMonitor g) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 10)],
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.white24, radius: 18, child: const Icon(Icons.person, color: Colors.white, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("${g.inicio} - ${g.fin}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                  ],
                ),
              ),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFutureGuardCard(GuardiaMonitor g) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              Text("${g.inicio} - ${g.fin}", style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedGuardChip(GuardiaMonitor g) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 10, color: Colors.white30),
          const SizedBox(width: 6),
          Text(g.nombre, style: const TextStyle(color: Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }
}
