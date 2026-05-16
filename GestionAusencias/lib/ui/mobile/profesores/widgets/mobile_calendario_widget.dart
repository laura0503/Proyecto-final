import 'package:flutter/material.dart';
import '../../../../domain/entities/horario_clase.dart';

class MobileCalendarioWidget extends StatefulWidget {
  final List<HorarioClase> horario;
  final String titulo;

  const MobileCalendarioWidget({
    super.key,
    required this.horario,
    required this.titulo,
  });

  @override
  State<MobileCalendarioWidget> createState() => _MobileCalendarioWidgetState();
}

class _MobileCalendarioWidgetState extends State<MobileCalendarioWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  @override
  void initState() {
    super.initState();
    // Seleccionar el día actual si es laborable
    final hoy = DateTime.now().weekday;
    int initialIndex = (hoy >= 1 && hoy <= 5) ? hoy - 1 : 0;
    _tabController = TabController(length: _dias.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildDaySelector(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _dias.map((dia) => _buildDayList(dia)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "HORARIO SEMANAL",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF818CF8),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: _dias.map((dia) => Tab(text: dia)).toList(),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
      ),
    );
  }

  Widget _buildDayList(String dia) {
    final rawClases = widget.horario.where((h) => h.dia == dia).toList();

    // Agrupar por hora de inicio para evitar duplicados visuales
    final Map<String, HorarioClase> agrupados = {};
    for (var c in rawClases) {
      if (!agrupados.containsKey(c.inicio)) {
        agrupados[c.inicio] = c;
      }
    }

    final clasesDia = agrupados.values.toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

    if (clasesDia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text("Sin clases asignadas", style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: clasesDia.length,
      itemBuilder: (context, index) {
        final clase = clasesDia[index];
        return _buildClaseCard(clase);
      },
    );
  }

  Widget _buildClaseCard(HorarioClase clase) {
    final bool esGuardia = clase.esGuardia && clase.profesorAusente.isEmpty;
    final bool esSustitucion = clase.profesorAusente.isNotEmpty;

    if (esGuardia) return _buildGuardiaCard(clase);
    if (esSustitucion) return _buildSustitucionCard(clase);
    return _buildNormalCard(clase);
  }

  Widget _buildGuardiaCard(HorarioClase clase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildTimeInfo(clase.inicio, clase.fin, textColor: Colors.white),
            const SizedBox(width: 16),
            const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GUARDIA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5)),
                  Text('Turno de vigilancia',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustitucionCard(HorarioClase clase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildTimeInfo(clase.inicio, clase.fin, textColor: Colors.white),
            const SizedBox(width: 16),
            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clase.asignatura.isNotEmpty ? clase.asignatura : 'SUSTITUCIÓN',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('Sustituye a: ${clase.profesorAusente}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (clase.aula.isNotEmpty)
                    Text('Aula ${clase.aula}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalCard(HorarioClase clase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _buildTimeInfo(clase.inicio, clase.fin),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clase.asignatura.isNotEmpty ? clase.asignatura : 'Sin nombre',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (clase.grupo.isNotEmpty) ...[
                      Icon(Icons.people_alt_rounded,
                          size: 12, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(clase.grupo,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (clase.aula.isNotEmpty) ...[
                      Icon(Icons.location_on_rounded,
                          size: 12, color: Colors.white.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(clase.aula,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String inicio, String fin, {Color textColor = Colors.white}) {
    return Column(
      children: [
        Text(
          inicio.substring(0, 5),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        Container(
          width: 2,
          height: 10,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: textColor.withValues(alpha: 0.3),
        ),
        Text(
          fin.substring(0, 5),
          style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
