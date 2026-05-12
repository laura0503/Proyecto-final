part of 'edit_clase_dialog.dart';

extension _EditClaseDialogDropdowns on _EditClaseDialogState {
  Widget _buildDropdownWrapper({
    required Color bgColor,
    required Color borderColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF9F7F2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _buildDiaDropdown(
      Color bgColor, Color textColor, Color borderColor, bool isDark) {
    return _buildDropdownWrapper(
      bgColor: bgColor,
      borderColor: borderColor,
      isDark: isDark,
      child: DropdownButton<int>(
        value: _diaSeleccionado,
        isExpanded: true,
        dropdownColor: bgColor,
        style: TextStyle(color: textColor, fontSize: 14),
        items: List.generate(
          _EditClaseDialogState._dias.length,
          (i) => DropdownMenuItem(
              value: i + 1, child: Text(_EditClaseDialogState._dias[i])),
        ),
        onChanged: widget.clase.id == 0
            ? null
            : (val) {
                if (val != null) setState(() => _diaSeleccionado = val);
              },
      ),
    );
  }

  Widget _buildAsignaturaDropdown(Color bgColor, Color textColor,
      Color? subColor, Color borderColor, bool isDark) {
    return _buildDropdownWrapper(
      bgColor: bgColor,
      borderColor: borderColor,
      isDark: isDark,
      child: DropdownButton<int>(
        value: _asignaturaSeleccionadaId,
        isExpanded: true,
        dropdownColor: bgColor,
        hint: Text(
          _asignaturaSeleccionadaNombre.isNotEmpty
              ? _asignaturaSeleccionadaNombre
              : 'Selecciona asignatura',
          style: TextStyle(color: subColor, fontSize: 14),
        ),
        style: TextStyle(color: textColor, fontSize: 14),
        items: _asignaturas
            .map((a) => DropdownMenuItem<int>(
                  value: a['id_asignaturas'] as int,
                  child: Text(a['nombre'] as String,
                      overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (val) => setState(() {
          _asignaturaSeleccionadaId = val;
          _asignaturaSeleccionadaNombre = _asignaturas
              .firstWhere((a) => a['id_asignaturas'] == val)['nombre']
              as String;
        }),
      ),
    );
  }

  Widget _buildTramoDropdown(Color bgColor, Color textColor, Color? subColor,
      Color borderColor, bool isDark) {
    return _buildDropdownWrapper(
      bgColor: bgColor,
      borderColor: borderColor,
      isDark: isDark,
      child: DropdownButton<int>(
        value: _tramoSeleccionadoId,
        isExpanded: true,
        dropdownColor: bgColor,
        hint: Text(
          _tramoSeleccionadoLabel.isNotEmpty
              ? _tramoSeleccionadoLabel
              : 'Selecciona hora',
          style: TextStyle(color: subColor, fontSize: 14),
        ),
        style: TextStyle(color: textColor, fontSize: 14),
        items: _tramos.map((t) {
          final ini = (t['horario_inicio'] as String).substring(0, 5);
          final fin = (t['horario_fin'] as String).substring(0, 5);
          return DropdownMenuItem<int>(
              value: t['id_horario'] as int, child: Text('$ini – $fin'));
        }).toList(),
        onChanged: (val) => setState(() {
          _tramoSeleccionadoId = val;
          final t = _tramos.firstWhere((t) => t['id_horario'] == val);
          _tramoSeleccionadoLabel =
              '${(t['horario_inicio'] as String).substring(0, 5)} – '
              '${(t['horario_fin'] as String).substring(0, 5)}';
        }),
      ),
    );
  }

  Widget _buildNotaField(
      Color textColor, Color? subColor, Color borderColor, bool isDark) {
    return TextField(
      controller: _notaController,
      maxLines: 3,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Añade una nota sobre esta clase...',
        hintStyle: TextStyle(color: subColor, fontSize: 13),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF9F7F2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF354231))),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}
