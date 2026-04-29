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

print("--- PROFESORES ---")
res = supabase.table("profesores").select("*").execute()
for row in res.data:
    print(f"ID: {row['id_profesor']}, Nombre: {row['nombre']}")
