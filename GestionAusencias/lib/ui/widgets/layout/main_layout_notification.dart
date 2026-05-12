import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/notification_provider.dart';

class MainLayoutNotification extends StatelessWidget {
  const MainLayoutNotification({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>().notifications;
    if (notifications.isEmpty) return const SizedBox.shrink();

    final latest = notifications.first;
    final diff = DateTime.now().difference(latest.timestamp).inSeconds;
    if (diff > 5) return const SizedBox.shrink();

    return Positioned(
      top: 40,
      right: 40,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (_, value, child) => Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        ),
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30, offset: const Offset(0, 15)),
            ],
            border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(latest.title,
                      style: const TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 16, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(latest.message,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.2)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () =>
                    context.read<NotificationProvider>().markAsRead(latest.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
