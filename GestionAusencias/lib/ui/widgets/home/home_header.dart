import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/profesor.dart';
import '../../providers/notification_provider.dart';
import '../shared/profesor_avatar.dart';
import '../../utils/app_strings.dart';

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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.get(context, 'dashboard_title'),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D4F3C),
                  borderRadius: BorderRadius.circular(16),
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
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.search, color: Colors.grey[400]),
            ),
            const SizedBox(width: 8),
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      onPressed: () => onShowNotifications(context, notifProvider),
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.grey[400],
                      ),
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
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
                );
              },
            ),
            const SizedBox(width: 15),
            ProfesorAvatar(
              profesor: usuario ??
                  const Profesor(
                    id: '0',
                    nombre: 'Invitado',
                    asignatura: '',
                    curso: '',
                    departamento: 'General',
                    foto: 'https://i.pravatar.cc/150?u=invitado',
                    estadoAusente: false,
                  ),
              radius: 18,
            ),
          ],
        ),
      ],
    );
  }
}
