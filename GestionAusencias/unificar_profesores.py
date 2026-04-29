import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()
supabase = create_client(os.environ.get('URL'), os.environ.get('KEY'))

# Mapa de Unificación: Slave -> Master
# Elegimos el ID que ya tiene más registros o el más antiguo.
UNIFICA = {
    160: 184, # Emilio
    147: 181, # Mar
    150: 179, # Carmen
    177: 182, # Miguel Anxo
    180: 132, # Sergio
    185: 158  # Lorena
}

def unificar():
    print("--- INICIANDO UNIFICACIÓN DE PROFESORES ---")
    
    for slave, master in UNIFICA.items():
        print(f"\nProcesando: Slave {slave} -> Master {master}")
        
        # 1. Mover registros de horario
        res_h = supabase.table("horario").update({"id_profesor": master}).eq("id_profesor", slave).execute()
        print(f"  Horarios movidos: {len(res_h.data)}")
        
        # 2. Mover registros de guardias (si existe la tabla)
        try:
            res_g = supabase.table("guardias").update({"id_profesor": master}).eq("id_profesor", slave).execute()
            print(f"  Guardias movidas: {len(res_g.data)}")
        except:
            pass
            
        # 3. Eliminar profesor duplicado (Slave)
        try:
            supabase.table("profesores").delete().eq("id_profesor", slave).execute()
            print(f"  Profesor {slave} eliminado de la tabla maestros.")
        except Exception as e:
            print(f"  No se pudo eliminar el profesor {slave} (posibles claves foráneas): {e}")

    print("\n--- UNIFICACIÓN FINALIZADA ---")

if __name__ == "__main__":
    unificar()
