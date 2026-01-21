import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_ausencias/core/utils/date.dart';
import '../../data/models/profesor_model.dart';
import '../../data/repositories/profesor_repository.dart';

class DatosSlot {
  final TextEditingController controller;
  String tipo;
  Color color;
  DatosSlot({
    required this.controller,
    this.tipo = "OTRO",
    this.color = Colors.grey,
  });
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  final Map<String, DatosSlot> _registroFaltas = {};
  List<Profesores> _profesoresReales = [];
  bool _cargandoProfesores = true;

  final Color primaryColor = const Color(0xFF6C63FF);
  final Color backgroundColor = const Color(0xFFF0F2F5);
  final Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    try {
      final lista = await ProfesorRepository.obtenerProfesores();
      setState(() {
        _profesoresReales = lista;
        _cargandoProfesores = false;
      });
    } catch (e) {
      setState(() => _cargandoProfesores = false);
    }
  }

  void _cambiarSemana(int semanas) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: semanas * 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final diasSemana = DateUtilsCustom.generarSemana(_fechaSeleccionada);
    final mesAno = DateFormat('MMMM yyyy', 'es').format(_fechaSeleccionada);
    final nSemana = DateUtilsCustom.numeroSemanaDelMes(_fechaSeleccionada);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: _cargandoProfesores
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                _buildHeaderModerno(mesAno, nSemana),
                _buildLeyendaEstilizada(),
                _buildCabeceraDias(diasSemana),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _profesoresReales.length,
                    itemBuilder: (context, index) => _filaProfesorArmonica(
                      diasSemana,
                      _profesoresReales[index],
                      index,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderModerno(String mesAno, int nSemana) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mesAno.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Color(0xFF2D3250),
                ),
              ),
              const Text(
                "Planificación Semanal",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          _selectorSemana(nSemana),
        ],
      ),
    );
  }

  Widget _selectorSemana(int nSemana) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: primaryColor),
            onPressed: () => _cambiarSemana(-1),
          ),
          Text(
            "S$nSemana",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () => _cambiarSemana(1),
          ),
        ],
      ),
    );
  }

  Widget _buildLeyendaEstilizada() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _badgeLeyenda(Colors.redAccent, "Falta"),
          _badgeLeyenda(Colors.orangeAccent, "Retraso"),
          _badgeLeyenda(Colors.lightBlueAccent, "Justificado"),
        ],
      ),
    );
  }

  Widget _badgeLeyenda(Color color, String texto) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabeceraDias(List<DateTime> dias) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 100,
            child: Icon(Icons.school_outlined, color: Colors.grey),
          ),
          ...dias.map((d) {
            bool esHoy =
                d.day == DateTime.now().day && d.month == DateTime.now().month;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                decoration: esHoy
                    ? BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E', 'es').format(d).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: esHoy ? Colors.white70 : Colors.grey,
                      ),
                    ),
                    Text(
                      d.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: esHoy ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filaProfesorArmonica(
    List<DateTime> dias,
    Profesores profesor,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text(
                      profesor.nombre[0],
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profesor.nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ...dias.map(
              (fecha) => Expanded(
                child: GestureDetector(
                  onTap: () => _abrirAgenda(fecha, profesor.nombre),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(minHeight: 70),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildEventosDetallados(profesor.nombre, fecha),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventosDetallados(String profesor, DateTime fecha) {
    String fechaKey = DateFormat('yyyy-MM-dd').format(fecha);
    List<Widget> widgetsEventos = [];

    _registroFaltas.forEach((key, data) {
      if (key.startsWith("${profesor}_$fechaKey") &&
          data.controller.text.isNotEmpty) {
        String hora = key.split('_').last;
        widgetsEventos.add(
          Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              border: Border(left: BorderSide(color: data.color, width: 3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$hora:00",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
                Text(
                  data.controller.text,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgetsEventos,
    );
  }

  void _abrirAgenda(DateTime fecha, String profesor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.event_note, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profesor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM', 'es').format(fecha),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 15, // Ajustado para cubrir de 8 a 22
                itemBuilder: (context, index) =>
                    _buildFilaHora(profesor, fecha, index + 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaHora(String profesor, DateTime fecha, int hora) {
    String key = "${profesor}_${DateFormat('yyyy-MM-dd').format(fecha)}_$hora";
    final datos = _registroFaltas.putIfAbsent(
      key,
      () => DatosSlot(controller: TextEditingController()),
    );
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              Text(
                "$hora:00",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: datos.color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: datos.color.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _dot(key, Colors.redAccent, "FALTA", setModalState),
                          _dot(
                            key,
                            Colors.orangeAccent,
                            "RETRASO",
                            setModalState,
                          ),
                          _dot(
                            key,
                            Colors.lightBlueAccent,
                            "OTRO",
                            setModalState,
                          ),
                          const Spacer(),
                          Text(
                            datos.tipo,
                            style: TextStyle(
                              fontSize: 10,
                              color: datos.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: datos.controller,
                        decoration: const InputDecoration(
                          hintText: "Escribe el motivo...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13),
                        ),
                        onChanged: (v) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(String key, Color c, String t, StateSetter setModalState) {
    bool seleccionado = _registroFaltas[key]!.color == c;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _registroFaltas[key]!.color = c;
          _registroFaltas[key]!.tipo = t;
        });
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: seleccionado ? 3 : 0),
          boxShadow: seleccionado
              ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 6)]
              : [],
        ),
      ),
    );
  }
}
//para poner el motivo de las horarios el widget que hemos utilizado IntrinsicHeight(Al envolver la fila del profesor con IntrinsicHeight, obligamos a que todas las celdas de esa fila (el nombre y los 5 días) se estiren hasta alcanzar la altura de la celda más larga.)
//Aplicar hors--> column 
//para los colores ha puesto esto Glassmorphism
