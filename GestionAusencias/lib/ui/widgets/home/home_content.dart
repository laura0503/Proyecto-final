import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/ui/providers/notification_provider.dart';
import 'package:gestion_ausencias/ui/utils/app_strings.dart';
import 'home_header.dart';
import 'home_info_card.dart';
import 'home_department_list.dart';

class HomeContent extends StatelessWidget {
  final Function(int) onNavigate;
  final String departamentoSeleccionado;
  final Function(String) onDepartamentoChanged;
  final List<Profesor> todosProfesores;

  const HomeContent({
    super.key,
    required this.onNavigate,
    required this.departamentoSeleccionado,
    required this.onDepartamentoChanged,
    required this.todosProfesores,
  });

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().profesorActual;
    final nombre = usuario?.nombre ?? "Profesor";
    
    // Calcular departamentos únicos
    final depsFromDB = todosProfesores.map((p) => p.departamento).toSet();
    final List<String> todosDepartamentos = [
      'Todos',
      'General',
      ...depsFromDB.where((d) => d != 'General' && d != 'Todos'),
      ...HomeDepartmentList.depIcons.keys.where((k) => k != 'Todos' && k != 'General' && !depsFromDB.contains(k)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isNarrow ? 20 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                nombre: nombre,
                usuario: usuario,
                onShowNotifications: (ctx, provider) => _mostrarNotificaciones(ctx, provider),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildStatusCard(context, constraints, isNarrow, 'En clase', todosProfesores.where((p) => p.estadoActual == 'En clase').length.toString(), Icons.school_rounded, Colors.redAccent),
                  _buildStatusCard(context, constraints, isNarrow, 'Disponibles', todosProfesores.where((p) => p.estadoActual == 'Disponible').length.toString(), Icons.check_circle_rounded, Colors.green),
                  _buildStatusCard(context, constraints, isNarrow, 'Ausentes', todosProfesores.where((p) => p.estadoActual == 'Ausente').length.toString(), Icons.warning_rounded, Colors.orange),
                ],
              ),
              const SizedBox(height: 48),
              Text(AppStrings.get(context, 'dptos_personal'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF354231))),
              const SizedBox(height: 20),
              HomeDepartmentList(departamentos: todosDepartamentos, profesores: todosProfesores),
            ],
          ),
        );
      },
    );
  }

  void _mostrarNotificaciones(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: SizedBox(
          width: double.maxFinite,
          child: provider.notifications.isEmpty
              ? const Padding(padding: EdgeInsets.all(20.0), child: Text('No tienes notificaciones nuevas', textAlign: TextAlign.center))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final n = provider.notifications[index];
                    return ListTile(
                      leading: Icon(n.isRead ? Icons.mark_chat_read : Icons.mark_chat_unread, color: n.isRead ? Colors.grey : Colors.indigo),
                      title: Text(n.title),
                      subtitle: Text(n.message),
                      onTap: () { provider.markAsRead(n.id); Navigator.pop(context); },
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, BoxConstraints constraints, bool isNarrow, String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 120) / 3,
      child: HomeInfoCard(title: title, subtitle: value, icon: icon, color: color, onTap: () {}),
    );
  }
}
