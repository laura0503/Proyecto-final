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

# Mapeo manual basado en lo que vimos en la DB
mapping = {
    "P rez Ruiz, Andrea": "Pérez Ruiz, Andrea",
    "P rez Romero, Emilio": "Pérez Romero, Emilio",
    "Dur n Pi a, Mar a de la O": "Durán Piña, María de la O",
    "Mart n Cifuentes, Lorena": "Martín Cifuentes, Lorena",
    "G mez Letr n, Carmen": "Gómez Letrán, Carmen",
    "Fern ndez Aranda, Dolores": "Fernández Aranda, Dolores",
    "Fern ndez Latorre, Mar": "Fernández Latorre, Mar",
    "Alguacil JimÃ©nez, Sergio A.": "Alguacil Jiménez, Sergio A."
}

print("--- CORRIGIENDO NOMBRES ESPECÍFICOS ---")
res = supabase.table("profesores").select("*").execute()
for row in res.data:
    nombre_db = row['nombre']
    if nombre_db in mapping:
        nuevo = mapping[nombre_db]
        print(f"Corrigiendo: '{nombre_db}' -> '{nuevo}'")
        supabase.table("profesores").update({"nombre": nuevo}).eq("id_profesor", row['id_profesor']).execute()
    elif "rez" in nombre_db and "P" in nombre_db: # Intento de captura genérica para P rez
        # Solo si no es el correcto ya
        if "é" not in nombre_db:
            nuevo = nombre_db.replace("P rez", "Pérez")
            print(f"Corrigiendo (auto): '{nombre_db}' -> '{nuevo}'")
            supabase.table("profesores").update({"nombre": nuevo}).eq("id_profesor", row['id_profesor']).execute()

print("\n--- PROFESORES ACTUALES ---")
res = supabase.table("profesores").select("*").execute()
for row in res.data:
    print(f"ID: {row['id_profesor']}, Nombre: {row['nombre']}")
