
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['URL']!,
    anonKey: dotenv.env['KEY']!,
  );
  final supabase = Supabase.instance.client;
  try {
    final res = await supabase.from('horario_tramo').select().limit(1);
    if (res.isNotEmpty) {
      print("COLUMNS: ${res.first.keys.toList()}");
    } else {
      print("TABLE EMPTY");
    }
  } catch (e) {
    print("ERROR: $e");
  }
}
