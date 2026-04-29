import os
import sys
from supabase import create_client
from dotenv import load_dotenv

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

mapping = {
    "D ez Cabrera, Enrique": "Díez Cabrera, Enrique",
    "Fern ndez Aranda, Dolores": "Fernández Aranda, Dolores",
    "Fern ndez Latorre, Mar": "Fernández Latorre, Mar",
    "G mez Letr n, Carmen": "Gómez Letrán, Carmen",
}

print("--- CORRIGIENDO RESTO DE PROFESORES ---")
res = supabase.table("profesores").select("*").execute()
for row in res.data:
    nombre_db = row['nombre']
    if nombre_db in mapping:
        nuevo = mapping[nombre_db]
        print(f"Corrigiendo: '{nombre_db}' -> '{nuevo}'")
        supabase.table("profesores").update({"nombre": nuevo}).eq("id_profesor", row['id_profesor']).execute()
