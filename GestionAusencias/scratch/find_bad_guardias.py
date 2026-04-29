import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def find_incorrect_guardias():
    print("Searching for records with null asignatura and es_guardia=False...")
    res = supabase.table("horario").select("*").is_("id_asignatura", "null").eq("es_guardia", False).execute()
    
    if res.data:
        print(f"Found {len(res.data)} records.")
        for row in res.data[:10]:
            print(row)
    else:
        print("No incorrect guardias found.")

if __name__ == "__main__":
    find_incorrect_guardias()
