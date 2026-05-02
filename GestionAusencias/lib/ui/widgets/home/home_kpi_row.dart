import 'dart:ui';
import 'package:flutter/material.dart';

class HomeKpiRow extends StatelessWidget {
  final int ausentes;
  final int retrasos;
  final int sustitutos;
  final int eficiencia;

  const HomeKpiRow({
    super.key,
    required this.ausentes,
    required this.retrasos,
    required this.sustitutos,
    required this.eficiencia,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _KpiItem('Ausencias Hoy', '$ausentes', const Color(0xFFEF4444)),
      _KpiItem('Retrasos', '$retrasos', const Color(0xFFF97316)),
      _KpiItem('Sustitutos Activos', '$sustitutos', const Color(0xFF3B82F6)),
      _KpiItem('Eficiencia de Plan', '$eficiencia%', const Color(0xFF22C55E)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        if (isNarrow) {
          return Column(
            children: [
              Row(children: [
                _KpiCard(items[0]),
                const SizedBox(width: 12),
                _KpiCard(items[1]),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _KpiCard(items[2]),
                const SizedBox(width: 12),
                _KpiCard(items[3]),
              ]),
            ],
          );
        }
        return Row(
          children: [
            _KpiCard(items[0]), const SizedBox(width: 12),
            _KpiCard(items[1]), const SizedBox(width: 12),
            _KpiCard(items[2]), const SizedBox(width: 12),
            _KpiCard(items[3]),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;
  const _KpiCard(this.item);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glass = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.72);

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: glass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: item.color,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final Color color;
  const _KpiItem(this.label, this.value, this.color);
}
