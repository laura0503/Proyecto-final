import 'package:flutter/material.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import 'wallpaper_selector_screen.dart';

class FormularioProfesorScreen extends StatefulWidget {
  final Profesor? profesor;
  const FormularioProfesorScreen({super.key, this.profesor});

  @override
  State<FormularioProfesorScreen> createState() =>
      _FormularioProfesorScreenState();
}

class _FormularioProfesorScreenState extends State<FormularioProfesorScreen> {
  final _key = GlobalKey<FormState>();

  late TextEditingController _nom;
  late TextEditingController _asig;
  late TextEditingController _cur;
  late TextEditingController _dep;
  late TextEditingController _contrasena;
  bool _ocultarContrasena = true;

  final List<String> _departamentos = [
    'General',
    'Matemáticas',
    'Historia',
    'Tecnología',
    'Lengua',
    'Ciencias',
    'Inglés',
    'Educación Física',
    'Arte',
    'Música',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.profesor?.nombre ?? "");
    _asig = TextEditingController(text: widget.profesor?.asignatura ?? "");
    _cur = TextEditingController(text: widget.profesor?.curso ?? "");
    _dep = TextEditingController(
      text: widget.profesor?.departamento ?? "General",
    );
    _contrasena = TextEditingController(
      text: widget.profesor?.contrasena ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF6C63FF);
    final isEditing = widget.profesor != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEditing ? "Editar Perfil" : "Nuevo Profesor",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.wallpaper),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WallpaperSelectorScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ConfigProvider>(
        builder: (context, config, child) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              image: config.backgroundImageProvider != null
                  ? DecorationImage(
                      image: config.backgroundImageProvider!,
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    )
                  : null,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Información de Acceso"),
                    const SizedBox(height: 16),
                    _buildCard([
                      _buildTextField(
                        controller: _contrasena,
                        label: "PIN de Acceso",
                        icon: Icons.lock_outline,
                        isPassword: _ocultarContrasena,
                        keyboardType: TextInputType.number,
                        suffix: IconButton(
                          icon: Icon(
                            _ocultarContrasena
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _ocultarContrasena = !_ocultarContrasena,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle("Datos Personales"),
                    const SizedBox(height: 16),
                    _buildCard([
                      _buildTextField(
                        controller: _nom,
                        label: "Nombre Completo",
                        icon: Icons.person_outline,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _asig,
                        label: "Especialidad / Asignatura",
                        icon: Icons.school_outlined,
                      ),
                      const Divider(height: 32),
                      _buildTextField(
                        controller: _cur,
                        label: "Curso (ej. 2º ESO)",
                        icon: Icons.book_outlined,
                      ),
                      const Divider(height: 32),
                      _buildDropdownField(),
                    ]),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isEditing ? "ACTUALIZAR DATOS" : "CREAR PROFESOR",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, size: 22, color: const Color(0xFF6C63FF)),
        suffixIcon: suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _departamentos.contains(_dep.text) ? _dep.text : 'Otro',
      decoration: const InputDecoration(
        labelText: "Departamento",
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(
          Icons.business_center_outlined,
          size: 22,
          color: Color(0xFF6C63FF),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      items: _departamentos.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(fontSize: 15)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _dep.text = newValue);
        }
      },
    );
  }

  void _guardar() {
    if (_key.currentState!.validate()) {
      final p = Profesor(
        id:
            widget.profesor?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nom.text,
        asignatura: _asig.text,
        curso: _cur.text,
        departamento: _dep.text,
        contrasena: _contrasena.text,
        foto:
            widget.profesor?.foto ?? "https://i.pravatar.cc/150?u=${_nom.text}",
        estadoAusente: widget.profesor?.estadoAusente ?? false,
      );
      Navigator.pop(context, p);
    }
  }
}
