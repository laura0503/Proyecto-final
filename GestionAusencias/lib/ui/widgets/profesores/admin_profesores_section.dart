import 'dart:io' as io;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../domain/entities/profesor.dart';
import '../../../domain/usecases/get_profesores_usecase.dart';
import '../../../domain/usecases/eliminar_profesor_usecase.dart';
import '../../../domain/usecases/importar_horario_usecase.dart';

class AdminProfesoradoSection extends StatefulWidget {
  final bool isDark;

  const AdminProfesoradoSection({super.key, required this.isDark});

  @override
  State<AdminProfesoradoSection> createState() => _AdminProfesoradoSectionState();
}

class _AdminProfesoradoSectionState extends State<AdminProfesoradoSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Profesor> _allProfesores = [];
  List<Profesor> _filteredProfesores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadProfesores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfesores() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final getProfesoresUseCase = context.read<GetProfesoresUseCase>();
    try {
      final list = await getProfesoresUseCase.execute();
      if (mounted) {
        setState(() {
          _allProfesores = list;
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredProfesores = _allProfesores.where((p) {
        return p.nombre.toLowerCase().contains(query);
      }).toList();
      _filteredProfesores.sort((a, b) => a.nombre.compareTo(b.nombre));
    });
  }

  Future<void> _importarCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        String csvContent = "";
        
        if (result.files.first.bytes != null) {
          try {
            csvContent = utf8.decode(result.files.first.bytes!);
          } catch (_) {
            csvContent = latin1.decode(result.files.first.bytes!);
          }
        } else if (result.files.first.path != null) {
          final file = io.File(result.files.first.path!);
          try {
            csvContent = await file.readAsString(encoding: utf8);
          } catch (_) {
            csvContent = await file.readAsString(encoding: latin1);
          }
        }
        
        if (csvContent.isEmpty) return;

        final importarUseCase = context.read<ImportarHorarioUseCase>();
        await importarUseCase.execute(csvContent);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Importación exitosa")),
          );
          _loadProfesores();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al importar: $e")),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Profesor p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Profesor"),
        content: Text("¿Estás seguro de que deseas eliminar a ${p.nombre}? Se borrarán también todos sus horarios."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final eliminarUseCase = context.read<EliminarProfesorUseCase>();
        await eliminarUseCase.execute(p.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profesor eliminado")),
          );
          _loadProfesores();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al eliminar: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF4A443C);
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Gestión de Profesorado",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Administra la lista de docentes y sus horarios",
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _importarCSV,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text("Importar CSV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),

        Container(
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E0D8),
            ),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar profesor por nombre...",
              prefixIcon: Icon(Icons.search_rounded, color: textColor.withOpacity(0.5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              hintStyle: TextStyle(color: textColor.withOpacity(0.3)),
            ),
            style: TextStyle(color: textColor),
          ),
        ),
        const SizedBox(height: 20),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredProfesores.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                "No hay profesores registrados",
                style: TextStyle(color: textColor.withOpacity(0.5)),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredProfesores.length,
            itemBuilder: (context, index) {
              final p = _filteredProfesores[index];
              return _buildAdminTeacherCard(context, p, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildAdminTeacherCard(BuildContext context, Profesor p, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF4A443C);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E0D8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Border
              Container(
                width: 6,
                color: const Color(0xFF007AFF),
              ),
              const SizedBox(width: 16),
              // Name Initial Circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    p.nombre[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Teacher Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.nombre,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: textColor.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.departamento,
                            style: TextStyle(
                              color: textColor.withOpacity(0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 14,
                            color: textColor.withOpacity(0.4),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              p.asignatura,
                              style: TextStyle(
                                color: textColor.withOpacity(0.4),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Actions Toggle/Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => _confirmarEliminar(p),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.all(12),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
