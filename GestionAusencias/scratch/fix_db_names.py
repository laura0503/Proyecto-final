import os
import glob
from supabase import create_client
from dotenv import load_dotenv
import unicodedata
import re

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def normalize(text):
    if not text: return ""
    text = str(text).strip().upper()
    text = "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")
    text = re.sub(r'[^A-Z]', '', text) # Solo letras para el matching inicial
    return text

def fix_names():
    print("Obteniendo nombres de los archivos CSV...")
    csv_names = {}
    for f in glob.glob("assets/csv/*.csv"):
        try:
            with open(f, 'r', encoding='latin-1') as file:
                line = file.readline()
                name = line.split(';')[0].strip()
                if name and len(name) > 5: # Evitar nombres demasiado cortos o cabeceras
                    csv_names[normalize(name)] = name
        except:
            continue
    
    print(f"Detectados {len(csv_names)} nombres unicos en CSVs.")

    print("\nObteniendo profesores de la DB...")
    res = supabase.table("profesores").select("id_profesor, nombre").execute()
    profesores = res.data

    updated_count = 0
    for p in profesores:
        db_name = p['nombre']
        db_id = p['id_profesor']
        norm_db = normalize(db_name)
        
        # Intentar encontrar match en csv_names
        best_match = csv_names.get(norm_db)
        
        if not best_match:
            # Intentar match parcial si falla el exacto
            for norm_csv, real_name in csv_names.items():
                if norm_db in norm_csv or norm_csv in norm_db:
                    best_match = real_name
                    break
        
        if best_match and best_match != db_name:
            print(f"Fixing ID {db_id}: '{db_name}' -> '{best_match}'")
            supabase.table("profesores").update({"nombre": best_match}).eq("id_profesor", db_id).execute()
            updated_count += 1
    
    print(f"\nProceso finalizado. Se han actualizado {updated_count} profesores.")

if __name__ == "__main__":
    fix_names()
