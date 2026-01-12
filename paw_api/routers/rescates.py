from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from ..database import get_db_conn

router = APIRouter(prefix="/api/rescates", tags=["rescates"])

# --- Models ---
class RescateCreate(BaseModel):
    id_mascota: int
    fecha: date
    alcaldia: str
    situacion: str
    necesidades: Optional[str] = None
    fuente: Optional[str] = None # No está en tabla original paw.rescate, lo pondremos en necesidades o ignoramos?
    # Revisando SQL: id_rescate, id_mascota, fecha, alcaldia, situacion, necesidades_especiales

class RescateOut(BaseModel):
    id_rescate: int
    id_mascota: int
    nombre_mascota: Optional[str]
    fecha: date
    alcaldia: str
    situacion: str
    necesidades_especiales: Optional[str]

# --- Endpoints ---

@router.post("/", response_model=RescateOut)
async def create_rescate(rescate: RescateCreate, conn=Depends(get_db_conn)):
    # Verificar mascota
    mascota = await conn.fetchrow("SELECT nombre FROM paw.mascota_rescatada WHERE id_mascota = $1", rescate.id_mascota)
    if not mascota:
            raise HTTPException(status_code=404, detail="Mascota no encontrada")

    # Combinar 'fuente' con 'necesidades' si ambos existen, o guardar fuente en necesidades
    # ya que la tabla rescate no tiene columna fuente.
    necesidades_final = rescate.necesidades
    if rescate.fuente:
        if necesidades_final:
            necesidades_final += f" (Fuente: {rescate.fuente})"
        else:
            necesidades_final = f"Fuente: {rescate.fuente}"

    # Insertar
    # Ojo: id_mascota es UNIQUE en paw.rescate. Si ya existe rescate para esa mascota, fallará.
    try:
        row = await conn.fetchrow("""
            INSERT INTO paw.rescate (id_mascota, fecha, alcaldia, situacion, necesidades_especiales)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id_rescate, id_mascota, fecha, alcaldia, situacion, necesidades_especiales
        """, rescate.id_mascota, rescate.fecha, rescate.alcaldia, rescate.situacion, necesidades_final)
    except Exception as e:
        if 'unique' in str(e).lower():
                raise HTTPException(status_code=400, detail="Esta mascota ya tiene un rescate registrado.")
        raise e

    return RescateOut(
        id_rescate=row['id_rescate'],
        id_mascota=row['id_mascota'],
        nombre_mascota=mascota['nombre'],
        fecha=row['fecha'],
        alcaldia=row['alcaldia'],
        situacion=row['situacion'],
        necesidades_especiales=row['necesidades_especiales']
    )

@router.get("/", response_model=List[RescateOut])
async def get_rescates(conn=Depends(get_db_conn)):
    rows = await conn.fetch("""
        SELECT r.id_rescate, r.id_mascota, m.nombre as nombre_mascota, r.fecha, r.alcaldia, r.situacion, r.necesidades_especiales
        FROM paw.rescate r
        JOIN paw.mascota_rescatada m ON r.id_mascota = m.id_mascota
        ORDER BY r.fecha DESC
        LIMIT 50
    """)
    return [
        RescateOut(
            id_rescate=r['id_rescate'],
            id_mascota=r['id_mascota'],
            nombre_mascota=r['nombre_mascota'],
            fecha=r['fecha'],
            alcaldia=r['alcaldia'],
            situacion=r['situacion'],
            necesidades_especiales=r['necesidades_especiales']
        ) for r in rows
    ]
