import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../widgets/profesor/profesor_form_card.dart';
import 'wallpaper_selector_screen.dart';

class FormularioProfesorScreen extends StatefulWidget {
  final Profesor? profesor;
  const FormularioProfesorScreen({super.key, this.profesor});

  @override
  State<FormularioProfesorScreen> createState() => _FormularioProfesorScreenState();
}

class _FormularioProfesorScreenState extends State<FormularioProfesorScreen> {
  final _key = GlobalKey<FormState>();
  late TextEditingController _nom;
  late TextEditingController _asig;
  late TextEditingController _cur;
  late TextEditingController _dep;

  static const _departamentos = [
    'General', 'Matemáticas', 'Historia', 'Tecnología', 'Lengua',
    'Ciencias', 'Inglés', 'Educación Física', 'Arte', 'Música', 'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.profesor?.nombre ?? "");
    _asig = TextEditingController(text: widget.profesor?.asignatura ?? "");
    _cur = TextEditingController(text: widget.profesor?.curso ?? "");
    _dep = TextEditingController(text: widget.profesor?.departamento ?? "General");
  }

  @override
  void dispose() {
    _nom.dispose(); _asig.dispose(); _cur.dispose(); _dep.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_key.currentState!.validate()) {
      final p = Profesor(
        id: widget.profesor?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nom.text,
        asignatura: _asig.text,
        curso: _cur.text,
        departamento: _dep.text,
        foto: widget.profesor?.foto ?? "https://i.pravatar.cc/150?u=${_nom.text}",
        estadoAusente: widget.profesor?.estadoAusente ?? false,
      );
      Navigator.pop(context, p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profesor != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isEditing ? "Editar Perfil" : "Nuevo Profesor",
          style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WallpaperSelectorScreen())),
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (_, config, _) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            image: config.backgroundImageProvider != null
                ? DecorationImage(
                    image: config.backgroundImageProvider!, fit: BoxFit.cover, opacity: 0.8)
                : null,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DATOS PERSONALES",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  ProfesorFormCard(
                    nomController: _nom,
                    asigController: _asig,
                    curController: _cur,
                    depController: _dep,
                    departamentos: _departamentos,
                    onDepartamentoChanged: (v) => setState(() => _dep.text = v),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(isEditing ? "ACTUALIZAR DATOS" : "CREAR PROFESOR",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
