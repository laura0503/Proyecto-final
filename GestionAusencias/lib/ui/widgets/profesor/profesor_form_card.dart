import 'package:flutter/material.dart';

class ProfesorFormCard extends StatelessWidget {
  final TextEditingController nomController;
  final TextEditingController asigController;
  final TextEditingController curController;
  final TextEditingController depController;
  final List<String> departamentos;
  final void Function(String) onDepartamentoChanged;

  const ProfesorFormCard({
    super.key,
    required this.nomController,
    required this.asigController,
    required this.curController,
    required this.depController,
    required this.departamentos,
    required this.onDepartamentoChanged,
  });

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: c,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, size: 22, color: const Color(0xFF6C63FF)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
    );
  }

  Widget _dropdown() {
    return DropdownButtonFormField<String>(
      initialValue: departamentos.contains(depController.text) ? depController.text : 'Otro',
      decoration: const InputDecoration(
        labelText: "Departamento",
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(Icons.business_center_outlined,
          size: 22, color: Color(0xFF6C63FF)),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      items: departamentos.map((v) => DropdownMenuItem(
        value: v, child: Text(v, style: const TextStyle(fontSize: 15)))).toList(),
      onChanged: (v) { if (v != null) onDepartamentoChanged(v); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _field(nomController, "Nombre Completo", Icons.person_outline),
          const Divider(height: 32),
          _field(asigController, "Especialidad / Asignatura", Icons.school_outlined),
          const Divider(height: 32),
          _field(curController, "Curso (ej. 2º ESO)", Icons.book_outlined),
          const Divider(height: 32),
          _dropdown(),
        ],
      ),
    );
  }
}
