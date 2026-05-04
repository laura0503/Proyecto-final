
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../domain/entities/horario_clase.dart';
import '../widgets/home/fichaje_dialog.dart';

class GuardSessionScreen extends StatefulWidget {
  final HorarioClase guardia;

  const GuardSessionScreen({super.key, required this.guardia});

  @override
  State<GuardSessionScreen> createState() => _GuardSessionScreenState();
}

class _GuardSessionScreenState extends State<GuardSessionScreen> {
  final List<String> _tasks = [
    "Ejercicios página 42 (1-15)",
    "Repaso de ecuaciones de segundo grado",
    "Repartir hojas de ejercicios para casa",
  ];
  final Set<int> _completedTasks = {};
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _behaviorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Espacio para el Sidebar lateral si se integra en MainLayout, 
          // pero aquí lo haremos contenido puro.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 1100;
                      return isNarrow 
                        ? Column(
                            children: [
                              _buildTaskList(),
                              const SizedBox(height: 32),
                              _buildSessionReportForm(),
                              const SizedBox(height: 32),
                              _buildMaterialsPanel(),
                              const SizedBox(height: 32),
                              _buildClassroomSnapshot(),
                              const SizedBox(height: 32),
                              _buildHelpCard(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Panel Izquierdo: Tareas y Reporte
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildTaskList(),
                                    const SizedBox(height: 32),
                                    _buildSessionReportForm(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Panel Derecho: Materiales y Estado
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildMaterialsPanel(),
                                    const SizedBox(height: 32),
                                    _buildClassroomSnapshot(),
                                    const SizedBox(height: 32),
                                    _buildHelpCard(),
                                  ],
                                ),
                              ),
                            ],
                          );
                    }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Session Overview",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  "Clase de ${widget.guardia.asignatura} • Grupo ${widget.guardia.grupo}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
              color: const Color(0xFF64748B),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                // Simular guardado
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reporte enviado con éxito")),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F52BA), // Azul premium
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Complete Report", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Classroom Task List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F52BA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "TODAY",
                  style: TextStyle(color: Color(0xFF0F52BA), fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Tasks assigned by ${widget.guardia.profesorAusente}",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 32),
          ...List.generate(_tasks.length, (index) => _taskItem(index)),
        ],
      ),
    );
  }

  Widget _taskItem(int index) {
    bool completed = _completedTasks.contains(index);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          setState(() {
            if (completed) _completedTasks.remove(index);
            else _completedTasks.add(index);
          });
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF0F52BA) : Colors.transparent,
                border: Border.all(
                  color: completed ? const Color(0xFF0F52BA) : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tasks[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: completed ? Colors.grey[400] : const Color(0xFF1E293B),
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ensure students show all working in their notebooks.",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionReportForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_rounded, color: Color(0xFF0F52BA), size: 20),
              SizedBox(width: 12),
              Text(
                "Session Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text("General Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "How did the lesson go? Mention engagement levels...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Incidents & Behavioral Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _behaviorController,
            maxLines: 3,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              hintText: "Report specific student issues or disturbances...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Materials", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text("SYNC", style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w900, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 24),
          _materialItem(Icons.picture_as_pdf_rounded, "Algebra_Lesson_Plan.pdf", "1.2 MB • Google Drive", Colors.blue[50]!, Colors.blue),
          _materialItem(Icons.description_rounded, "Worksheet_Page_42.pdf", "840 KB • Google Drive", Colors.red[50]!, Colors.red),
          _materialItem(Icons.play_circle_fill_rounded, "Intro_to_Quadratics.mp4", "4.5 MB • Local Storage", Colors.amber[50]!, Colors.amber),
        ],
      ),
    );
  }

  Widget _materialItem(IconData icon, String title, String sub, Color bg, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis)),
                Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomSnapshot() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Classroom Snapshot", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text("24 Students", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.timer_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text("15m remaining", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey[100],
              color: const Color(0xFF0F52BA),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text("Session Progress: 75% complete", style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[900]!]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Need Assistance?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            "Contact the department head for immediate help with the lesson plan.",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[900],
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Call Support", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
