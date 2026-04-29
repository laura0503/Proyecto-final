import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def cleanup():
    print("Cleaning up garbage entries...")
    # Delete from Asignaturas
    res_asig = supabase.table("Asignaturas").delete().ilike("nombre", "%UOUI%").execute()
    print(f"Deleted {len(res_asig.data)} from Asignaturas")
    
    # Delete from grupo
    res_grupo = supabase.table("grupo").delete().ilike("nombre", "%UOUI%").execute()
    print(f"Deleted {len(res_grupo.data)} from grupo")

if __name__ == "__main__":
    cleanup()
