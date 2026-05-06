import 'package:flutter/material.dart';
import '../widgets/torre_control_section.dart';
import '../../core/layout/app_breakpoints.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding,
          vertical: 40,
        ),
        child: TorreControlSection(isDark: isDark),
      ),
    );
  }
}
