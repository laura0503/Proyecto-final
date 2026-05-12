import 'package:flutter/material.dart';

class ProfesoresScreenHeader extends StatelessWidget {
  final void Function(String) onSearch;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;

  const ProfesoresScreenHeader({
    super.key, 
    required this.onSearch,
    this.onCopy,
    this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cuerpo Docente",
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                        letterSpacing: -0.5,
                      )),
                  Text("Gestión y Disponibilidad",
                      style: TextStyle(
                          fontSize: 14, color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  if (onCopy != null)
                    _headerActionBtn(Icons.copy_rounded, onCopy!),
                  if (onPaste != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _headerActionBtn(Icons.paste_rounded, onPaste!),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: TextField(
              onChanged: onSearch,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "Buscar docente por nombre...",
                hintStyle: TextStyle(
                    color: const Color(0xFF1E293B).withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF6366F1), size: 22),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerActionBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
