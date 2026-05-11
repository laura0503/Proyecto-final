part of 'edit_clase_dialog.dart';

extension _EditClaseDialogBuild on _EditClaseDialogState {
  Widget _buildDialogContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white54 : Colors.grey[600];
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E0D8);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: _cargando
              ? const SizedBox(
                  height: 160,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF354231))),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(textColor, subColor),
                    const SizedBox(height: 24),
                    if (widget.clase.id == 0) ...[
                      _buildBannerSinId(isDark),
                      const SizedBox(height: 18),
                    ],
                    _buildLabel('Día', textColor),
                    const SizedBox(height: 8),
                    _buildDiaDropdown(bgColor, textColor, borderColor, isDark),
                    const SizedBox(height: 18),
                    _buildLabel('Asignatura', textColor),
                    const SizedBox(height: 8),
                    _buildAsignaturaDropdown(
                        bgColor, textColor, subColor, borderColor, isDark),
                    const SizedBox(height: 18),
                    _buildLabel('Hora', textColor),
                    const SizedBox(height: 8),
                    _buildTramoDropdown(
                        bgColor, textColor, subColor, borderColor, isDark),
                    const SizedBox(height: 18),
                    _buildLabel('Nota', textColor),
                    const SizedBox(height: 8),
                    _buildNotaField(textColor, subColor, borderColor, isDark),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                    ],
                    const SizedBox(height: 24),
                    _buildBotones(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color? subColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF354231).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.edit_calendar_rounded,
              color: Color(0xFF354231), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editar clase',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textColor)),
              Text(
                '${widget.clase.dia}  •  ${widget.clase.inicio.length >= 5 ? widget.clase.inicio.substring(0, 5) : widget.clase.inicio}',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: Icon(Icons.close_rounded, color: subColor),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildBannerSinId(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Clase sin ID en la base de datos. Los cambios no se podrán guardar hasta reimportar el horario.',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.orange[200] : Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  Text _buildLabel(String label, Color textColor) => Text(label,
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: textColor));

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF354231),
              side: const BorderSide(color: Color(0xFF354231)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: (_guardando || widget.clase.id == 0) ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF354231),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
