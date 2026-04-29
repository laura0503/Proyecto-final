import os
import unicodedata
import re
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def normalizar(texto):
    if not texto: return ""
    s = str(texto).strip().upper()
    s = "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")
    return re.sub(r'[^A-Z]', '', s)

# Mapeo de nombres correctos basados en los archivos CSV
nombres_correctos = [
    "Pérez Ruiz, Andrea",
    "Pérez Romero, Emilio",
    "Durán Piña, María de la O",
    "Martín Cifuentes, Lorena",
    "Gómez Letrán, Carmen",
    "Fernández Aranda, Dolores",
    "Fernández Latorre, Mar",
    "Cerrillo Ruiz, Pablo",
    "Bustos Rodríguez, Miguel",
    "Ibañez Porcel, Pablo",
    "Alguacil Jiménez, Sergio A."
]

print("--- CORRIGIENDO NOMBRES DE PROFESORES ---")
res = supabase.table("profesores").select("*").execute()
for row in res.data:
    nombre_db = row['nombre']
    norm_db = normalizar(nombre_db)
    
    for correcto in nombres_correctos:
        norm_corr = normalizar(correcto)
        # Si coinciden al normalizar (ignorando el hueco del carácter corrupto)
        # O si uno es muy parecido al otro
        if norm_corr in norm_db or norm_db in norm_corr:
            if nombre_db != correcto:
                print(f"Actualizando: '{nombre_db}' -> '{correcto}'")
                supabase.table("profesores").update({"nombre": correcto}).eq("id_profesor", row['id_profesor']).execute()
            break
