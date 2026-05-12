import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'data/services/horario_importer.dart';
import 'data/services/supabase_service.dart';
import 'core/services/karma_service.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es', null);

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['URL'] ?? '';
  final supabaseKey = dotenv.env['KEY'] ?? '';

  if (supabaseUrl == 'YOUR_SUPABASE_URL' || supabaseUrl.isEmpty) {
    print("❌ ERROR: No has configurado tu URL de Supabase en el archivo .env");
    // Podríamos mostrar una pantalla de error aquí, pero por ahora lanzamos un aviso claro.
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final appLinks = AppLinks();
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      Supabase.instance.client.auth.getSessionFromUrl(initialUri);
    }
    appLinks.uriLinkStream.listen((uri) {
      Supabase.instance.client.auth.getSessionFromUrl(uri);
    });
  }

  final supabase = Supabase.instance.client;
  final horarioImporter = HorarioImporter();
  final supabaseService = SupabaseService(supabase);
  final karmaService = KarmaService();

  Future(() async {
    try {
      final rows = await supabase.from('horario').select().limit(1);
      if ((rows as List).isNotEmpty) return;

      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final csvKeys = manifest
          .listAssets()
          .where((k) => k.startsWith('assets/csv/') && k.endsWith('.csv'))
          .toList();

      for (final key in csvKeys) {
        try {
          final content = await rootBundle.loadString(key);
          await horarioImporter.subirASupabase(content);
        } catch (_) {}
      }
      await horarioImporter.sincronizarTodo();
    } catch (e) {
      debugPrint("ERROR en auto-importación: $e");
    }
  });

  runApp(
    buildApp(
      supabase: supabase,
      horarioImporter: horarioImporter,
      supabaseService: supabaseService,
      karmaService: karmaService,
    ),
  );
}
