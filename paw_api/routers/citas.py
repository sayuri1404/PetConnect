from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from ..database import get_db_conn

router = APIRouter(prefix="/api/citas", tags=["citas"])

# --- Models ---
class CitaCreate(BaseModel):
    id_solicitud: int
    fecha_hora: datetime
    notas: Optional[str] = None

class CitaOut(BaseModel):
    id_cita: int
    id_solicitud: int
    fecha_hora: datetime
    estado: str
    notas: Optional[str]

    class Config:
        from_attributes = True

# --- Endpoints ---

@router.post("/", response_model=CitaOut)
async def create_cita(cita: CitaCreate, conn=Depends(get_db_conn)):
    # Verificar que la solicitud existe
    exists = await conn.fetchval(
        "SELECT 1 FROM paw.solicitud_adopcion WHERE id_solicitud = $1", 
        cita.id_solicitud
    )
    if not exists:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    row = await conn.fetchrow("""
        INSERT INTO paw.cita_visita (id_solicitud, fecha_hora, notas, estado)
        VALUES ($1, $2, $3, 'programada')
        RETURNING id_cita, id_solicitud, fecha_hora, estado, notas
    """, cita.id_solicitud, cita.fecha_hora, cita.notas)
    
    return dict(row)

@router.get("/solicitud/{id_solicitud}", response_model=List[CitaOut])
async def get_citas_by_solicitud(id_solicitud: int, conn=Depends(get_db_conn)):
    rows = await conn.fetch("""
        SELECT id_cita, id_solicitud, fecha_hora, estado, notas
        FROM paw.cita_visita
        WHERE id_solicitud = $1
        ORDER BY fecha_hora DESC
    """, id_solicitud)
    return [dict(row) for row in rows]

@router.get("/mis", response_model=List[CitaOut])
async def get_mis_citas(conn=Depends(get_db_conn)):
    # Placeholder: En aplicación real, filtrar por usuario autenticado.
    # Dado que las citas están ligadas a SOLICITUD -> ADOPTANTE
    # Requeriría decodificar token y hacer join.
    # Por simplicidad del MVP, retornaremos todas o las últimas creadas.
    rows = await conn.fetch("""
        SELECT id_cita, id_solicitud, fecha_hora, estado, notas
        FROM paw.cita_visita
        ORDER BY fecha_hora DESC
        LIMIT 50
    """)
    return [dict(row) for row in rows]
