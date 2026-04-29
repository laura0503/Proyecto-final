import os
from supabase import create_client
from dotenv import load_dotenv
import re
import unicodedata

load_dotenv()
URL = os.environ.get("URL")
KEY = os.environ.get("KEY")
supabase = create_client(URL, KEY)

def normalize_text(text):
    if not text: return ""
    text = str(text).strip().upper()
    text = "".join(c for c in unicodedata.normalize("NFD", text) if unicodedata.category(c) != "Mn")
    text = re.sub(r'[^A-Z0-9]', '', text)
    return text

res = supabase.table("profesores").select("nombre").execute()
for row in res.data:
    name = row['nombre']
    print(f"Original: '{name}' | Normalized: '{normalize_text(name)}'")

print("\nTarget: 'Alguacil Jiménez, Sergio A.' | Normalized: '" + normalize_text("Alguacil Jiménez, Sergio A.") + "'")
