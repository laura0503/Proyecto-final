import 'package:flutter/material.dart';

class GuardSessionTaskList extends StatefulWidget {
  final List<String> tasks;
  final String absenceeName;

  const GuardSessionTaskList({
    super.key,
    required this.tasks,
    required this.absenceeName,
  });

  @override
  State<GuardSessionTaskList> createState() => _GuardSessionTaskListState();
}

class _GuardSessionTaskListState extends State<GuardSessionTaskList> {
  final Set<int> _completed = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Classroom Task List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F52BA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text("TODAY",
                  style: TextStyle(color: Color(0xFF0F52BA), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Tasks assigned by ${widget.absenceeName}",
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 32),
          ...List.generate(widget.tasks.length, (i) => _TaskItem(
            label: widget.tasks[i],
            completed: _completed.contains(i),
            onToggle: () => setState(() {
              if (_completed.contains(i)) {
                _completed.remove(i);
              } else {
                _completed.add(i);
              }
            }),
          )),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String label;
  final bool completed;
  final VoidCallback onToggle;

  const _TaskItem({required this.label, required this.completed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onToggle,
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF0F52BA) : Colors.transparent,
                border: Border.all(
                  color: completed ? const Color(0xFF0F52BA) : Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: completed ? Colors.grey[400] : const Color(0xFF1E293B),
                      decoration: completed ? TextDecoration.lineThrough : null,
                    )),
                  const SizedBox(height: 4),
                  Text("Ensure students show all working in their notebooks.",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.more_vert_rounded, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
