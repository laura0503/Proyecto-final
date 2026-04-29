import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

res = supabase.table("horario").select("count", count="exact").execute()
print(f"Total records in horario: {res.count}")
