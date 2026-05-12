import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/profesor.dart';
import '../../providers/notification_provider.dart';
import '../shared/profesor_avatar.dart';

class HomeHeader extends StatelessWidget {
  final String nombre;
  final Profesor? usuario;
  final Function(BuildContext, NotificationProvider) onShowNotifications;

  const HomeHeader({
    super.key,
    required this.nombre,
    required this.usuario,
    required this.onShowNotifications,
  });

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _nombreCorto {
    if (nombre.isEmpty) return 'Profesor';
    final partes = nombre.trim().split(' ');
    return partes.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white60 : Colors.grey[500];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_saludo, $_nombreCorto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: labelColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF354231).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                      style: const TextStyle(
                        color: Color(0xFFE2E9E1),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) => Stack(
                children: [
                  IconButton(
                    onPressed: () => onShowNotifications(context, notifProvider),
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: subColor,
                    ),
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ProfesorAvatar(
              profesor:
                  usuario ??
                  const Profesor(
                    id: '0',
                    nombre: 'Invitado',
                    asignatura: '',
                    curso: '',
                    departamento: 'General',
                    foto: 'https://i.pravatar.cc/150?u=invitado',
                    estadoAusente: false,
                  ),
              radius: 20,
            ),
          ],
        ),
      ],
    );
  }
}
