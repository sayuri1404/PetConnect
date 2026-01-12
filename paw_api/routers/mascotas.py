from fastapi import APIRouter, Depends, HTTPException
from typing import Optional
from pydantic import BaseModel
from ..database import get_db_conn
from ..config import PAW_SCHEMA
from .auth import get_current_user
from datetime import datetime
import logging

# Define Pydantic model for creation
class MascotaCreate(BaseModel):
    nombre: str
    especie: str # 'perro' or 'gato'
    raza: str
    edad_anios: int
    edad_meses: int
    sexo: str
    tamanio: str
    nivel_energia: str
    comportamiento: str
    estado_salud: str
    cp: str
    vacunado: bool
    esterilizado: bool
    senias_particulares: Optional[str] = None
    url_foto: Optional[str] = None
    
    # Rescue fields
    rescate_fecha: str
    rescate_alcaldia: str
    rescate_situacion: str
    rescate_necesidades: Optional[str] = None
    rescate_fuente: Optional[str] = None

router = APIRouter(prefix="/api/mascotas", tags=["mascotas"])

@router.get("")
async def mascotas(available: Optional[bool] = True, conn=Depends(get_db_conn)):
    # Simple query for list
    query = f"""
        SELECT m.*, r.situacion, r.necesidades_especiales, r.fecha as fecha_rescate
        FROM {PAW_SCHEMA}.mascota_rescatada m
        LEFT JOIN {PAW_SCHEMA}.rescate r ON m.id_mascota = r.id_mascota
        ORDER BY m.id_mascota
    """
    rows = await conn.fetch(query)
    return {"mascotas": [dict(r) for r in rows]}

@router.post("")
async def create_mascota(mascota: MascotaCreate, conn=Depends(get_db_conn), user=Depends(get_current_user)):
    # Verify role
    if user['rol'] != 'fundacion':
        raise HTTPException(status_code=403, detail="Solo fundaciones pueden registrar mascotas")
        
    id_fundacion = user.get('id_fundacion')
    if not id_fundacion:
        raise HTTPException(status_code=400, detail="Usuario fundación sin ID de fundación asociado")

    # 1. Determine especie_id
    especie_id = 1 if mascota.especie.lower() == 'perro' else (2 if mascota.especie.lower() == 'gato' else 1)

    # 2. Find or Create Raza
    row_raza = await conn.fetchrow(f"SELECT id_raza FROM {PAW_SCHEMA}.raza WHERE LOWER(nombre) = LOWER($1) AND especie_id = $2", mascota.raza, especie_id)
    if row_raza:
        id_raza = row_raza['id_raza']
    else:
        try:
             new_raza = await conn.fetchrow(f"INSERT INTO {PAW_SCHEMA}.raza (nombre, especie_id) VALUES ($1, $2) RETURNING id_raza", mascota.raza, especie_id)
             id_raza = new_raza['id_raza']
        except Exception as e:
             logging.warning(f"Error inserting raza: {e}")
             row_raza = await conn.fetchrow(f"SELECT id_raza FROM {PAW_SCHEMA}.raza WHERE LOWER(nombre) = LOWER($1) AND especie_id = $2", mascota.raza, especie_id)
             if row_raza:
                 id_raza = row_raza['id_raza']
             else:
                 raise HTTPException(status_code=500, detail="Error managing raza")

    # 3. Insert Mascota Rescatada
    try:
        # Added id_origen and fuente columns to match schema
        query_pet = f"INSERT INTO {PAW_SCHEMA}.mascota_rescatada (id_mascota, nombre, especie_id, edad, id_raza, tamanio, comportamiento, sexo, senias_particulares, url_foto, id_origen, fuente) VALUES ((SELECT COALESCE(MAX(id_mascota), 0) + 1 FROM {PAW_SCHEMA}.mascota_rescatada), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id_mascota"
        
        full_behavior = f"{mascota.comportamiento}. Energía: {mascota.nivel_energia}."
        
        # 'fuente' is essentially the type of origin. Since it's a foundation user, we use 'FUNDACION' or assume it.
        
        new_pet = await conn.fetchrow(query_pet, 
            mascota.nombre, 
            especie_id, 
            mascota.edad_anios, 
            id_raza, 
            mascota.tamanio, 
            full_behavior, 
            mascota.sexo, 
            mascota.senias_particulares, 
            mascota.url_foto,
            id_fundacion, # id_origen
            'FUNDACION'   # fuente
        )
        id_mascota = new_pet['id_mascota']

        # 4. Insert Rescate
        # FIX: Parse date string to object
        try:
            rescate_date = datetime.strptime(mascota.rescate_fecha, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")

        query_rescue = f"INSERT INTO {PAW_SCHEMA}.rescate (id_mascota, fecha, alcaldia, situacion, necesidades_especiales) VALUES ($1, $2, $3, $4, $5)"
        
        await conn.execute(query_rescue, 
            id_mascota, 
            rescate_date, 
            mascota.rescate_alcaldia or mascota.cp, 
            mascota.rescate_situacion, 
            mascota.rescate_necesidades
        )

        return {"success": True, "id_mascota": id_mascota, "message": "Mascota registrada exitosamente"}

    except Exception as e:
        logging.error(f"Error creating pet: {e}")
        # Log stack trace
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/{id_mascota}")
async def mascota_detail(id_mascota: int, conn=Depends(get_db_conn)):
    # 1. Datos básicos + Rescate
    row = await conn.fetchrow(
        f"""
        SELECT m.*, r.situacion, r.necesidades_especiales, r.fecha as fecha_rescate, r.alcaldia
        FROM {PAW_SCHEMA}.mascota_rescatada m
        LEFT JOIN {PAW_SCHEMA}.rescate r ON m.id_mascota = r.id_mascota
        WHERE m.id_mascota=$1
        """,
        id_mascota
    )
    if not row:
        raise HTTPException(status_code=404, detail="Mascota no encontrada")
    
    mascota_dict = dict(row)

    # 2. Vacunas
    vacunas = await conn.fetch(
        f"""
        SELECT v.nombrevac as vacuna, va.fecha_aplicacion, va.proxima_dosis
        FROM {PAW_SCHEMA}.vacuna_aplicada va
        JOIN vacunas.vacuna v ON va.id_vacuna = v.id_vacunavac
        WHERE va.id_mascota = $1
        """, id_mascota
    )
    mascota_dict["vacunas"] = [dict(v) for v in vacunas]

    # 3. Padecimientos / Enfermedades
    padecimientos = await conn.fetch(
        f"""
        SELECT p.nombre as padecimiento, mp.tratamiento
        FROM {PAW_SCHEMA}.mascota_padecimiento mp
        JOIN {PAW_SCHEMA}.padecimiento p ON mp.id_padecimiento = p.id_padecimiento
        WHERE mp.id_mascota = $1
        """, id_mascota
    )
    mascota_dict["padecimientos"] = [dict(p) for p in padecimientos]

    # 4. Historial médico (Eventos)
    eventos = await conn.fetch(
        f"""
        SELECT tipo, fecha, detalle
        FROM {PAW_SCHEMA}.evento_medico
        WHERE id_mascota = $1
        ORDER BY fecha DESC
        """, id_mascota
    )
    mascota_dict["historial_medico"] = [dict(e) for e in eventos]

    return {"mascota": mascota_dict}
