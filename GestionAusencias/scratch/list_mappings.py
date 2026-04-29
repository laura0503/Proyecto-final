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

print("--- ASIGNATURAS ---")
res = supabase.table("Asignaturas").select("*").execute()
for row in res.data:
    print(f"ID: {row['id_asignaturas']}, Nombre: {row['nombre']}")

print("\n--- GRUPOS ---")
res = supabase.table("grupo").select("*").execute()
for row in res.data:
    print(f"ID: {row['id_grupo']}, Nombre: {row['nombre']}")

print("\n--- AULAS ---")
res = supabase.table("aulas").select("*").execute()
for row in res.data:
    print(f"ID: {row['id_aulas']}, Nombre: {row['nombre']}")
