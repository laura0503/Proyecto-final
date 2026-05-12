import 'package:flutter/material.dart';
import '../widgets/torre_control_section.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TorreControlSection(isDark: isDark),
    );
  }
}
