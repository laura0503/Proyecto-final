
import os
import csv
import re
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
url = os.environ.get('URL')
key = os.environ.get('KEY')
supabase = create_client(url, key)

def sync_guards():
    print("--- INICIANDO ADICION DE GUARDIAS (Modo Seguro) ---")
    
    res_t = supabase.table('horario_tramo').select('id_horario, horario_inicio, horario_fin').execute()
    tramos = {f"{r['horario_inicio'][:5]} {r['horario_fin'][:5]}": r['id_horario'] for r in res_t.data}
    
    res_p = supabase.table('profesores').select('id_profesor, nombre').execute()
    profes = {p['nombre'].upper().replace('Á','A').replace('É','E').replace('Í','I').replace('Ó','O').replace('Ú','U'): p['id_profesor'] for p in res_p.data}
    
    id_guardia = 938 
    
    csv_dir = 'assets/csv'
    all_new_guards = []
    profesores_con_guardia = set()

    for filename in os.listdir(csv_dir):
        if not filename.endswith('.csv') or '__' not in filename: continue
        filepath = os.path.join(csv_dir, filename)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = list(csv.reader(f, delimiter=';'))
        except: continue
        if not lines: continue
        
        raw_name = lines[0][0].strip().upper().replace('Á','A').replace('É','E').replace('Í','I').replace('Ó','O').replace('Ú','U')
        prof_id = profes.get(raw_name)
        if not prof_id:
            for name, pid in profes.items():
                if raw_name in name or name in raw_name:
                    prof_id = pid
                    break
        if not prof_id: continue

        dias = [1, 2, 3, 4, 5]
        for row in lines:
            if not row: continue
            tramo_text = row[0].replace('"', '').strip()
            m = re.search(r'(\d{1,2}:\d{2})\s+(\d{1,2}:\d{2})', tramo_text)
            if not m: continue
            h_ini = m.group(1).zfill(5)
            h_fin = m.group(2).zfill(5)
            tramo_key = f"{h_ini} {h_fin}"
            tramo_id = tramos.get(tramo_key)
            if not tramo_id: continue
            
            for i in range(1, min(len(row), 6)):
                cell_content = row[i].upper()
                if 'GUARDIA' in cell_content:
                    all_new_guards.append({
                        'id_profesor': prof_id,
                        'id_tramo': tramo_id,
                        'dia_semana': dias[i-1],
                        'id_asignatura': id_guardia,
                        'es_guardia': True
                    })
                    profesores_con_guardia.add(prof_id)

    print(f"Insertando {len(all_new_guards)} registros...")
    success = 0
    for g in all_new_guards:
        try:
            # Primero verificamos si ya existe para no duplicar
            exists = supabase.table('horario').select('id').match({
                'id_profesor': g['id_profesor'],
                'id_tramo': g['id_tramo'],
                'dia_semana': g['dia_semana'],
                'id_asignatura': g['id_asignatura']
            }).execute()
            
            if not exists.data:
                supabase.table('horario').insert(g).execute()
                success += 1
            else:
                # Si ya existe, nos aseguramos de que es_guardia sea True
                supabase.table('horario').update({'es_guardia': True}).eq('id', exists.data[0]['id']).execute()
                success += 1
        except Exception as e:
            print(f"Error en record: {e}")

    # Sincronizar tabla profesores
    for pid in profesores_con_guardia:
        try:
            supabase.table('profesores').update({'es_guardia': True}).eq('id_profesor', pid).execute()
        except: pass

    print(f"COMPLETADO: {success} guardias procesadas con exito.")

if __name__ == "__main__":
    sync_guards()
