import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def check_table(table, limit=10):
    print(f"\n--- Table: {table} ---")
    res = supabase.table(table).select("*").limit(limit).execute()
    for row in res.data:
        print(row)

check_table("profesores")
check_table("Asignaturas")
check_table("horario_tramo")
check_table("horario", limit=5)
