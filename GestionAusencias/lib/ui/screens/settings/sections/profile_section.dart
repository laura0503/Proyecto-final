import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_strings.dart';
import '../widgets/settings_shared.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profesor = authProvider.profesorActual;

    if (profesor == null) {
      return Center(child: Text(AppStrings.get(context, 'no_session')));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(
          title: AppStrings.get(context, 'profile_info_title'),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        child: Text(
                          profesor.nombre.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profesor.nombre,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${AppStrings.get(context, 'teacher_of')} ${profesor.asignatura}",
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  ProfileInfoRow(
                    icon: Icons.business_center_rounded,
                    label: AppStrings.get(context, 'department'),
                    value: "Tecnología",
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoRow(
                    icon: Icons.access_time_rounded,
                    label: AppStrings.get(context, 'teaching_schedule'),
                    value: "08:00 - 14:30",
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoRow(
                    icon: Icons.group_rounded,
                    label: AppStrings.get(context, 'assigned_group'),
                    value: "2º Bachillerato A",
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoRow(
                    icon: Icons.room_rounded,
                    label: AppStrings.get(context, 'usual_room'),
                    value: "Aula 102",
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoRow(
                    icon: Icons.school_rounded,
                    label: AppStrings.get(context, 'tutoring'),
                    value: profesor.curso,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoRow(
                    icon: Icons.info_outline_rounded,
                    label: AppStrings.get(context, 'current_status'),
                    value: profesor.estadoAusente
                        ? AppStrings.get(context, 'absent')
                        : AppStrings.get(context, 'present'),
                    color: profesor.estadoAusente ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => authProvider.logout(),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(AppStrings.get(context, 'logout')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
