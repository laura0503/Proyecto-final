import 'package:flutter/material.dart';

class GuardSessionSidePanels extends StatelessWidget {
  const GuardSessionSidePanels({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _MaterialsPanel(),
        SizedBox(height: 32),
        _ClassroomSnapshot(),
        SizedBox(height: 32),
        _HelpCard(),
      ],
    );
  }
}

class _MaterialsPanel extends StatelessWidget {
  const _MaterialsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Materials",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text("SYNC",
                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w900, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 24),
          _MaterialItem(Icons.picture_as_pdf_rounded, "Algebra_Lesson_Plan.pdf",
            "1.2 MB • Google Drive", Colors.blue[50]!, Colors.blue),
          _MaterialItem(Icons.description_rounded, "Worksheet_Page_42.pdf",
            "840 KB • Google Drive", Colors.red[50]!, Colors.red),
          _MaterialItem(Icons.play_circle_fill_rounded, "Intro_to_Quadratics.mp4",
            "4.5 MB • Local Storage", Colors.amber[50]!, Colors.amber),
        ],
      ),
    );
  }
}

class _MaterialItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color bg;
  final MaterialColor color;

  const _MaterialItem(this.icon, this.title, this.sub, this.bg, this.color);

  @override
  Widget build(BuildContext context) {
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
                Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                    overflow: TextOverflow.ellipsis)),
                Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomSnapshot extends StatelessWidget {
  const _ClassroomSnapshot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Classroom Snapshot",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
          Text("Session Progress: 75% complete",
            style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[900]!]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Need Assistance?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Contact the department head for immediate help with the lesson plan.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[900],
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Call Support",
              style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
