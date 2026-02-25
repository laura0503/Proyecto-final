import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 20),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white54 : const Color(0xFF6D6D72),
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final List<Color>? gradientColors;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsCard({
    super.key,
    required this.icon,
    this.iconBg,
    this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark
        ? const Color(0xFF1E293B).withOpacity(0.7)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);
    final titleColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6D6D72);
    final arrowColor = isDark ? Colors.white38 : const Color(0xFFC7C7CC);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: gradientColors == null
                            ? (iconBg ?? Colors.grey)
                            : null,
                        gradient: gradientColors != null
                            ? LinearGradient(
                                colors: gradientColors!,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: titleColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: arrowColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
