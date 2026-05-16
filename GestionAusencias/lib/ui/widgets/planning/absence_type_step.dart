import 'package:flutter/material.dart';
import '../../../domain/entities/ausencia.dart';

class AbsenceTypeStep extends StatelessWidget {
  final TipoAusencia tipoSeleccionado;
  final Color primaryColor;
  final void Function(TipoAusencia) onChanged;

  const AbsenceTypeStep({
    super.key,
    required this.tipoSeleccionado,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 400;
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selecciona el motivo principal de tu solicitud.", 
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isSmall ? 1 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isSmall ? 3.5 : 1.4,
              children: [
                _TypeCard(type: TipoAusencia.bajaMedica, label: "Baja Médica", icon: Icons.medical_services_rounded, selected: tipoSeleccionado, primaryColor: primaryColor, onTap: onChanged),
                _TypeCard(type: TipoAusencia.vacaciones, label: "Vacaciones", icon: Icons.beach_access_rounded, selected: tipoSeleccionado, primaryColor: primaryColor, onTap: onChanged),
                _TypeCard(type: TipoAusencia.diasPersonales, label: "Asuntos Propios", icon: Icons.assignment_ind_rounded, selected: tipoSeleccionado, primaryColor: primaryColor, onTap: onChanged),
                _TypeCard(type: TipoAusencia.formacion, label: "Se encuentra malo", icon: Icons.sick_rounded, selected: tipoSeleccionado, primaryColor: primaryColor, onTap: onChanged),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  final TipoAusencia type;
  final String label;
  final IconData icon;
  final TipoAusencia selected;
  final Color primaryColor;
  final void Function(TipoAusencia) onTap;

  const _TypeCard({required this.type, required this.label, required this.icon, required this.selected, required this.primaryColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    final isSmall = MediaQuery.of(context).size.width < 400;

    return InkWell(
      onTap: () => onTap(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
              width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: isSmall
            ? Row(
                children: [
                  Icon(icon,
                      color: isSelected ? primaryColor : const Color(0xFF94A3B8),
                      size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? primaryColor
                                : const Color(0xFF475569),
                            fontSize: 13)),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: primaryColor, size: 18),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      color: isSelected ? primaryColor : const Color(0xFF94A3B8),
                      size: 32),
                  const SizedBox(height: 12),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? primaryColor
                              : const Color(0xFF475569),
                          fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
