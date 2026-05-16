import 'package:flutter/material.dart';
import 'package:gestion_ausencias/core/layout/app_breakpoints.dart';
import '../widgets/torre_control_section.dart';
import '../mobile/monitor/screens/mobile_monitor_screen.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (context.isMobile) {
      return const MobileMonitorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TorreControlSection(isDark: isDark),
    );
  }
}
