import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get('SUPABASE_URL')
key = os.environ.get('SUPABASE_ANON_KEY')
supabase = create_client(url, key)

try:
    res = supabase.from('profesores').select('*').limit(1).execute()
    if res.data:
        print("Columns in 'profesores':", list(res.data[0].keys()))
    else:
        print("Table 'profesores' is empty, checking definition...")
        # Since we can't easily check schema without query, let's try to insert dummy and rollback or just check another table
        res_h = supabase.from('horario').select('*').limit(1).execute()
        if res_h.data:
            print("Columns in 'horario':", list(res_h.data[0].keys()))
except Exception as e:
    print("Error:", e)
