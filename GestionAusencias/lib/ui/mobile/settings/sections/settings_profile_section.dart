import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_strings.dart';

class SettingsProfileSection extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsProfileSection({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final prof = context.watch<AuthProvider>().profesorActual;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = prof?.nombre.substring(0, 1).toUpperCase() ?? 'L';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get(context, 'profile_info_title'),
          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prof?.nombre ?? 'No disponible',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${AppStrings.get(context, 'teacher_of')} ${prof?.asignatura ?? "General"}',
                          style: TextStyle(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1, color: Colors.white12),
              ),
              _InfoRow(icon: Icons.business_center_rounded, label: AppStrings.get(context, 'department'), value: prof?.departamento ?? 'Tecnología', iconColor: const Color(0xFF60A5FA)),
              _InfoRow(icon: Icons.access_time_rounded, label: AppStrings.get(context, 'teaching_schedule'), value: '${prof?.horarioEntrada ?? "08:00"} - ${prof?.horarioSalida ?? "14:30"}', iconColor: const Color(0xFF34D399)),
              _InfoRow(icon: Icons.groups_rounded, label: AppStrings.get(context, 'assigned_group'), value: prof?.curso ?? '2º Bachillerato A', iconColor: const Color(0xFFFBBF24)),
              _InfoRow(icon: Icons.location_on_rounded, label: AppStrings.get(context, 'usual_room'), value: prof?.ubicacionActual ?? 'Aula 102', iconColor: const Color(0xFF60A5FA)),
              _InfoRow(icon: Icons.school_rounded, label: AppStrings.get(context, 'tutoring'), value: prof?.tutoria ?? 'Sin tutoría', iconColor: const Color(0xFF818CF8)),
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: AppStrings.get(context, 'current_status'),
                value: prof?.estadoActual ?? (prof?.estadoAusente == true ? AppStrings.get(context, 'absent') : AppStrings.get(context, 'present')),
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(AppStrings.get(context, 'logout'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
