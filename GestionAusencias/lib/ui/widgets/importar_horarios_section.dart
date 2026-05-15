import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../domain/usecases/importar_horario_usecase.dart';
import 'importar_horarios_models.dart';
import 'importar_archivo_row.dart';

class ImportarHorariosSection extends StatefulWidget {
  final bool isDark;
  const ImportarHorariosSection({super.key, required this.isDark});

  @override
  State<ImportarHorariosSection> createState() => _ImportarHorariosSectionState();
}

class _ImportarHorariosSectionState extends State<ImportarHorariosSection> {
  final List<ArchivoItem> _archivos = [];
  bool _importando = false;
  int _procesados = 0;

  Future<void> _seleccionarArchivos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _archivos.clear();
      for (final f in result.files) {
        _archivos.add(ArchivoItem(f.name));
      }
      _procesados = 0;
    });
    _iniciarImportacion(result.files);
  }

  Future<void> _iniciarImportacion(List<PlatformFile> files) async {
    setState(() => _importando = true);
    final useCase = context.read<ImportarHorarioUseCase>();

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      setState(() => _archivos[i].estado = EstadoArchivo.importando);

      try {
        String contenido;
        if (kIsWeb) {
          contenido = String.fromCharCodes(file.bytes!);
        } else {
          contenido = await File(file.path!).readAsString();
        }

        await useCase.execute(contenido);

        setState(() {
          _archivos[i].estado = EstadoArchivo.ok;
          _procesados++;
        });
      } catch (e) {
        setState(() {
          _archivos[i].estado = EstadoArchivo.error;
          _archivos[i].mensaje = e.toString().length > 80
              ? '${e.toString().substring(0, 80)}…'
              : e.toString();
          _procesados++;
        });
      }
    }

    setState(() => _importando = false);
    if (mounted) {
      final errores = _archivos.where((a) => a.estado == EstadoArchivo.error).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errores == 0
            ? '${_archivos.length} archivo(s) importados correctamente'
            : '${_archivos.length - errores} ok · $errores con error'),
        backgroundColor: errores == 0 ? const Color(0xFF354231) : Colors.orange[800],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white60 : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Importar Horarios CSV', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 6),
        Text(
          'Selecciona uno o varios archivos CSV de profesores, aulas o grupos. '
          'Se subirán automáticamente a la base de datos.',
          style: TextStyle(fontSize: 13, color: subColor),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _importando ? null : _seleccionarArchivos,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Seleccionar archivos CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF354231),
              side: const BorderSide(color: Color(0xFF354231)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (_archivos.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Archivos seleccionados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 12),
          ...List.generate(_archivos.length, (i) => ArchivoRow(item: _archivos[i], isDark: isDark)),
          if (!_importando && _procesados == _archivos.length && _procesados > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _seleccionarArchivos,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Importar más archivos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF354231),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
