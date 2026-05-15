import 'package:flutter/material.dart';

const _accentColor = Color(0xFF4F46E5);

class HomeScheduleHeader extends StatelessWidget {
  final int total;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const HomeScheduleHeader({
    super.key,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 24,
        vertical: isSmall ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: isSmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(isSmall: true),
                const SizedBox(height: 10),
                Row(children: [
                  _buildNavigator(),
                  const SizedBox(width: 12),
                  _buildBadge(),
                ]),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTitle(isSmall: false),
                Row(children: [
                  _buildNavigator(),
                  const SizedBox(width: 16),
                  _buildBadge(),
                ]),
              ],
            ),
    );
  }

  Widget _buildTitle({required bool isSmall}) {
    return Row(
      children: [
        Icon(Icons.calendar_month_outlined, color: _accentColor, size: isSmall ? 22 : 28),
        const SizedBox(width: 10),
        Text(
          "Mi Agenda Semanal",
          style: TextStyle(
            fontSize: isSmall ? 18 : 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: isSmall ? -0.8 : -1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left, onPrevious),
          const Text(
            " HOY ",
            style: TextStyle(color: _accentColor, fontWeight: FontWeight.w900, fontSize: 11),
          ),
          _navBtn(Icons.chevron_right, onNext),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: _accentColor),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        "$total guardias esta semana",
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}
