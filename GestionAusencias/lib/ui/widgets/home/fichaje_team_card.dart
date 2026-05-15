import 'package:flutter/material.dart';

class FichajeTeamCard extends StatelessWidget {
  final String name;
  final String time;
  final String location;
  final bool isMe;
  final bool isRecommended;
  final String? avatar;

  const FichajeTeamCard({
    super.key,
    required this.name,
    required this.time,
    required this.location,
    this.isMe = false,
    this.isRecommended = false,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isMe
        ? const Color(0xFF5856D6)
        : (isRecommended ? const Color(0xFF007AFF) : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cardColor.withValues(alpha: isMe || isRecommended ? 0.3 : 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              image: avatar != null
                  ? DecorationImage(image: NetworkImage(avatar!), fit: BoxFit.cover)
                  : null,
            ),
            child: avatar == null
                ? Icon(isMe ? Icons.person_rounded : Icons.person_outline_rounded, size: 16, color: cardColor)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF1C1C1E))),
                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.w600)),
                if (isRecommended)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(4)),
                    child: const Text("RECOMENDADO", style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
