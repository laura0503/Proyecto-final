import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def check_guardias():
    print("Checking guardias in database...")
    # Fetch some records from horario
    res = supabase.table("horario").select("*").limit(5).execute()
    if res.data:
        print(f"Columns: {res.data[0].keys()}")
        for row in res.data:
            print(row)
    
    for row in res.data:
        asig_nombre = row.get("Asignaturas", {}).get("nombre") if row.get("Asignaturas") else "N/A"
        # Try different ID names
        id_val = row.get("id_horario") or row.get("id") or "N/A"
        print(f"ID: {id_val} | Asig: {asig_nombre} | es_guardia: {row['es_guardia']}")

if __name__ == "__main__":
    check_guardias()
