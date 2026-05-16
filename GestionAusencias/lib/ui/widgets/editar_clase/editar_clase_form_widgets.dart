import 'package:flutter/material.dart';
import 'package:gestion_ausencias/core/utils/string_utils.dart';
export 'editar_clase_action_widgets.dart';

class EditarClaseSectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const EditarClaseSectionLabel({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF475569),
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

class EditarClaseDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const EditarClaseDropdown({super.key, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F46E5)),
          items: items.map((name) => DropdownMenuItem(
            value: name,
            child: Text(StringUtils.abbreviateAsignatura(name),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class EditarClaseSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const EditarClaseSelector({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditarClaseSectionLabel(icon: icon, text: label),
        EditarClaseDropdown(value: value, items: items, onChanged: onChanged),
      ],
    );
  }
}

class EditarClaseNotesField extends StatelessWidget {
  final TextEditingController controller;

  const EditarClaseNotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: "Añade notas o instrucciones para esta sesión...",
          hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
