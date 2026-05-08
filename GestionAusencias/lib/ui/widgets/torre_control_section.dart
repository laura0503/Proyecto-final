import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SlotMonitor {
  final int ausenciaId;
  final int? idTramo;
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
    this.idTramo,
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

class _GuardiaMonitor {
  final int profId;
  final String nombre;
  final String inicio;
  final String fin;
  final int? idTramo;
  final bool esActual;

  _GuardiaMonitor({
    required this.profId,
    required this.nombre,
    required this.inicio,
    required this.fin,
    this.idTramo,
    required this.esActual,
  });
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
  List<_GuardiaMonitor> _guardias = [];

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
    final dateStr = '${hoy.year.toString().padLeft(4, '0')}-'
        '${hoy.month.toString().padLeft(2, '0')}-'
        '${hoy.day.toString().padLeft(2, '0')}';

    try {
      final results = await Future.wait([
        // 1. Ausencias de hoy
        supabase.from('ausencia').select('''
          id_ausencia,
          fecha,
          profesor_ausente:id_profesor_ausente (nombre),
          horario:id_horario_sesion (
            id_tramo,
            Asignaturas:id_asignatura (nombre),
            aulas:id_aula (nombre),
            grupo:id_grupo (nombre),
            horario_tramo:id_tramo (horario_inicio, horario_fin)
          )
        ''').eq('fecha', dateStr),

        // 2. Sustituciones de hoy
        supabase.from('sustitucion').select('''
          id_ausencia,
          id_sustitucion,
          sustituto:id_profesor_sustituto (nombre),
          ausencia:id_ausencia (fecha)
        ''').eq('ausencia.fecha', dateStr),

        // 3. Profesores de guardia hoy (usando dia_semana int)
        supabase.from('horario').select('''
          id_profesor,
          id_tramo,
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
          idTramo: horario?['id_tramo'] as int?,
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

      final guardias = guardiasRaw.map((g) {
        final tramo = g['horario_tramo'] ?? {};
        final inicio = (tramo['horario_inicio'] ?? '00:00').toString().substring(0, 5);
        final fin = (tramo['horario_fin'] ?? '00:00').toString().substring(0, 5);
        return _GuardiaMonitor(
          profId: g['id_profesor'] as int? ?? 0,
          nombre: g['profesores']?['nombre']?.toString() ?? 'N/A',
          inicio: inicio,
          fin: fin,
          idTramo: g['id_tramo'] as int?,
          esActual: nowStr.compareTo(inicio) >= 0 && nowStr.compareTo(fin) < 0,
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

  // Muestra el sheet de asignación consultando guardias disponibles por tramo
  void _showAsignarGuardiaSheet(_SlotMonitor slot) async {
    final supabase = Supabase.instance.client;
    final hoy = DateTime.now();
    List<Map<String, dynamic>> guardasDisponibles = [];

    if (slot.idTramo != null) {
      try {
        // Todos los guardias del tramo
        final guardResp = await supabase
            .from('horario')
            .select('id_profesor, profesores:id_profesor(nombre)')
            .eq('id_tramo', slot.idTramo!)
            .eq('dia_semana', hoy.weekday)
            .eq('es_guardia', true);
        final allGuards = List<Map<String, dynamic>>.from(guardResp as List);

        // Horarios del mismo tramo para buscar ausencias simultáneas
        final sameTramoResp = await supabase
            .from('horario')
            .select('id')
            .eq('id_tramo', slot.idTramo!)
            .eq('dia_semana', hoy.weekday);
        final sameIds = (sameTramoResp as List).map((h) => h['id'] as int).toList();

        // Ausencias en ese tramo hoy (excluyendo la actual)
        final dateStr = '${hoy.year.toString().padLeft(4, '0')}-'
            '${hoy.month.toString().padLeft(2, '0')}-'
            '${hoy.day.toString().padLeft(2, '0')}';
        final otrasAusencias = await supabase
            .from('ausencia')
            .select('id_ausencia')
            .inFilter('id_horario_sesion', sameIds)
            .eq('fecha', dateStr)
            .neq('id_ausencia', slot.ausenciaId);

        final otrasIds = (otrasAusencias as List).map((a) => a['id_ausencia'] as int).toList();
        final Set<int> yaAsignados = {};
        if (otrasIds.isNotEmpty) {
          final sustResp = await supabase
              .from('sustitucion')
              .select('id_profesor_sustituto')
              .inFilter('id_ausencia', otrasIds);
          for (final s in sustResp as List) {
            final pid = s['id_profesor_sustituto'];
            if (pid != null) yaAsignados.add(pid as int);
          }
        }

        guardasDisponibles = allGuards.where((g) {
          final pid = g['id_profesor'] as int?;
          return pid != null && !yaAsignados.contains(pid);
        }).toList();
      } catch (e) {
        debugPrint("Error cargando guardias: $e");
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Asignar Guardia", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(
              "Cubriendo a: ${slot.profesorAusente}  •  ${slot.inicio} - ${slot.fin}",
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            if (guardasDisponibles.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Expanded(child: Text("No hay profesores de guardia disponibles en este tramo.", style: TextStyle(color: Colors.redAccent, fontSize: 13))),
                  ],
                ),
              )
            else
              ...guardasDisponibles.map((g) {
                final nombre = g['profesores']?['nombre'] as String? ?? 'Desconocido';
                final profId = g['id_profesor'] as int?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFF6366F1), size: 20),
                    ),
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("Guardia ${slot.inicio} - ${slot.fin}", style: const TextStyle(fontSize: 11)),
                    trailing: ElevatedButton(
                      onPressed: profId == null ? null : () async {
                        Navigator.pop(ctx);
                        await _realizarAsignacion(slot.ausenciaId, profId, nombre);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                      child: const Text("ASIGNAR"),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _realizarAsignacion(int ausenciaId, int profId, String nombre) async {
    final supabase = Supabase.instance.client;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sust = await supabase
          .from('sustitucion')
          .select()
          .eq('id_ausencia', ausenciaId)
          .maybeSingle();

      if (sust != null) {
        await supabase
            .from('sustitucion')
            .update({'id_profesor_sustituto': profId})
            .eq('id_sustitucion', sust['id_sustitucion']);
      } else {
        await supabase.from('sustitucion').insert({
          'id_ausencia': ausenciaId,
          'id_profesor_sustituto': profId,
          'puntos_karma': 1.0,
        });
      }
      await _cargarDatos();
      messenger.showSnackBar(SnackBar(
        content: Text("$nombre asignado como guardia ✓"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ));
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
        // 1. TÍTULO Y BOTONES
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
                _buildActionBtn(Icons.add_alert_rounded, "Nueva Alerta", color: const Color(0xFF4F46E5), isPrimary: true),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // 2. KPIs
        Row(
          children: [
            _buildKpiCard("PROFESORES AUSENTES", "${_slots.length}", "+5% vs ayer", Icons.people_outline, const Color(0xFF4F46E5)),
            const SizedBox(width: 20),
            _buildKpiCard("GUARDIAS CUBIERTAS", "$cubiertas", "$eficiencia% eficiencia", Icons.verified_user_outlined, const Color(0xFF64748B)),
            const SizedBox(width: 20),
            _buildCriticalCard(desiertas),
          ],
        ),
        const SizedBox(height: 32),

        // 3. NUEVA CARD: GESTIÓN DE GUARDIAS DEL DÍA
        _buildGestionGuardiasCard(),
        const SizedBox(height: 48),

        const SizedBox(height: 48),

        // 4. EQUIPO DE GUARDIA (Todas las guardias del día)
        Row(
          children: [
            const Text("Equipo de Guardia para Hoy", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const Spacer(),
            _buildLegendDot("Disponible ahora", const Color(0xFF6366F1)),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_guardias.isEmpty)
          _buildEmptyState(msg: "No hay profesores asignados de guardia hoy")
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _guardias.map((g) => _buildGuardCard(g)).toList(),
          ),
        
        const SizedBox(height: 60),
      ],
    );
  }

  // ─── NUEVA CARD PRINCIPAL DE GESTIÓN ───────────────────────────────────────
  Widget _buildGestionGuardiasCard() {
    final fechaStr = DateFormat('EEEE d MMMM', 'es').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Gestión de Guardias del Día",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      fechaStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
                  onPressed: _cargarDatos,
                  tooltip: "Actualizar",
                ),
              ],
            ),
          ),

          // Cabecera tabla
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                _headerCell("HORARIO", flex: 2),
                _headerCell("PROFESOR AUSENTE", flex: 3),
                _headerCell("AULA • MATERIA", flex: 3),
                _headerCell("GUARDIA ASIGNADA", flex: 3),
                _headerCell("", flex: 2),
              ],
            ),
          ),

          // Filas de ausencias
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
            )
          else if (_slots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      "No hay ausencias registradas hoy",
                      style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_slots.length, (i) {
              final s = _slots[i];
              final isLast = i == _slots.length - 1;
              return _buildGestionRow(s, isLast);
            }),

          // Footer: guardias activos ahora
          if (_guardias.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.04),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PROFESORES DE GUARDIA HOY",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey[500], letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _guardias.map((g) => _buildGuardChip(g)).toList(),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildGestionRow(_SlotMonitor s, bool isLast) {
    final bool isNow = s.esActual;
    return Container(
      decoration: BoxDecoration(
        color: isNow ? const Color(0xFF4F46E5).withOpacity(0.03) : Colors.transparent,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey[100]!),
          left: isNow ? const BorderSide(color: Color(0xFF4F46E5), width: 3) : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Horario
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${s.inicio} - ${s.fin}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: isNow ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                  ),
                ),
                if (isNow)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("AHORA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
                  ),
              ],
            ),
          ),

          // Profesor ausente
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_off_rounded, size: 14, color: Colors.redAccent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.profesorAusente,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Aula y materia
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.aula, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                Text(s.asignatura, style: TextStyle(fontSize: 11, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Guardia asignada
          Expanded(
            flex: 3,
            child: s.sustitutoNombre != null
                ? Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.sustitutoNombre!,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 6),
                      Text(
                        "Sin asignar",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.orange[700]),
                      ),
                    ],
                  ),
          ),

          // Botón acción
          Expanded(
            flex: 2,
            child: s.esDesierta
                ? ElevatedButton(
                    onPressed: () => _showAsignarGuardiaSheet(s),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    child: const Text("ASIGNAR"),
                  )
                : TextButton.icon(
                    onPressed: () => _showAsignarGuardiaSheet(s),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                    label: const Text("Cambiar", style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardChip(_GuardiaMonitor g) {
    final bool isNow = g.esActual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isNow ? const Color(0xFF4F46E5).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNow ? const Color(0xFF4F46E5).withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 12, color: isNow ? const Color(0xFF4F46E5) : Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            g.nombre.split(',').first,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isNow ? const Color(0xFF4F46E5) : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "${g.inicio}-${g.fin}",
            style: TextStyle(fontSize: 10, color: isNow ? const Color(0xFF4F46E5).withOpacity(0.7) : Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ─── WIDGETS EXISTENTES ─────────────────────────────────────────────────────

  Widget _buildGuardCard(_GuardiaMonitor g) {
    final bool isNow = g.esActual;
    final color = isNow ? const Color(0xFF6366F1) : Colors.grey.shade400;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNow ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isNow ? color : Colors.transparent, width: 2),
        boxShadow: isNow ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.shield_rounded, color: color, size: 20),
              if (isNow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text("AHORA", style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            g.nombre,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isNow ? const Color(0xFF1E293B) : Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "${g.inicio} - ${g.fin}",
            style: TextStyle(fontSize: 11, color: isNow ? color : Colors.grey.shade400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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
            ),
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
            _buildSmallActionBtn("Asignar Guardia Ahora", color, () => _showAsignarGuardiaSheet(s))
          else
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey.shade400, size: 14),
                const SizedBox(width: 6),
                Text("Cubierto", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
                const Spacer(),
                TextButton(
                  onPressed: () => _showAsignarGuardiaSheet(s),
                  child: const Text("Cambiar", style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
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
        ),
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

  Widget _buildSmallActionBtn(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
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

  Widget _buildEmptyState({String msg = "No hay ausencias hoy"}) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey)),
        ],
      ),
    );
  }
}
