import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/aula.dart';
import '../../domain/usecases/get_aulas_usecase.dart';
import 'aula_card.dart';

class AulasSection extends StatelessWidget {
  final bool isDark;

  const AulasSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final aulasUseCase = Provider.of<GetAulasUseCase>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "LISTADO DE AULAS"),
        const SizedBox(height: 16),
        FutureBuilder<List<Aula>>(
          future: aulasUseCase.call(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No hay aulas registradas"));
            }

            final aulas = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.8,
              ),
              itemCount: aulas.length,
              itemBuilder: (context, index) {
                final aula = aulas[index];
                return AulaCard(aula: aula, isDark: isDark);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, top: 10),
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
