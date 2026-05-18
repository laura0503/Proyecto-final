import 'package:flutter/material.dart';
import '../../../../domain/entities/horario_clase.dart';
import 'calendario_clase_cards.dart';

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

class _MobileCalendarioWidgetState extends State<MobileCalendarioWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now().weekday;
    final initialIndex = (hoy >= 1 && hoy <= 5) ? hoy - 1 : 0;
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
                  'HORARIO SEMANAL',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
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
    final Map<String, HorarioClase> agrupados = {};
    for (var c in rawClases) {
      agrupados.putIfAbsent(c.inicio, () => c);
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
            const Text('Sin clases asignadas', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: clasesDia.length,
      itemBuilder: (context, index) {
        final clase = clasesDia[index];
        if (clase.esGuardia && clase.profesorAusente.isEmpty) {
          return CalendarioGuardiaCard(clase: clase);
        }
        if (clase.profesorAusente.isNotEmpty) {
          return CalendarioSustitucionCard(clase: clase);
        }
        return CalendarioNormalCard(clase: clase);
      },
    );
  }
}
