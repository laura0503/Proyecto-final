
import 'package:flutter/material.dart';
import '../../../domain/entities/ausencia.dart';

class HomeAbsenceAlert extends StatelessWidget {
  final Ausencia ausencia;

  const HomeAbsenceAlert({super.key, required this.ausencia});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "CURRENT ABSENCE",
                        style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Unscheduled Absence Today",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  "You are currently marked as absent for your current class. Please confirm if this was an error or add a replacement request.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              _btn("Confirm", const Color(0xFF4F46E5), Colors.white),
              const SizedBox(height: 12),
              _btn("Dismiss", Colors.grey[100]!, Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, Color bg, Color text) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
    );
  }
}
