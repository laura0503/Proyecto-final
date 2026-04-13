import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart'; // usar núcleo puro sin inicializar plugins
import 'package:gestion_ausencias/data/services/horario_importer.dart';

void main() {
  test('importar_desde_consola', () async {
    // 1. Leer .env a mano para evitar flutter_dotenv (que requiere UI bindings)
    final envFile = File('.env');
    final lines = await envFile.readAsLines();
    String url = '';
    String key = '';
    for (final line in lines) {
      if (line.startsWith('URL=')) url = line.substring(4);
      if (line.startsWith('KEY=')) key = line.substring(4);
    }

    // 2. Instanciar SupabaseClient directamente (sin Supabase.initialize)
    final client = SupabaseClient(url, key);
    
    // Inyectamos el cliente en nuestro importador (que acabamos de modificar)
    final importer = HorarioImporter(client);

    // 3. Limpiar la tabla de horarios primero (está corrompida con 1 fila y para que sea en limpio)
    /* 
    print('Limpiando la tabla horario...');
    try {
      await client.from('horario').delete().neq('id', 0);
    } catch(e) {
      print('Aviso limpiar horario: $e');
    }
    */
    
    // 4. Leer la carpeta
    final dir = Directory('assets/csv');
    final files = dir.listSync()
                     .whereType<File>()
                     .where((f) => f.path.endsWith('.csv'))
                     .toList();
    
    print('Encontrados ${files.length} archivos CSV. Comienza la subida...');
    
    for (int i = 0; i < files.length; i++) {
        final f = files[i];
        print('Procesando [${i+1}/${files.length}]: ${f.path.split(Platform.pathSeparator).last}');
        final content = await f.readAsString();
        await importer.subirASupabase(content);
    }
    
    print('Sincronizando departamentos...');
    await importer.sincronizarTodo();
    print('¡IMPORTACIÓN TERMINADA AL 100%!');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
