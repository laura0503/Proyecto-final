import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def check_tramos():
    print("Checking horario_tramo in database...")
    res = supabase.table("horario_tramo").select("*").limit(1).execute()
    if res.data:
        print(f"Columns in horario_tramo: {res.data[0].keys()}")
    
    for row in res.data:
        # print(f"ID: {row['id_horario']} | Texto: {row['texto']} | Inicio: {row['horario_inicio']} | es_guardia: {row.get('es_guardia')}")
        print(row)

if __name__ == "__main__":
    check_tramos()
