import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_ANON_KEY')
supabase = create_client(url, key)

res = supabase.from('profesores').select('*').limit(1).execute()
if res.data:
    print("Columns:", list(res.data[0].keys()))
else:
    print("No data in profesores table")
