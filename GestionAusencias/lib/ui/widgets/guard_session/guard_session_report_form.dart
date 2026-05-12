import 'package:flutter/material.dart';

class GuardSessionReportForm extends StatefulWidget {
  const GuardSessionReportForm({super.key});

  @override
  State<GuardSessionReportForm> createState() => _GuardSessionReportFormState();
}

class _GuardSessionReportFormState extends State<GuardSessionReportForm> {
  final _commentController = TextEditingController();
  final _behaviorController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _behaviorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_rounded, color: Color(0xFF0F52BA), size: 20),
              SizedBox(width: 12),
              Text("Session Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 32),
          const Text("General Comments",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "How did the lesson go? Mention engagement levels...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Incidents & Behavioral Notes",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _behaviorController,
            maxLines: 3,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 20),
              hintText: "Report specific student issues or disturbances...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
