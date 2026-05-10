import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/guardia.dart';
import '../../domain/entities/profesor.dart';
import '../../domain/usecases/get_profesores_usecase.dart';
import '../../domain/usecases/get_guardias_usecase.dart';
import '../../domain/usecases/guardar_guardia_usecase.dart';
import '../../domain/usecases/eliminar_guardia_usecase.dart';
import 'detalle_guardia_screen.dart';
import '../widgets/guardias/guardias_body.dart';

class GuardiasScreen extends StatefulWidget {
  const GuardiasScreen({super.key});

  @override
  State<GuardiasScreen> createState() => _GuardiasScreenState();
}

class _GuardiasScreenState extends State<GuardiasScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Guardia> _guardias = [];
  List<Profesor> _profesores = [];
  List<Map<String, dynamic>> _tramos = [
    {'horario_inicio': '08:00:00', 'horario_fin': '09:00:00', 'texto': '1ª HORA', 'recreo': false},
    {'horario_inicio': '09:00:00', 'horario_fin': '10:00:00', 'texto': '2ª HORA', 'recreo': false},
    {'horario_inicio': '10:00:00', 'horario_fin': '11:00:00', 'texto': '3ª HORA', 'recreo': false},
    {'horario_inicio': '11:00:00', 'horario_fin': '11:15:00', 'texto': 'RECREO', 'recreo': true},
    {'horario_inicio': '11:15:00', 'horario_fin': '12:15:00', 'texto': '4ª HORA', 'recreo': false},
    {'horario_inicio': '12:15:00', 'horario_fin': '13:15:00', 'texto': '5ª HORA', 'recreo': false},
    {'horario_inicio': '13:15:00', 'horario_fin': '14:15:00', 'texto': '6ª HORA', 'recreo': false},
  ];
  bool _cargando = true;

  final Color primaryColor = const Color(0xFF6366F1);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        context.read<GetProfesoresUseCase>().execute(),
        context.read<GetGuardiasUseCase>().execute(),
        _supabase.from('horario_tramo').select().order('horario_inicio'),
      ]);
      setState(() {
        _profesores = results[0] as List<Profesor>;
        _guardias = results[1] as List<Guardia>;
        _tramos = List<Map<String, dynamic>>.from(results[2] as List);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  List<Guardia> _obtenerGuardiasDelDia() {
    return _guardias.where((g) =>
        g.fecha.day == _fechaSeleccionada.day &&
        g.fecha.month == _fechaSeleccionada.month &&
        g.fecha.year == _fechaSeleccionada.year).toList();
  }

  Future<void> _navegarADetalleGuardia([Guardia? guardia]) async {
    final eliminarUseCase = context.read<EliminarGuardiaUseCase>();
    final guardarUseCase = context.read<GuardarGuardiaUseCase>();
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleGuardiaScreen(
          guardia: guardia,
          profesores: _profesores,
          fecha: _fechaSeleccionada,
        ),
      ),
    );

    if (resultado != null) {
      if (resultado == 'eliminar') {
        if (guardia != null) {
          try { await eliminarUseCase.execute(guardia.id); } catch (_) {}
          setState(() => _guardias.removeWhere((g) => g.id == guardia.id));
        }
      } else if (resultado is Guardia) {
        try { await guardarUseCase.execute(resultado); } catch (_) {}
        setState(() {
          if (guardia == null || guardia.id.isEmpty) {
            _guardias.add(resultado);
          } else {
            final index = _guardias.indexWhere((g) => g.id == guardia.id);
            if (index != -1) _guardias[index] = resultado;
          }
        });
      }
    }
  }

  Future<void> _navegarNuevaGuardia(String? horario) async {
    String hIni = '08:00';
    String hFin = '09:00';
    if (horario != null) {
      hIni = horario.split(' - ')[0];
      hFin = horario.split(' - ')[1];
    }
    await _navegarADetalleGuardia(Guardia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: _fechaSeleccionada,
      horaInicio: hIni, horaFin: hFin,
      grupo: '', aula: '', profesorAusente: '', asignaturaAusente: '', tarea: '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarNuevaGuardia(null),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [primaryColor.withValues(alpha: 0.05), backgroundColor],
            ),
          )),
          SafeArea(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : GuardiasBody(
                    fechaSeleccionada: _fechaSeleccionada,
                    tramos: _tramos,
                    guardiasDelDia: _obtenerGuardiasDelDia(),
                    primaryColor: primaryColor,
                    onDateChanged: (date) => setState(() => _fechaSeleccionada = date),
                    onNuevaGuardia: _navegarNuevaGuardia,
                    onTapGuardia: _navegarADetalleGuardia,
                  ),
          ),
        ],
      ),
    );
  }
}
