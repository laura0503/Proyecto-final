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
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAulas();
  }

  Future<void> _loadAulas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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
        setState(() {
          _isLoading = false;
          _errorMessage = "Error al conectar con el servidor: $e";
        });
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
        else if (_errorMessage != null)
          Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loadAulas, child: const Text("Reintentar")),
              ],
            ),
          )
        else if (_aulas.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      size: 64,
                      color: widget.isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No hay aulas registradas",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Parece que la base de datos de aulas está vacía. El sistema intentará cargar los datos automáticamente al inicio si no encuentra nada.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadAulas,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Reintentar carga"),
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
