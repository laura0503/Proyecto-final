import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/aula.dart';
import '../../domain/usecases/get_aulas_usecase.dart';
import 'aula_card.dart';

class AulasSection extends StatefulWidget {
  final bool isDark;

  const AulasSection({super.key, required this.isDark});

  @override
  State<AulasSection> createState() => _AulasSectionState();
}

class _AulasSectionState extends State<AulasSection> {
  List<Aula> _aulas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAulas();
  }

  Future<void> _loadAulas() async {
    try {
      final aulasUseCase = Provider.of<GetAulasUseCase>(context, listen: false);
      final list = await aulasUseCase.call();
      if (mounted) {
        setState(() {
          _aulas = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Listado de Aulas",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_aulas.length} Registradas",
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_aulas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 64,
                    color: widget.isDark ? Colors.white10 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No se han encontrado aulas",
                    style: TextStyle(
                      color: widget.isDark ? Colors.white38 : Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // Igual que asignaturas
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.1,
            ),
            itemCount: _aulas.length,
            itemBuilder: (context, index) {
              final aula = _aulas[index];
              return AulaCard(aula: aula, isDark: widget.isDark);
            },
          ),
      ],
    );
  }
}
