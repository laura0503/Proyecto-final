import os
import glob
from supabase import create_client
from dotenv import load_dotenv
import unicodedata
import re
import sys

# Forzar salida en UTF-8 para evitar errores en Windows
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def normalize(text):
    if not text: return ""
    text = str(text).strip().upper()
    text = "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")
    text = re.sub(r'[^A-Z]', '', text)
    return text

def fix_names():
    print("Obteniendo nombres validos de los archivos CSV...")
    csv_names = {}
    for f in glob.glob("assets/csv/*.csv"):
        try:
            with open(f, 'r', encoding='latin-1') as file:
                line = file.readline()
                name = line.split(';')[0].strip().replace('"', '')
                # Un nombre de profesor suele tener una coma (Apellido, Nombre)
                if name and "," in name and len(name) > 5 and not any(x in name for x in ["1º", "2º", "3º", "4º"]):
                    csv_names[normalize(name)] = name
        except:
            continue
    
    print(f"Detectados {len(csv_names)} nombres de profesores en CSVs.")

    print("\nObteniendo profesores de la DB...")
    res = supabase.table("profesores").select("id_profesor, nombre").execute()
    profesores = res.data

    updated_count = 0
    for p in profesores:
        db_name = p['nombre']
        db_id = p['id_profesor']
        norm_db = normalize(db_name)
        
        # Intentar encontrar match
        best_match = csv_names.get(norm_db)
        
        if not best_match:
            # Intentar match parcial (ej: "Gomez Letron" matches "Gomez Letron, Carmen")
            for norm_csv, real_name in csv_names.items():
                if norm_db != "" and (norm_db in norm_csv or norm_csv in norm_db):
                    best_match = real_name
                    break
        
        if best_match and best_match != db_name and "," in best_match:
            print(f"Fixing ID {db_id}: '{db_name}' -> '{best_match}'")
            try:
                supabase.table("profesores").update({"nombre": best_match}).eq("id_profesor", db_id).execute()
                updated_count += 1
            except Exception as e:
                print(f"Error actualizando {db_id}: {e}")
    
    print(f"\nProceso finalizado. Se han actualizado {updated_count} profesores.")

if __name__ == "__main__":
    fix_names()
