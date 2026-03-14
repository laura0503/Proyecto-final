import 'package:flutter/material.dart';
import '../../screens/settings_screen.dart';

class GuardiasHeader extends StatelessWidget {
  final Color primaryColor;
  final Color cardColor;

  const GuardiasHeader({
    super.key,
    required this.primaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Guardias',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              color: primaryColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: primaryColor,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
